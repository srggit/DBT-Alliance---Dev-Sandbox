@RestResource(urlMapping='/ProposalDeclaration/submit/*')
global without sharing class SaveProposalDeclarationAPI {

    @HttpPost
    global static SaveDeclarationResponseWrapper saveDeclaration() {
        SaveDeclarationResponseWrapper response = new SaveDeclarationResponseWrapper();
        Savepoint sp = Database.setSavepoint();

        try {
            RestRequest req = RestContext.request;
            SaveDeclarationRequestWrapper reqBody =
                (SaveDeclarationRequestWrapper) JSON.deserialize(
                    req.requestBody.toString(), SaveDeclarationRequestWrapper.class
                );

            // ---- Resolve the APA record (dual-lookup pattern) ----
            Applicant_Proposal_Association__c apaRecord;

            if (String.isNotBlank(reqBody.apaId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :reqBody.apaId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given apaId.';
                    return response;
                }
                apaRecord = apaList[0];

            } else if (String.isNotBlank(reqBody.proposalId) && String.isNotBlank(reqBody.contactId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :reqBody.proposalId
                    AND Contact__c = :reqBody.contactId
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

            // ---- Update APA declarations ----
            apaRecord.Declaration_1__c = reqBody.declaration1;
            apaRecord.Declaration_2__c = reqBody.declaration2;
            update apaRecord;

            // ---- Update related Proposal__c ----
            if (apaRecord.Proposal__c == null) {
                response.success = false;
                response.message = 'Applicant Proposal Association is not linked to a Proposal record.';
                Database.rollback(sp);
                return response;
            }

            List<Proposal__c> proposalList = [
                SELECT Id, Proposal_Status__c, Application_Date__c
                FROM Proposal__c
                WHERE Id = :apaRecord.Proposal__c
                LIMIT 1
            ];

            if (proposalList.isEmpty()) {
                response.success = false;
                response.message = 'Linked Proposal record could not be found.';
                Database.rollback(sp);
                return response;
            }

            Proposal__c proposalRecord = proposalList[0];

            // ---- Idempotency guard: block re-submission ----
            if (proposalRecord.Proposal_Status__c == 'Submitted') {
                response.success = false;
                response.message = 'Proposal has already been submitted and cannot be re-submitted.';
                response.apaId = apaRecord.Id;
                response.proposalId = proposalRecord.Id;
                Database.rollback(sp);
                return response;
            }

            proposalRecord.Proposal_Status__c = 'Submitted';
            proposalRecord.Application_Date__c = Date.today();
            update proposalRecord;

            response.success = true;
            response.message = 'Declarations saved and proposal submitted successfully.';
            response.apaId = apaRecord.Id;
            response.proposalId = proposalRecord.Id;
        } catch (Exception ex) {
            Database.rollback(sp);
            response.success = false;
            response.message = 'Error saving declaration: ' + ex.getMessage();
        }

        return response;
    }

    global class SaveDeclarationRequestWrapper {
        global String apaId;
        global String proposalId;
        global String contactId;
        global Boolean declaration1;
        global Boolean declaration2;
    }

    global class SaveDeclarationResponseWrapper {
        global Boolean success;
        global String message;
        global String apaId;
        global String proposalId;
    }
}