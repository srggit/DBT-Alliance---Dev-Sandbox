@RestResource(urlMapping='/saveApplicantCVDetails')
global without sharing class saveApplicantCVDetailsAPI {

    @HttpPost
    global static ResponseWrapper saveApplicantCVDetails() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            // if(String.isBlank(req.contactId)) {
            //     response.success = false;
            //     response.message = 'Missing required field: contactId';
            //     return response;
            // }

            if(String.isBlank(req.proposalId)) {
                response.success = false;
                response.message = 'Missing required field: proposalId';
                return response;
            }

            Proposal__c updatedProposal = new Proposal__c(
                Id = req.proposalId,
                Title_of_Thesis_Dissertation__c = req.titleThesisDissertation,
                Research_Summary_During_Highest_Degree__c = req.researchSummaryDuringHigherDegree,
                Scientific_Meetings__c = req.scientificMeetings,
                Scientific_career_to_date__c = req.scientificCareerToDate
            );
            update updatedProposal;

            response.success = true;
            response.message = 'Proposal updated successfully';
            response.proposalId = req.proposalId;     
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    global class RequestWrapper {
        public String proposalId;
        public String titleThesisDissertation;
        public String researchSummaryDuringHigherDegree;
        public String scientificMeetings;
        public String scientificCareerToDate;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Id proposalId;
    }
}