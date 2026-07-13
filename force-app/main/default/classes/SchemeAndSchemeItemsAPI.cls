@RestResource(urlMapping='/schemeAndSchemeItems')
global without sharing class SchemeAndSchemeItemsAPI {

    @HttpGet
    global static ResponseWrapper getSchemeAndSchemeItems() {
        ResponseWrapper response = new ResponseWrapper();

        RestRequest req = RestContext.request;
        String contactId = req.params.get('contactId');

        if (String.isBlank(contactId)) {
            response.success = false;
            response.message = 'Missing required parameter: contactId';
            return response;
        }

        try {

            // Step 1: Fetch the applicant contact — eligibility is evaluated against their profile fields.
            List<Contact> contacts = [
                SELECT Id, Name, Email, Qualifying_Degree__c, Research_Experience_After_Viva_Date_Yrs__c, Research_Experience_After_Viva_Date_Mont__c
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                response.success = false;
                response.message = 'No contact found for the user.';
                return response;
            }

            Contact contact = contacts[0];

            List<Year__c> years = [
                SELECT Id, Name, Is_Active__c, Is_Current_Year__c, Year_Start_Date__c, Year_End_Date__c
                FROM Year__c
                WHERE Is_Active__c = true AND Is_Current_Year__c = true
                LIMIT 1
            ];

            if (years.isEmpty()) {
                response.success = false;
                response.message = 'No active year found.';
                return response;
            }

            Year__c year = years[0];
            DataWrapper data = new DataWrapper();
            data.year = buildYearWrapper(year);

            List<Scheme__c> schemes = [
                SELECT Id, Name, Description__c, Scheme_Type__c, is_Active__c, Scheme_Duration__c
                FROM Scheme__c
                WHERE is_Active__c = true
                ORDER BY Name
            ];

            if (schemes.isEmpty()) {
                data.schemeAndItemsData = new List<SchemeDataWrapper>();
                response.success = true;
                response.message = 'No active schemes found.';
                response.data = data;
                return response;
            }

            Set<Id> schemeIds = new Set<Id>();
            for (Scheme__c scheme : schemes) {
                schemeIds.add(scheme.Id);
            }

            List<Scheme_Items__c> schemeItems = [
                SELECT Id, Name, Duration__c, Is_Active__c, Scheme__c, First_Page_URL__c
                FROM Scheme_Items__c
                WHERE Scheme__c IN :schemeIds AND Is_Active__c = true
                ORDER BY Name
            ];

            Set<Id> schemeItemIds = new Set<Id>();
            Map<Id, List<Scheme_Items__c>> itemsBySchemeId = new Map<Id, List<Scheme_Items__c>>();

            for (Scheme_Items__c item : schemeItems) {
                schemeItemIds.add(item.Id);
                if (!itemsBySchemeId.containsKey(item.Scheme__c)) {
                    itemsBySchemeId.put(item.Scheme__c, new List<Scheme_Items__c>());
                }
                itemsBySchemeId.get(item.Scheme__c).add(item);
            }

            Map<Id, Yearly_Schemes__c> yearlySchemeByItemId = new Map<Id, Yearly_Schemes__c>();
            if (!schemeItemIds.isEmpty()) {
                for (Yearly_Schemes__c ys : [
                    SELECT Id, Name, Scheme_Items__c, Is_Active__c, Scheme_Visibility__c, Approval_Status__c,
                           Scheme_Start_Date__c, Scheme_End_Date__c,
                           Second_Stage_Start_Date__c, Second_Stage_End_Date__c,
                           Application_Stages__c, Budget_Cap__c, Experience_Required__c,
                           Required_Degree__c, Team_Size_Limits__c
                    FROM Yearly_Schemes__c
                    WHERE Year__c = :year.Id 
                    AND Scheme_Items__c IN :schemeItemIds 
                    AND Is_Active__c = true
                    AND Scheme_Visibility__c = 'Public'
                    AND Approval_Status__c = 'Approved'
                ]) {
                    yearlySchemeByItemId.put(ys.Scheme_Items__c, ys);
                }
            }
            // For Future: There can be multiple Yearly Schemes for a Scheme Item, so we need to handle that.


            List<SchemeDataWrapper> schemeDataList = new List<SchemeDataWrapper>();
            for (Scheme__c scheme : schemes) {
                List<Scheme_Items__c> items = itemsBySchemeId.get(scheme.Id);
                if (items == null || items.isEmpty()) {
                    continue;
                }

                SchemeDataWrapper schemeData = new SchemeDataWrapper();
                schemeData.schemeId = scheme.Id;
                schemeData.schemeName = scheme.Name;
                schemeData.description = scheme.Description__c;
                schemeData.schemeType = scheme.Scheme_Type__c;
                schemeData.schemeDuration = scheme.Scheme_Duration__c;
                schemeData.isActive = scheme.is_Active__c;
                schemeData.schemeLineItems = new List<SchemeLineItemWrapper>();

                for (Scheme_Items__c item : items) {
                    // Step 5: Evaluate eligibility per line item against the contact and its yearly scheme criteria.
                    schemeData.schemeLineItems.add(
                        buildLineItemWrapper(item, yearlySchemeByItemId.get(item.Id), contact)
                    );
                }

                schemeDataList.add(schemeData);
            }

            data.schemeAndItemsData = schemeDataList;
            response.success = true;
            response.message = 'Scheme details fetched successfully.';
            response.data = data;
        } catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    private static YearWrapper buildYearWrapper(Year__c year) {
        YearWrapper wrapper = new YearWrapper();
        wrapper.yearId = year.Id;
        wrapper.yearName = year.Name;
        wrapper.isActive = year.Is_Active__c;
        wrapper.isCurrentYear = year.Is_Current_Year__c;
        wrapper.yearStartDate = year.Year_Start_Date__c;
        wrapper.yearEndDate = year.Year_End_Date__c;
        return wrapper;
    }

    private static SchemeLineItemWrapper buildLineItemWrapper(
        Scheme_Items__c item,
        Yearly_Schemes__c yearlyScheme,
        Contact contact
    ) {
        SchemeLineItemWrapper lineItem = new SchemeLineItemWrapper();
        lineItem.schemeItemId = item.Id;
        lineItem.schemeItemName = item.Name;
        lineItem.duration = item.Duration__c;
        lineItem.durationLabel = formatDuration(item.Duration__c);
        lineItem.isActive = item.Is_Active__c;
        lineItem.firstPageUrl = item.First_Page_URL__c;
        lineItem.yearlyScheme = buildYearlySchemeWrapper(yearlyScheme);

        EligibilityWrapper eligibility = buildEligibilityResult(contact, yearlyScheme);
        lineItem.eligibility = eligibility;
        lineItem.actions = buildActions(item.Id, yearlyScheme, eligibility);

        return lineItem;
    }

    private static YearlySchemeWrapper buildYearlySchemeWrapper(Yearly_Schemes__c yearlyScheme) {
        if (yearlyScheme == null) {
            return null;
        }

        YearlySchemeWrapper wrapper = new YearlySchemeWrapper();
        wrapper.yearlySchemeId = yearlyScheme.Id;
        wrapper.yearlySchemeName = yearlyScheme.Name;
        wrapper.isActive = yearlyScheme.Is_Active__c;
        // wrapper.status = yearlyScheme.Is_Active__c ? 'Active' : 'Draft';
        wrapper.visibility = yearlyScheme.Scheme_Visibility__c;
        wrapper.schemeStartDate = toDateString(yearlyScheme.Scheme_Start_Date__c);
        wrapper.schemeEndDate = toDateString(yearlyScheme.Scheme_End_Date__c);
        wrapper.deadlineLabel = formatDeadlineLabel(yearlyScheme.Scheme_End_Date__c);
        wrapper.secondStageStartDate = toDateString(yearlyScheme.Second_Stage_Start_Date__c);
        wrapper.secondStageEndDate = toDateString(yearlyScheme.Second_Stage_End_Date__c);
        wrapper.applicationStages = yearlyScheme.Application_Stages__c;
        wrapper.budgetCap = yearlyScheme.Budget_Cap__c;
        wrapper.experienceRequired = yearlyScheme.Experience_Required__c;
        wrapper.requiredDegree = yearlyScheme.Required_Degree__c;
        wrapper.teamSizeLimits = yearlyScheme.Team_Size_Limits__c;
        return wrapper;
    }

    private static ActionsWrapper buildActions(
        Id schemeItemId,
        Yearly_Schemes__c yearlyScheme,
        EligibilityWrapper eligibility
    ) {
        ActionsWrapper actions = new ActionsWrapper();
        Boolean canInteract = yearlyScheme != null && yearlyScheme.Is_Active__c;
        Boolean isEligible = eligibility != null && eligibility.isEligible;

        actions.showEligibilityCheck = canInteract;
        // Apply is allowed only when the scheme is active and the contact passes eligibility checks.
        actions.canApply = canInteract && isEligible;

        if (yearlyScheme != null) {
            actions.eligibilityUrl = '/eligibility/' + yearlyScheme.Id;
            actions.applyUrl = '/apply/' + yearlyScheme.Id;
        }
        actions.knowMoreUrl = '/scheme-item/' + schemeItemId;
        return actions;
    }

    /**
     * Step 2: Normalize the contact's research experience into total years (years + months).
     * Contact stores experience as separate year and month fields; scheme stores required experience in years.
     */
    private static Decimal getContactExperienceInYears(Contact contact) {
        Decimal experienceYears = contact.Research_Experience_After_Viva_Date_Yrs__c != null
            ? contact.Research_Experience_After_Viva_Date_Yrs__c
            : 0;
        Decimal experienceMonths = contact.Research_Experience_After_Viva_Date_Mont__c != null
            ? contact.Research_Experience_After_Viva_Date_Mont__c
            : 0;

        return experienceYears + (experienceMonths / 12);
    }

    /**
     * Step 3: Parse a multi-select picklist value (semicolon-delimited) into a normalized set.
     * Required_Degree__c on Yearly_Schemes__c is configured as a multi-select picklist.
     */
    private static Set<String> splitMultiSelect(String multiSelectValue) {
        Set<String> values = new Set<String>();

        if (String.isBlank(multiSelectValue)) {
            return values;
        }

        for (String valuePart : multiSelectValue.split(';')) {
            String trimmedValue = valuePart.trim();
            if (String.isNotBlank(trimmedValue)) {
                values.add(trimmedValue);
            }
        }

        return values;
    }

    private static EligibilityWrapper buildEligibilityResult(Contact contact, Yearly_Schemes__c yearlyScheme) {
        EligibilityWrapper wrapper = new EligibilityWrapper();
        wrapper.criteriaResults = new List<CriteriaResultWrapper>();

        if (yearlyScheme == null) {
            wrapper.isEligible = false;
            wrapper.eligibilityMessage = 'No active yearly scheme found for this scheme item.';
            return wrapper;
        }

        EligibilityEvaluationService.EligibilityEvaluationResult evaluationResult =
            EligibilityEvaluationService.evaluateYearlyScheme(contact.Id, yearlyScheme.Id);

        wrapper.isEligible = evaluationResult.isEligible;
        wrapper.eligibilityMessage = evaluationResult.overallMessage;

        if (evaluationResult.criteriaResults != null) {
            for (EligibilityEvaluationService.CriteriaResult criteriaResult : evaluationResult.criteriaResults) {
                CriteriaResultWrapper criteriaWrapper = new CriteriaResultWrapper();
                criteriaWrapper.criteriaId = criteriaResult.criteriaId;
                criteriaWrapper.criteriaLabel = criteriaResult.criteriaLabel;
                criteriaWrapper.passed = criteriaResult.passed;
                criteriaWrapper.message = criteriaResult.message;
                criteriaWrapper.formula = criteriaResult.formula;
                criteriaWrapper.validationType = criteriaResult.validationType;
                criteriaWrapper.eligibilityType = criteriaResult.eligibilityType;
                wrapper.criteriaResults.add(criteriaWrapper);
            }
        }

        if (evaluationResult.hasConfiguredCriteria != true) {
            return buildLegacyEligibilityFallback(contact, yearlyScheme, wrapper);
        }

        return wrapper;
    }

    private static EligibilityWrapper buildLegacyEligibilityFallback(
        Contact contact,
        Yearly_Schemes__c yearlyScheme,
        EligibilityWrapper wrapper
    ) {
        List<String> failureReasons = new List<String>();

        Set<String> schemeRequiredDegrees = splitMultiSelect(yearlyScheme.Required_Degree__c);

        if (!schemeRequiredDegrees.isEmpty()) {
            if (String.isBlank(contact.Qualifying_Degree__c)) {
                failureReasons.add('Qualifying degree is not provided on your profile.');
            } else if (!schemeRequiredDegrees.contains(contact.Qualifying_Degree__c)) {
                failureReasons.add(
                    'Your qualifying degree (' + contact.Qualifying_Degree__c +
                    ') does not meet the scheme requirement (' + yearlyScheme.Required_Degree__c + ').'
                );
            }
        }

        if (yearlyScheme.Experience_Required__c != null) {
            Decimal contactExperienceYears = getContactExperienceInYears(contact);

            if (contactExperienceYears < yearlyScheme.Experience_Required__c) {
                failureReasons.add(
                    'Minimum ' + yearlyScheme.Experience_Required__c.intValue() +
                    ' year(s) of research experience after qualifying viva is required. ' +
                    'Your current experience is ' + formatExperienceLabel(contactExperienceYears) + '.'
                );
            }
        }

        wrapper.isEligible = failureReasons.isEmpty();
        wrapper.eligibilityMessage = wrapper.isEligible
            ? 'You are eligible to apply for this scheme.'
            : String.join(failureReasons, ' ');

        return wrapper;
    }

    private static String formatExperienceLabel(Decimal experienceYears) {
        Integer wholeYears = experienceYears.intValue();
        Integer remainingMonths = ((experienceYears - wholeYears) * 12).intValue();

        if (remainingMonths == 0) {
            return wholeYears + ' year(s)';
        }

        return wholeYears + ' year(s) and ' + remainingMonths + ' month(s)';
    }

    private static String formatDuration(Decimal duration) {
        if (duration == null) {
            return null;
        }
        Integer years = duration.intValue();
        return years == 1 ? '1 Year' : years + ' Years';
    }

    private static String formatDeadlineLabel(Datetime deadline) {
        if (deadline == null) {
            return null;
        }
        return deadline.format('d MMMM yyyy');
    }

    private static String toDateString(Datetime value) {
        if (value == null) {
            return null;
        }
        return value.format('yyyy-MM-dd');
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public DataWrapper data;
    }

    global class DataWrapper {
        public YearWrapper year;
        public List<SchemeDataWrapper> schemeAndItemsData;
    }

    global class YearWrapper {
        public String yearId;
        public String yearName;
        public Boolean isActive;
        public Boolean isCurrentYear;
        public Date yearStartDate;
        public Date yearEndDate;
    }

    global class SchemeDataWrapper {
        public String schemeId;
        public String schemeName;
        public String status;
        public String visibility;
        public String description;
        public String schemeType;
        public String schemeDuration;
        public Boolean isActive;
        public List<SchemeLineItemWrapper> schemeLineItems;
    }

    global class SchemeLineItemWrapper {
        public String schemeItemId;
        public String schemeItemName;
        public Decimal duration;
        public String durationLabel;
        public Boolean isActive;
        public String firstPageUrl;
        public YearlySchemeWrapper yearlyScheme;
        public EligibilityWrapper eligibility;
        public ActionsWrapper actions;
    }

    global class YearlySchemeWrapper {
        public String yearlySchemeId;
        public String yearlySchemeName;
        public Boolean isActive;
        public String visibility;
        public String schemeStartDate;
        public String schemeEndDate;
        public String deadlineLabel;
        public String secondStageStartDate;
        public String secondStageEndDate;
        public String applicationStages;
        public Decimal budgetCap;
        public Decimal experienceRequired;
        public String requiredDegree;
        public Decimal teamSizeLimits;
    }

    global class EligibilityWrapper {
        public Boolean isEligible;
        public String eligibilityMessage;
        public List<CriteriaResultWrapper> criteriaResults;
    }

    global class CriteriaResultWrapper {
        public String criteriaId;
        public String criteriaLabel;
        public Boolean passed;
        public String message;
        public String formula;
        public String validationType;
        public String eligibilityType;
    }

    global class ActionsWrapper {
        public Boolean showEligibilityCheck;
        public Boolean canApply;
        public String eligibilityUrl;
        public String applyUrl;
        public String knowMoreUrl;
    }
}