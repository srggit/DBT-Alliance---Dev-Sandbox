@RestResource(urlMapping='/dashboard/*')
global without sharing class DashboardAPI {

    private static final Set<String> APPLICATION_STATUSES = new Set<String>{
        'Draft',
        'Submitted'
    };

    private static final Set<String> EXCLUDED_GRANT_STATUSES = new Set<String>{
        'Draft',
        'Submitted',
        'Rejected'
    };

    @HttpGet
    global static ResponseWrapper getDashboard() {
        ResponseWrapper response = new ResponseWrapper();
        response.activeGrants = new List<ProposalWrapper>();
        response.activeApplication = new List<ProposalWrapper>();
        response.yearlySchemeDetails = new List<YearlySchemeWrapper>();
        response.activeGrantCount = 0;
        response.activeApplicationCount = 0;

        try {
            String contactId = RestContext.request.params.get('contactId');

            if (String.isBlank(contactId)) {
                response.success = false;
                response.message = 'Contact ID is required';
                return response;
            }

            List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                response.success = false;
                response.message = 'No contact found for the provided contactId';
                return response;
            }

            List<Applicant_Proposal_Association__c> associationList = [
                SELECT Id, Contact__c, Proposal__c, Yearly_Scheme__c, Proposal__r.Name, Proposal__r.Proposal_Id__c, Proposal__r.Proposal_Status__c, Proposal__r.Application_Stages__c, Proposal__r.Project_Title__c, Proposal__r.Application_Date__c, Proposal__r.Yearly_Scheme__c, Proposal__r.Yearly_Scheme__r.Name, Proposal__r.Yearly_Scheme__r.Scheme_Items__c, Proposal__r.Yearly_Scheme__r.Scheme_Items__r.Name, Proposal__r.Yearly_Scheme__r.Scheme_Start_Date__c, Proposal__r.Yearly_Scheme__r.Scheme_End_Date__c, Proposal__r.Yearly_Scheme__r.Application_Stages__c, Yearly_Scheme__r.Name, Yearly_Scheme__r.Scheme_Items__c, Yearly_Scheme__r.Scheme_Items__r.Name
                FROM Applicant_Proposal_Association__c
                WHERE Contact__c = :contactId
                AND Proposal__c != null
            ];
            System.debug('associationList: ' + associationList);

            for (Applicant_Proposal_Association__c apa : associationList) {   // 3
                String proposalStatus = apa.Proposal__r.Proposal_Status__c;
                ProposalWrapper proposalWrapper = buildProposalWrapper(apa);

                if (String.isNotBlank(proposalStatus) && APPLICATION_STATUSES.contains(proposalStatus)) {
                    response.activeApplicationCount++;
                    response.activeApplication.add(proposalWrapper);
                } 
                else if (String.isNotBlank(proposalStatus) && !EXCLUDED_GRANT_STATUSES.contains(proposalStatus)) {
                    response.activeGrantCount++;
                    response.activeGrants.add(proposalWrapper);
                }
            }

            List<Yearly_Schemes__c> yearlySchemes = [
                SELECT Id, Name, Is_Active__c, Scheme_Visibility__c, Scheme_Start_Date__c, Scheme_End_Date__c, Second_Stage_Start_Date__c, Second_Stage_End_Date__c, Approval_Status__c, Application_Stages__c, Budget_Cap__c, Experience_Required__c, Required_Degree__c, Team_Size_Limits__c, Scheme_Items__c, Scheme_Items__r.Name, Year__c, Year__r.Name, Year__r.Is_Active__c, Year__r.Is_Current_Year__c
                FROM Yearly_Schemes__c
                WHERE Is_Active__c = true
                AND Year__r.Is_Active__c = true
                AND Year__r.Is_Current_Year__c = true
                ORDER BY Name
            ];

            for (Yearly_Schemes__c yearlyScheme : yearlySchemes) {
                response.yearlySchemeDetails.add(buildYearlySchemeWrapper(yearlyScheme));
            }

            response.success = true;
            response.message = 'Dashboard data fetched successfully';
        } catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    private static ProposalWrapper buildProposalWrapper(Applicant_Proposal_Association__c apa) {
        ProposalWrapper wrapper = new ProposalWrapper();
        Yearly_Schemes__c apaYearlyScheme = apa.Yearly_Scheme__r;
        Yearly_Schemes__c proposalYearlyScheme = apa.Proposal__r.Yearly_Scheme__r;
        Yearly_Schemes__c selectedYearlyScheme = apaYearlyScheme != null ? apaYearlyScheme : proposalYearlyScheme;

        wrapper.apaId = apa.Id;
        wrapper.contactId = apa.Contact__c;
        wrapper.proposalId = apa.Proposal__c;
        wrapper.proposalName = apa.Proposal__r.Name;
        wrapper.proposalNumber = apa.Proposal__r.Proposal_Id__c;
        wrapper.proposalStatus = apa.Proposal__r.Proposal_Status__c;
        wrapper.applicationStage = apa.Proposal__r.Application_Stages__c;
        wrapper.applicationDate = apa.Proposal__r.Application_Date__c;
        wrapper.yearlySchemeId = apa.Yearly_Scheme__c != null ? apa.Yearly_Scheme__c : apa.Proposal__r.Yearly_Scheme__c;
        wrapper.yearlySchemeName = selectedYearlyScheme != null ? selectedYearlyScheme.Name : null;
        wrapper.schemeItemId = selectedYearlyScheme != null ? selectedYearlyScheme.Scheme_Items__c : null;
        wrapper.schemeItemName = selectedYearlyScheme != null && selectedYearlyScheme.Scheme_Items__r != null ? selectedYearlyScheme.Scheme_Items__r.Name : null;
        return wrapper;
    }

    private static YearlySchemeWrapper buildYearlySchemeWrapper(Yearly_Schemes__c yearlyScheme) {
        YearlySchemeWrapper wrapper = new YearlySchemeWrapper();
        wrapper.yearlySchemeId = yearlyScheme.Id;
        wrapper.yearlySchemeName = yearlyScheme.Name;
        wrapper.isActive = yearlyScheme.Is_Active__c;
        wrapper.visibility = yearlyScheme.Scheme_Visibility__c;
        wrapper.approvalStatus = yearlyScheme.Approval_Status__c;
        wrapper.schemeStartDate = toDateString(yearlyScheme.Scheme_Start_Date__c);
        wrapper.schemeEndDate = toDateString(yearlyScheme.Scheme_End_Date__c);
        wrapper.secondStageStartDate = toDateString(yearlyScheme.Second_Stage_Start_Date__c);
        wrapper.secondStageEndDate = toDateString(yearlyScheme.Second_Stage_End_Date__c);
        wrapper.applicationStages = yearlyScheme.Application_Stages__c;
        wrapper.budgetCap = yearlyScheme.Budget_Cap__c;
        wrapper.experienceRequired = yearlyScheme.Experience_Required__c;
        wrapper.teamSizeLimits = yearlyScheme.Team_Size_Limits__c;
        wrapper.requiredDegree = yearlyScheme.Required_Degree__c;
        wrapper.schemeItemId = yearlyScheme.Scheme_Items__c;
        wrapper.schemeItemName = yearlyScheme.Scheme_Items__r != null ? yearlyScheme.Scheme_Items__r.Name : null;
        wrapper.yearId = yearlyScheme.Year__c;
        wrapper.yearName = yearlyScheme.Year__r != null ? yearlyScheme.Year__r.Name : null;
        wrapper.yearIsActive = yearlyScheme.Year__r != null ? yearlyScheme.Year__r.Is_Active__c : null;
        wrapper.yearIsCurrentYear = yearlyScheme.Year__r != null ? yearlyScheme.Year__r.Is_Current_Year__c : null;
        return wrapper;
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
        public Integer activeGrantCount;
        public Integer activeApplicationCount;

        public List<ProposalWrapper> activeGrants;
        public List<ProposalWrapper> activeApplication;
        public List<YearlySchemeWrapper> yearlySchemeDetails;
    }

    global class ProposalWrapper {
        public Id apaId;
        public Id contactId;
        public Id proposalId;
        public String proposalName;
        public String proposalNumber;
        public String proposalStatus;
        public String applicationStage;
        public Date applicationDate;
        public Id yearlySchemeId;
        public String yearlySchemeName;
        public Id schemeItemId;
        public String schemeItemName;
    }

    global class YearlySchemeWrapper {
        public Id yearlySchemeId;
        public String yearlySchemeName;
        public Boolean isActive;
        public String visibility;
        public String approvalStatus;
        public String schemeStartDate;
        public String schemeEndDate;
        public String secondStageStartDate;
        public String secondStageEndDate;
        public String applicationStages;
        public Decimal budgetCap;
        public Decimal experienceRequired;
        public String requiredDegree;
        public Decimal teamSizeLimits;
        public Id schemeItemId;
        public String schemeItemName;
        public Id schemeId;
        public Id yearId;
        public String yearName;
        public Boolean yearIsActive;
        public Boolean yearIsCurrentYear;
    }
}