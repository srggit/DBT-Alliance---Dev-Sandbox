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
                Scientific_career_to_date__c = req.scientificCareerToDate,
                Have_you_identified_Sponsor_at_Host_Inst__c = req.haveYouIdentifiedSponserAtHostInstitution,
                Sponsor_Name__c = req.nameOfSponser,
                Sponsor_Designation__c = req.sponserDesignation,
                Sponsor_Department__c = req.sponserDepartment,
                Sponsor_Organisation__c = req.sponserOrganisation,
                Have_you_identified_mentor_on_your_appli__c = req.haveYouIdentifiedMentorOnYourApplication,
                Mentor_Name__c = req.nameOfMentor,
                Mentor_Designation__c = req.mentorDesignation,
                Mentor_Department__c = req.mentorDepartment,
                Mentor_Organisation__c = req.mentorOrganisation,
                Mentor_City__c = req.mentorCity,
                Mentor_Country__c = req.mentorCountry,
                What_guidance_do_you_expect_to_receive__c = req.guidanceReceivedFromMentorAndBenefits,  
                If_identified_External_Sponsor_s_for_Wo__c = req.identifiedExternalSponserForWohiBreifDetails   
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
        public String haveYouIdentifiedSponserAtHostInstitution;
        public string nameOfSponser;
        public string sponserDesignation;
        public string sponserDepartment;
        public string sponserOrganisation;
        public string haveYouIdentifiedMentorOnYourApplication;
        public string nameOfMentor;
        public string mentorDesignation;
        public string mentorDepartment;
        public string mentorOrganisation;
        public string mentorCity;
        public string mentorCountry;
        public string guidanceReceivedFromMentorAndBenefits;
        public string identifiedExternalSponserForWohiBreifDetails;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Id proposalId;
    }
}