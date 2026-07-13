@RestResource(urlMapping='/createProposal')
global without sharing class createProposalAPI {

    @HttpPost
    global static ResponseWrapper createProposal() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if (String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required field: contactId';
                return response;        
            }

            if (String.isBlank(req.proposalId)) {
                Proposal__c proposal = new Proposal__c();
                proposal.Project_Title__c = req.projectTitle;
                proposal.Outline_of_proposed_research__c = req.outlineOfProposedWord;
                proposal.Keywords__c = req.keywords;
                proposal.Significance_of_the_proposed_work__c = req.signinficanceOfProposedWork;
                proposal.Research_References__c = req.researchReferences;
                proposal.Yearly_Scheme__c = req.yearlySchemeId;
                insert proposal;

                Applicant_Proposal_Association__c association = new Applicant_Proposal_Association__c(
                    Contact__c = req.contactId,
                    Proposal__c = proposal.Id
                );
                insert association;

                response.success = true;
                response.message = 'Proposal & APA created successfully.';
                response.proposalId = proposal.Id;
                response.apaId = association.Id;
                response.proposal = proposal;
            } else {
                Proposal__c proposal = new Proposal__c(
                    Id = req.proposalId,
                    Project_Title__c = req.projectTitle,
                    Outline_of_proposed_research__c = req.outlineOfProposedWord,
                    Keywords__c = req.keywords,
                    Significance_of_the_proposed_work__c = req.signinficanceOfProposedWork,
                    Research_References__c = req.researchReferences,
                    Yearly_Scheme__c = req.yearlySchemeId
                );
                update proposal;

                List<Applicant_Proposal_Association__c> associations = [
                    SELECT Id
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :req.proposalId
                    AND Contact__c = :req.contactId
                    AND Proposal__r.Yearly_Scheme__c = :req.yearlySchemeId
                    LIMIT 1
                ];

                response.success = true;
                response.message = 'Proposal updated successfully.';
                response.proposalId = proposal.Id;

                if (!associations.isEmpty()) {
                    response.apaId = associations[0].Id;
                }

                response.proposal = [
                    SELECT Id, Project_Title__c, Outline_of_proposed_research__c, Keywords__c,
                           Significance_of_the_proposed_work__c, Research_References__c, Yearly_Scheme__c
                    FROM Proposal__c
                    WHERE Id = :proposal.Id
                    LIMIT 1
                ];
            }
        }
        catch (System.JSONException e) {
            response.success = false;
            response.message = 'Invalid request body.';
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    global class RequestWrapper {
        public String proposalId;
        public String projectTitle;
        public String outlineOfProposedWord;
        public String keywords;
        public String signinficanceOfProposedWork;
        public String researchReferences;
        public String contactId;
        public String yearlySchemeId;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Proposal__c proposal;
        public String proposalId;
        public String apaId;
    }
}
