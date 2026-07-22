@RestResource(urlMapping='/getReviewerMappingDetail')
global without sharing class getReviewerMappingDetail {

    @HttpGet
    global static ApplicantHostWrapper doGet() {

        ApplicantHostWrapper response = new ApplicantHostWrapper();

        try {
            RestRequest req = RestContext.request;
            String contactId = req.params.get('contactId'); // Reviewer's Contact Id

            if (String.isBlank(contactId)) {
                response.success = false;
                response.message = 'Contact Id is required';
                return response;
            }

            // ---- Step 1: Get Reviewer Mapping records for this reviewer ----
            // Traverse directly: Proposal__r.Proposal_Id__c and Proposal__r.Yearly_Scheme__r.Scheme__c
            List<Reviewer_Mapping__c> mappings = [
                SELECT Id, Status__c, Proposal__c,
                       Proposal__r.Proposal_Id__c,
                       Proposal__r.Yearly_Scheme__r.Scheme__c
                FROM Reviewer_Mapping__c
                WHERE Contact__c = :contactId
            ];

            if (mappings.isEmpty()) {
                response.success = true;
                response.message = 'No reviewer mappings found';
                response.reviewerMappingDetails = new List<ReviewerMappingWrapper>();
                return response;
            }

            // ---- Collect distinct Proposal Ids ----
            Set<Id> proposalIds = new Set<Id>();
            for (Reviewer_Mapping__c rm : mappings) {
                if (rm.Proposal__c != null) {
                    proposalIds.add(rm.Proposal__c);
                }
            }

            // ---- Step 2: Get Applicant Name(s) per Proposal via Applicant_Proposal_Association__c ----
            Map<Id, List<String>> proposalIdToApplicantNames = new Map<Id, List<String>>();
            List<Applicant_Proposal_Association__c> associations = [
                SELECT Id, Proposal__c, Contact__c, Contact__r.Name
                FROM Applicant_Proposal_Association__c
                WHERE Proposal__c IN :proposalIds  AND Contact__c != null Limit 1
            ];

            for (Applicant_Proposal_Association__c apa : associations) {
                if (apa.Proposal__c == null) continue;

                if (!proposalIdToApplicantNames.containsKey(apa.Proposal__c)) {
                    proposalIdToApplicantNames.put(apa.Proposal__c, new List<String>());
                }
                if (apa.Contact__r != null) {
                    proposalIdToApplicantNames.get(apa.Proposal__c).add(apa.Contact__r.Name);
                }
            }

            // ---- Build final wrapper list ----
            List<ReviewerMappingWrapper> resultList = new List<ReviewerMappingWrapper>();

            for (Reviewer_Mapping__c rm : mappings) {
                ReviewerMappingWrapper rmw = new ReviewerMappingWrapper();
                rmw.reviewerMappingId = rm.Id;
                rmw.status = rm.Status__c;
                rmw.proposalId = rm.Proposal__c;
                rmw.proposalNumber = rm.Proposal__r?.Proposal_Id__c;
                rmw.schemeName = rm.Proposal__r?.Yearly_Scheme__r?.Scheme__c;
                rmw.applicantNames = proposalIdToApplicantNames.containsKey(rm.Proposal__c)
                                    ? proposalIdToApplicantNames.get(rm.Proposal__c)
                                    : new List<String>();
                resultList.add(rmw);
            }

            response.success = true;
            response.message = 'Success';
            response.reviewerMappingDetails = resultList;

        } catch (Exception e) {
            response.success = false;
            response.message = 'Error: ' + e.getMessage();
        }

        return response;
    }

    // ---- Wrapper classes ----
    global class ApplicantHostWrapper {
        global Boolean success;
        global String message;
        global List<ReviewerMappingWrapper> reviewerMappingDetails;
    }

    global class ReviewerMappingWrapper {
        global String reviewerMappingId;
        global String status;
        global String proposalId;
        global String proposalNumber;       // Proposal__r.Proposal_Id__c
        global String schemeName;           // Proposal__r.Yearly_Scheme__r.Scheme__c
        global List<String> applicantNames; // From Applicant_Proposal_Association__c.Contact__r.Name
    }
}