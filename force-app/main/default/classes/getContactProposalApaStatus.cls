@RestResource(urlMapping='/getContactProposalApaStatus')
global without sharing class getContactProposalApaStatus {
//Passing Contact id and getting APA,Proposal,Active Yearly Scheme,Proposal Status,Proposal Application Stage and isApplied status in response 
    @HttpGet
    global static ResponseWrapper getContactProposalApaStatus() {

        ResponseWrapper response = new ResponseWrapper();

        try {
            String contactId = RestContext.request.params.get('contactId');

            if (String.isBlank(contactId)) {
                response.success = false;
                response.message = 'Contact ID is required';
                return response;
            }

            List<Applicant_Proposal_Association__c> associationList = [
                SELECT Id,
                       Contact__c,
                       Proposal__c,
                       Proposal__r.Yearly_Scheme__c,
                       Proposal__r.Proposal_Status__c,
                       Proposal__r.Application_Stages__c,
                       Proposal__r.Yearly_Scheme__r.Is_Active__c,
                       Proposal__r.Yearly_Scheme__r.Year__r.Is_Active__c,
                       Proposal__r.Yearly_Scheme__r.Year__r.Is_Current_Year__c
                FROM Applicant_Proposal_Association__c
                WHERE Contact__c = :contactId
                AND Proposal__r.Yearly_Scheme__r.Is_Active__c = true
                AND Proposal__r.Yearly_Scheme__r.Year__r.Is_Active__c = true
                AND Proposal__r.Yearly_Scheme__r.Year__r.Is_Current_Year__c = true
                LIMIT 1
            ];

            if (!associationList.isEmpty()) {

                Applicant_Proposal_Association__c apa = associationList[0];

                ProposalDetails details = new ProposalDetails();
                details.contactId = apa.Contact__c;
                details.apaId = apa.Id;
                details.proposalId = apa.Proposal__c;
                details.yearlySchemeId = apa.Proposal__r.Yearly_Scheme__c;
                details.proposalStatus = apa.Proposal__r.Proposal_Status__c;
                details.proposalApplicationStage = apa.Proposal__r.Application_Stages__c;
                details.isApplied = true;

                response.success = true;
                response.message = 'Proposal found.';
                response.applicantionDetail = details;
            } else {

                ProposalDetails details = new ProposalDetails();
                details.contactId = (Id)contactId;
                details.isApplied = false;

                response.success = true;
                response.message = 'No proposal found.';
                response.applicantionDetail = details;
            }

        } catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    // Response Wrapper
    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public ProposalDetails applicantionDetail;
    }

    // Data Wrapper
    global class ProposalDetails {
        public Id contactId;
        public Id apaId;
        public Id proposalId;
        public Id yearlySchemeId;
        public String proposalStatus;
        public String proposalApplicationStage;
        public Boolean isApplied;
    }
}