@RestResource(urlMapping='/getProjectSummaryDetailsP1')
global with sharing class getProjectSummaryDetailsP1 {

    @HttpGet
    global static ResponseWrapper getProjectSummaryDetailsP1(){
        ResponseWrapper response = new ResponseWrapper();
        try{
            String contactId = RestContext.request.params.get('contactId');
            if(String.isBlank(contactId)){
                response.success = false;
                response.message = 'Contact ID is required';
                return response;
            }

            List<Applicant_Proposal_Association__c> applicantProposalAssociations = [
                SELECT Id, Contact__c, Proposal__c, Proposal__r.Project_Title__c, Proposal__r.Outline_of_proposed_research__c, Proposal__r.Keywords__c, Proposal__r.Significance_of_the_proposed_work__c, Proposal__r.Research_References__c
                FROM Applicant_Proposal_Association__c 
                WHERE Contact__c = :contactId
            ];

            List<ProposalWrapper> proposalWrappers = new List<ProposalWrapper>();
            for(Applicant_Proposal_Association__c applicantProposalAssociation : applicantProposalAssociations){
                ProposalWrapper proposalWrapper = new ProposalWrapper();
                proposalWrapper.projectTitle = applicantProposalAssociation.Proposal__r.Project_Title__c;
                proposalWrapper.outlineOfProposedWord = applicantProposalAssociation.Proposal__r.Outline_of_proposed_research__c;
                proposalWrapper.keywords = applicantProposalAssociation.Proposal__r.Keywords__c;
                proposalWrapper.signinficanceOfProposedWork = applicantProposalAssociation.Proposal__r.Significance_of_the_proposed_work__c;
                proposalWrapper.researchReferences = applicantProposalAssociation.Proposal__r.Research_References__c;
                proposalWrapper.contactId = applicantProposalAssociation.Contact__c;
                proposalWrapper.apaId = applicantProposalAssociation.Id;
                proposalWrapper.proposalId = applicantProposalAssociation.Proposal__c;
                proposalWrappers.add(proposalWrapper);
            }

            response.proposalWrappersList = proposalWrappers;

            if(proposalWrappers.isEmpty()){
                response.success = false;
                response.message = 'Applicant proposal association not found';
                return response;
            }


            response.success = true;
            response.message = 'Applicant proposal association fetched successfully';
            return response;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            return response;
        }
    }

    global class RequestWrapper {
        public String contactId;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<ProposalWrapper> proposalWrappersList;
    }

    global class ProposalWrapper {
        public String projectTitle;
        public String outlineOfProposedWord;
        public String keywords;
        public String signinficanceOfProposedWork;
        public String researchReferences;
        public String contactId;
        public String apaId;
        public String proposalId;
    }
}