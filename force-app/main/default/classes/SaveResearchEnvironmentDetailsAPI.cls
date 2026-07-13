@RestResource(urlMapping='/saveResearchEnvironmentDetailsAPI/*')
global without sharing class SaveResearchEnvironmentDetailsAPI {
    @HttpPost
    global static ResponseWrapper saveResearchEnvironmentDetails() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);


            Proposal__c proposalHostInformation = new Proposal__c(
                Id = req.proposalId,
                Why_FH_Host_is_Suitable_Choice__c = req.whyHostLaboratoryIsSuitableForWork,
                Host_Institution_Infrastructure__c = req.infrastructureFacilitiesOfHostInst,
                Alternative_Facility_Arrangements__c = req.alternativeFacilityArrangements,
                Previous_Collaboration__c = req.previousCollaboration,
                Describe_WOHI_Plan_and_Sponsor_s__c = req.describeWOHIPlanAndSponsor,
                Status_at_the_Host_Institution__c = req.statusAtHostInstitution,
                Start_Date_of_Host_Appointment__c = req.startDateOfAppointmentAtHostInstitution,
                Current_Position_At_Host_Institution__c = req.currentPositionAtHostInstitution
            );
            update proposalHostInformation;

            response.success = true;
            response.message = 'Research environment details saved successfully.';

        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
            System.debug('Error: ' + e.getMessage());
            System.debug('Error: ' + e.getStackTraceString());
            System.debug('Error: ' + e.getLineNumber());
        }
        return response;
    }


    global class RequestWrapper {
        public String proposalId;
        public String whyHostLaboratoryIsSuitableForWork;
        public String infrastructureFacilitiesOfHostInst;
        public String alternativeFacilityArrangements;
        public String previousCollaboration;
        public String describeWOHIPlanAndSponsor;
        public String statusAtHostInstitution;
        public Date startDateOfAppointmentAtHostInstitution;
        public String currentPositionAtHostInstitution;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
    }
}