@RestResource(urlMapping='/getOtherGrantsAndApplicationDetails')
global without sharing class getOtherGrantsAndApplicationDetails {

    @HttpGet
    global static ResponseWrapper getOtherGrantsAndApplicationDetails() {
        ResponseWrapper response = new ResponseWrapper();

        try {
            RestRequest req = RestContext.request;
            String apaIdParam = req.params.get('apaId');
            String proposalId = req.params.get('proposalId');
            String contactIdParam = req.params.get('contactId');

            Id apaRecordId;
            Id contactRecordId = String.isBlank(contactIdParam) ? null : (Id) contactIdParam;

            // ---- Resolve APA Id (same pattern as before) ----
            if (!String.isBlank(apaIdParam)) {
                apaRecordId = apaIdParam;
            }
            else if (!String.isBlank(proposalId)) {
                List<Applicant_Proposal_Association__c> associations = [
                    SELECT Id, Proposal__c, Contact__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :proposalId
                    AND Contact__c = :contactRecordId
                    LIMIT 1
                ];

                if (associations.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the provided proposalId';
                    return response;
                }

                apaRecordId = associations[0].Id;
            } else {
                response.success = false;
                response.message = 'Missing required field: provide either apaId or proposalId (with contactId)';
                return response;
            }

            // ---- Fetch main APA / Other Grants & Application Details fields ----
            List<Applicant_Proposal_Association__c> apaList = [
                SELECT Id, Contact__c,
                       Have_you_applied_to_Alliance_before__c,
                       Previous_Application_Reference_Number__c,
                       Previous_Application_Project_Title__c,
                       Decision_on_previous_application__c,
                       Key_difference_from_previous_application__c,
                       Other_Ongoing_Applications__c,
                       Name_of_the_Ongoing_funding_agency__c,
                       Ongoing_Project_Title__c,
                       Abstract_Ongoing__c,
                       Overlap_with_current_IA_application__c,
                       Type_of_funding__c,
                       Your_Role_on_the_Application__c,
                       Expected_date_of_decision__c
                FROM Applicant_Proposal_Association__c
                WHERE Id = :apaRecordId
                LIMIT 1
            ];

            if (apaList.isEmpty()) {
                response.success = false;
                response.message = 'No Applicant Proposal Association record found for the given Id';
                return response;
            }

            Applicant_Proposal_Association__c apa = apaList[0];

            // Derive contactId from APA record if it wasn't passed explicitly
            if (contactRecordId == null) {
                contactRecordId = apa.Contact__c;
            }

            response.success = true;
            response.message = 'Other grants and application details retrieved successfully';
            response.apaId = apa.Id;

            response.firstApplicationWithAlliance = apa.Have_you_applied_to_Alliance_before__c;
            response.previousApplReferenceNumber = apa.Previous_Application_Reference_Number__c;
            response.previousApplProjectTitle_Alliance = apa.Previous_Application_Project_Title__c;
            response.prevoiusApplDecision = apa.Decision_on_previous_application__c;
            response.keyDifferencesFromPreviousApplication = apa.Key_difference_from_previous_application__c;

            response.otherOngoingApplications = apa.Other_Ongoing_Applications__c;
            response.nameOfFundingAgencyAndScheme = apa.Name_of_the_Ongoing_funding_agency__c;
            response.projectTitle_Ongoing = apa.Ongoing_Project_Title__c;
            response.abstract_Ongoing = apa.Abstract_Ongoing__c;
            response.degreeOfOverlapWithCurrentAllianceApplication = apa.Overlap_with_current_IA_application__c;
            response.typeOfFunding_Ongoing = apa.Type_of_funding__c;
            response.yourRoleOnApplication_Ongoing = apa.Your_Role_on_the_Application__c;
            response.expectedDateOfDecision_Ongoing = apa.Expected_date_of_decision__c;

            // ---- Fetch Existing Grants: try by APA first, fallback to Contact ----
            List<Existing_Grants__c> existingGrants = [
                SELECT Id, Name, Title__c, Funding_Agency__c, Type__c,
                       Role_of_Applicant__c, Start_Date__c, End_Date__c,
                       Duration_In_Months__c, Total_Award_Amount__c,
                       Currency__c, CurrencyIsoCode, Other_Currency__c,
                       Abstracts_of_ongoing_grants_fellowship__c,
                       Applicant_Proposal_Association__c, Contact__c
                FROM Existing_Grants__c
                WHERE Applicant_Proposal_Association__c = :apaRecordId
            ];

            Boolean usedContactFallback = false;

            if (existingGrants.isEmpty() && contactRecordId != null) {
                existingGrants = [
                    SELECT Id, Name, Title__c, Funding_Agency__c, Type__c,
                           Role_of_Applicant__c, Start_Date__c, End_Date__c,
                           Duration_In_Months__c, Total_Award_Amount__c,
                           Currency__c, CurrencyIsoCode, Other_Currency__c,
                           Abstracts_of_ongoing_grants_fellowship__c,
                           Applicant_Proposal_Association__c, Contact__c
                    FROM Existing_Grants__c
                    WHERE Contact__c = :contactRecordId
                ];
                usedContactFallback = true;
            }

            response.existingGrantsSourcedFromContact = usedContactFallback;
            response.existingGrants = new List<ExistingGrantWrapper>();

            for (Existing_Grants__c eg : existingGrants) {
                ExistingGrantWrapper w = new ExistingGrantWrapper();
                w.id = eg.Id;
                w.name = eg.Name;
                w.title = eg.Title__c;
                w.fundingAgency = eg.Funding_Agency__c;
                w.type = eg.Type__c;
                w.roleOfApplicant = eg.Role_of_Applicant__c;
                w.startDate = eg.Start_Date__c;
                w.endDate = eg.End_Date__c;
                w.durationInMonths = eg.Duration_In_Months__c;
                w.totalAwardAmount = eg.Total_Award_Amount__c;
                w.currencyPicklist = eg.Currency__c;                
                w.otherCurrency = eg.Other_Currency__c;
                w.abstractOfOngoingGrant = eg.Abstracts_of_ongoing_grants_fellowship__c;
                w.applicantProposalAssociationId = eg.Applicant_Proposal_Association__c;
                w.contactId = eg.Contact__c;

                response.existingGrants.add(w);
            }
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Id apaId;

        public String firstApplicationWithAlliance;
        public String previousApplReferenceNumber;
        public String previousApplProjectTitle_Alliance;
        public String prevoiusApplDecision;
        public String keyDifferencesFromPreviousApplication;

        public String otherOngoingApplications;
        public String nameOfFundingAgencyAndScheme;
        public String projectTitle_Ongoing;
        public String abstract_Ongoing;
        public String degreeOfOverlapWithCurrentAllianceApplication;
        public String typeOfFunding_Ongoing;
        public String yourRoleOnApplication_Ongoing;
        public Date expectedDateOfDecision_Ongoing;

        public Boolean existingGrantsSourcedFromContact;
        public List<ExistingGrantWrapper> existingGrants;
    }

    global class ExistingGrantWrapper {
        public Id id;
        public String name;
        public String title;
        public String fundingAgency;
        public String type;
        public String roleOfApplicant;
        public Date startDate;
        public Date endDate;
        public Decimal durationInMonths;
        public Decimal totalAwardAmount;
        public String currencyPicklist;       
        public String otherCurrency;
        public String abstractOfOngoingGrant;
        public Id applicantProposalAssociationId;
        public Id contactId;
    }
}