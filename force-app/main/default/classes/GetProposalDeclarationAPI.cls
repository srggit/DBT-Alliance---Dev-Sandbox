@RestResource(urlMapping='/ProposalDeclaration/get/*')
global without sharing class GetProposalDeclarationAPI {

    @HttpGet
    global static GetDeclarationResponseWrapper getDeclaration() {
        GetDeclarationResponseWrapper response = new GetDeclarationResponseWrapper();

        try {
            RestRequest req = RestContext.request;
            String apaId = req.params.get('apaId');
            String proposalId = req.params.get('proposalId');
            String contactId = req.params.get('contactId');

            Applicant_Proposal_Association__c apaRecord;

            if (String.isNotBlank(apaId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :apaId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given apaId.';
                    return response;
                }
                apaRecord = apaList[0];

            } else if (String.isNotBlank(proposalId) && String.isNotBlank(contactId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :proposalId
                    AND Contact__c = :contactId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given proposalId/contactId combination.';
                    return response;
                }
                apaRecord = apaList[0];

            } else {
                response.success = false;
                response.message = 'Either apaId, or both proposalId and contactId, must be provided.';
                return response;
            }

            response.declaration1 = apaRecord.Declaration_1__c;
            response.declaration2 = apaRecord.Declaration_2__c;
            response.apaId = apaRecord.Id;

            if (apaRecord.Proposal__c != null) {
                List<Proposal__c> proposalList = [
                    SELECT Id, Proposal_Status__c, Application_Date__c
                    FROM Proposal__c
                    WHERE Id = :apaRecord.Proposal__c
                    LIMIT 1
                ];
                if (!proposalList.isEmpty()) {
                    response.proposalId = proposalList[0].Id;
                    response.proposalStatus = proposalList[0].Proposal_Status__c;
                    response.applicationDate = proposalList[0].Application_Date__c;
                }
            }

            response.success = true;
            response.message = 'Declaration and proposal details retrieved successfully.';

        } catch (Exception ex) {
            response.success = false;
            response.message = 'Error retrieving declaration: ' + ex.getMessage();
        }

        return response;
    }

    global class GetDeclarationResponseWrapper {
        global Boolean success;
        global String message;
        global String apaId;
        global String proposalId;
        global Boolean declaration1;
        global Boolean declaration2;
        global String proposalStatus;
        global Date applicationDate;
    }
}