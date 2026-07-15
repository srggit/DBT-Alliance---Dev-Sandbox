@RestResource(urlMapping='/getResearchEnvironmentDetailsP2')
global without sharing class getResearchEnvironmentDetailsP2 {

    @HttpGet
    global static ResponseWrapper getResearchEnvironmentDetailsP2(){
        ResponseWrapper response = new ResponseWrapper();

        try{
            String proposalId = RestContext.request.params.get('proposalId');
            if(String.isBlank(proposalId)){
                response.success = false;
                response.message = 'Proposal ID is required';
                return response;
            }

            Proposal__c proposal = [
                SELECT Id, Why_FH_Host_is_Suitable_Choice__c, Host_Institution_Infrastructure__c, Alternative_Facility_Arrangements__c, Previous_Collaboration__c, Describe_WOHI_Plan_and_Sponsor_s__c, Status_at_the_Host_Institution__c, Start_Date_of_Host_Appointment__c, Current_Position_At_Host_Institution__c
                FROM Proposal__c
                WHERE Id = :proposalId
            ];

            if(proposal == null){
                response.success = false;
                response.message = 'Proposal not found';
                return response;
            }

            List<ResearchDetailsWrapper> researchEnvironmentDetails = new List<ResearchDetailsWrapper>();
            ResearchDetailsWrapper researchDetailsWrapper = new ResearchDetailsWrapper();
            researchDetailsWrapper.whyHostLaboratoryIsSuitableForWork = proposal.Why_FH_Host_is_Suitable_Choice__c;
            researchDetailsWrapper.infrastructureFacilitiesOfHostInst = proposal.Host_Institution_Infrastructure__c;
            researchDetailsWrapper.alternativeFacilityArrangements = proposal.Alternative_Facility_Arrangements__c;
            researchDetailsWrapper.previousCollaboration = proposal.Previous_Collaboration__c;
            researchDetailsWrapper.describeWOHIPlanAndSponsor = proposal.Describe_WOHI_Plan_and_Sponsor_s__c;
            researchDetailsWrapper.statusAtHostInstitution = proposal.Status_at_the_Host_Institution__c;
            researchDetailsWrapper.startDateOfAppointmentAtHostInstitution = proposal.Start_Date_of_Host_Appointment__c;
            researchDetailsWrapper.currentPositionAtHostInstitution = proposal.Current_Position_At_Host_Institution__c;

            researchEnvironmentDetails.add(researchDetailsWrapper);
            response.success = true;
            response.message = 'Research environment details fetched successfully.';
            response.researchEnvironmentDetails = researchEnvironmentDetails;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            System.debug('Error: ' + e.getMessage());
            System.debug('Error: ' + e.getStackTraceString());
            System.debug('Error: ' + e.getLineNumber());
        }

        return response;
    }
    
    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<ResearchDetailsWrapper> researchEnvironmentDetails;
    }

    global class ResearchDetailsWrapper {
        public String whyHostLaboratoryIsSuitableForWork;
        public String infrastructureFacilitiesOfHostInst;
        public String alternativeFacilityArrangements;
        public String previousCollaboration;
        public String describeWOHIPlanAndSponsor;
        public String statusAtHostInstitution;
        public Date startDateOfAppointmentAtHostInstitution;
        public String currentPositionAtHostInstitution;
    }    
}