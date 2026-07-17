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

            // Validate applicant contact from request parameter.
            List<Contact> contacts = [
                SELECT Id
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
            Id applicantContactId = contact.Id;

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

            Set<Id> yearlySchemeIds = new Set<Id>();
            for (Yearly_Schemes__c yearlySchemeRecord : yearlySchemeByItemId.values()) {
                yearlySchemeIds.add(yearlySchemeRecord.Id);
            }

            // Map yearly scheme Id -> proposal status for schemes the contact has already applied to.
            Map<Id, String> proposalStatusByYearlySchemeId = new Map<Id, String>();
            Map<Id, Id> proposalIdByYearlySchemeId = new Map<Id, Id>();
            Map<Id, Id> apaIdByYearlySchemeId = new Map<Id, Id>();

            if (!yearlySchemeIds.isEmpty()) {
                for (Applicant_Proposal_Association__c apaRecord : [
                    SELECT Id, Yearly_Scheme__c, Proposal__r.Proposal_Status__c,
                           Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Contact__c = :contactId
                    AND Yearly_Scheme__c IN :yearlySchemeIds
                ]) {
                    if (apaRecord.Yearly_Scheme__c != null) {
                        proposalStatusByYearlySchemeId.put(apaRecord.Yearly_Scheme__c, apaRecord.Proposal__r.Proposal_Status__c);
                        proposalIdByYearlySchemeId.put(apaRecord.Yearly_Scheme__c, apaRecord.Proposal__c);
                        apaIdByYearlySchemeId.put(apaRecord.Yearly_Scheme__c, apaRecord.Id);
                    }
                }
            }

            System.debug('proposalStatusByYearlySchemeId: ' + proposalStatusByYearlySchemeId);

            Map<Id, EligibilityEvaluationService.EligibilityEvaluationResult> eligibilityByYearlySchemeId =
                EligibilityEvaluationService.evaluateYearlySchemes(applicantContactId, yearlySchemeIds);

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
                    schemeData.schemeLineItems.add(
                        buildLineItemWrapper(
                            item,
                            yearlySchemeByItemId.get(item.Id),
                            eligibilityByYearlySchemeId,
                            proposalStatusByYearlySchemeId,
                            proposalIdByYearlySchemeId,
                            apaIdByYearlySchemeId
                        )
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
        Map<Id, EligibilityEvaluationService.EligibilityEvaluationResult> eligibilityByYearlySchemeId,
        Map<Id, String> proposalStatusByYearlySchemeId,
        Map<Id, Id> proposalIdByYearlySchemeId,
        Map<Id, Id> apaIdByYearlySchemeId
    ) {
        SchemeLineItemWrapper lineItem = new SchemeLineItemWrapper();
        lineItem.schemeItemId = item.Id;
        lineItem.schemeItemName = item.Name;
        lineItem.duration = item.Duration__c;
        lineItem.durationLabel = formatDuration(item.Duration__c);
        lineItem.isActive = item.Is_Active__c;
        lineItem.firstPageUrl = item.First_Page_URL__c;
        lineItem.yearlyScheme = buildYearlySchemeWrapper(yearlyScheme, proposalStatusByYearlySchemeId, proposalIdByYearlySchemeId, apaIdByYearlySchemeId);

        EligibilityEvaluationService.EligibilityEvaluationResult evaluationResult = yearlyScheme != null
            ? eligibilityByYearlySchemeId.get(yearlyScheme.Id)
            : null;
        EligibilityWrapper eligibility = buildEligibilityResult(yearlyScheme, evaluationResult);
        lineItem.eligibility = eligibility;
        lineItem.actions = buildActions(item.Id, yearlyScheme, eligibility);

        return lineItem;
    }

    private static YearlySchemeWrapper buildYearlySchemeWrapper(
        Yearly_Schemes__c yearlyScheme,
        Map<Id, String> proposalStatusByYearlySchemeId,
        Map<Id, Id> proposalIdByYearlySchemeId,
        Map<Id, Id> apaIdByYearlySchemeId
    ) {
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

        Boolean hasApplied = proposalStatusByYearlySchemeId != null && proposalStatusByYearlySchemeId.containsKey(yearlyScheme.Id);
        wrapper.appliedStatus = hasApplied;
        wrapper.proposalStatus = hasApplied ? proposalStatusByYearlySchemeId.get(yearlyScheme.Id) : null;
        wrapper.proposalId = proposalIdByYearlySchemeId.get(yearlyScheme.Id);
        wrapper.apaId = apaIdByYearlySchemeId.get(yearlyScheme.Id);
        return wrapper;
    }

    private static ActionsWrapper buildActions(
        Id schemeItemId,
        Yearly_Schemes__c yearlyScheme,
        EligibilityWrapper eligibility
    ) {
        ActionsWrapper actions = new ActionsWrapper();
        Boolean canInteract = yearlyScheme != null && yearlyScheme.Is_Active__c;
        Boolean isEligible = eligibility != null && eligibility.isEligible == true;
        Boolean canApplyFromEligibility = eligibility != null && eligibility.canApply == true;

        actions.showEligibilityCheck = canInteract;
        actions.canApply = canInteract && canApplyFromEligibility && isEligible;

        if (yearlyScheme != null) {
            actions.eligibilityUrl = '/eligibility/' + yearlyScheme.Id;
            actions.applyUrl = '/apply/' + yearlyScheme.Id;
        }
        actions.knowMoreUrl = '/scheme-item/' + schemeItemId;
        return actions;
    }

    private static EligibilityWrapper buildEligibilityResult(
        Yearly_Schemes__c yearlyScheme,
        EligibilityEvaluationService.EligibilityEvaluationResult evaluationResult
    ) {
        EligibilityWrapper wrapper = new EligibilityWrapper();
        wrapper.criteriaResults = new List<CriteriaResultWrapper>();

        if (yearlyScheme == null) {
            wrapper.isEligible = false;
            wrapper.canApply = false;
            wrapper.hasConfiguredCriteria = false;
            wrapper.eligibilityMessage = 'No active yearly scheme found for this scheme item.';
            return wrapper;
        }

        if (evaluationResult == null) {
            wrapper.isEligible = true;
            wrapper.canApply = yearlyScheme.Is_Active__c == true;
            wrapper.hasConfiguredCriteria = false;
            wrapper.eligibilityMessage = 'No eligibility criteria configured for this scheme.';
            return wrapper;
        }

        wrapper.isEligible = evaluationResult.isEligible == true;
        wrapper.canApply = evaluationResult.canApply == true && yearlyScheme.Is_Active__c == true;
        wrapper.hasConfiguredCriteria = evaluationResult.hasConfiguredCriteria == true;
        wrapper.eligibilityMessage = evaluationResult.overallMessage;

        if (evaluationResult.criteriaResults != null) {
            for (EligibilityEvaluationService.CriteriaResult criteriaResult : evaluationResult.criteriaResults) {
                CriteriaResultWrapper criteriaWrapper = new CriteriaResultWrapper();
                criteriaWrapper.criteriaId = criteriaResult.criteriaId;
                criteriaWrapper.criteriaLabel = criteriaResult.criteriaLabel;
                criteriaWrapper.passed = criteriaResult.passed == true;
                criteriaWrapper.status = criteriaResult.status;
                criteriaWrapper.message = criteriaResult.message;
                criteriaWrapper.formula = criteriaResult.formula;
                criteriaWrapper.validationType = criteriaResult.validationType;
                criteriaWrapper.eligibilityType = criteriaResult.eligibilityType;
                wrapper.criteriaResults.add(criteriaWrapper);
            }
        }

        return wrapper;
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
        public Boolean appliedStatus;
        public String proposalStatus;
        public String proposalId;
        public String apaId;
    }

    global class EligibilityWrapper {
        public Boolean isEligible;
        public Boolean canApply;
        public Boolean hasConfiguredCriteria;
        public String eligibilityMessage;
        public List<CriteriaResultWrapper> criteriaResults;
    }

    global class CriteriaResultWrapper {
        public String criteriaId;
        public String criteriaLabel;
        public Boolean passed;
        public String status;
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