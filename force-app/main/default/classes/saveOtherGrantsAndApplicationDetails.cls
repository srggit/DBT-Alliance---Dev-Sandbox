@RestResource(urlMapping='/saveOtherGrantsAndApplicationDetails')
global without sharing class saveOtherGrantsAndApplicationDetails {

    @HttpPost
    global static ResponseWrapper saveOtherGrantsAndApplicationDetails() {
        ResponseWrapper response = new ResponseWrapper();

        try {   
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            Id apaRecordId;

            if (!String.isBlank(req.apaId)) {
                apaRecordId = req.apaId;
            } 
            else if (!String.isBlank(req.proposalId)) {
                List<Applicant_Proposal_Association__c> associations = [
                    SELECT Id, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :req.proposalId
                    AND Contact__c = :req.contactId
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
                response.message = 'Missing required field: provide either apaId or proposalId';
                return response;
            }

            Applicant_Proposal_Association__c updatedAPA = new Applicant_Proposal_Association__c(
                Id = apaRecordId,
                Have_you_applied_to_Alliance_before__c = req.firstApplicationWithAlliance,
                Previous_Application_Reference_Number__c = req.previousApplReferenceNumber,
                Previous_Application_Project_Title__c = req.previousApplProjectTitle_Alliance,
                Decision_on_previous_application__c = req.prevoiusApplDecision,
                Key_difference_from_previous_application__c = req.keyDifferencesFromPreviousApplication,
                
                Other_Ongoing_Applications__c = req.otherOngoingApplications,
                Name_of_the_Ongoing_funding_agency__c = req.nameOfFundingAgencyAndScheme,
                Ongoing_Project_Title__c = req.projectTitle_Ongoing,
                Abstract_Ongoing__c = req.abstract_Ongoing,
                Overlap_with_current_IA_application__c = req.degreeOfOverlapWithCurrentAllianceApplication,
                Type_of_funding__c = req.typeOfFunding_Ongoing,
                Your_Role_on_the_Application__c = req.yourRoleOnApplication_Ongoing,
                Expected_date_of_decision__c = req.expectedDateOfDecision_Ongoing
            );
            update updatedAPA;

            response.success = true;
            response.message = 'Other grants and application details saved successfully';
            response.apaId = updatedAPA.Id;
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    global class RequestWrapper {
        public String proposalId;
        public String apaId;
        public String contactId;
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
    }   

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Id apaId;
    }
}