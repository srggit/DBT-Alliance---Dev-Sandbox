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
                SELECT Id, Why_FH_Host_is_Suitable_Choice__c, Host_Institution_Infrastructure__c, Alternative_Facility_Arrangements__c, Previous_Collaboration__c, Describe_WOHI_Plan_and_Sponsor_s__c, Status_at_the_Host_Institution__c, Start_Date_of_Host_Appointment__c, Current_Position_At_Host_Institution__c,
                Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c,Sponsor_Department__c,Sponsor_Organisation__c,Have_you_identified_mentor_on_your_appli__c,
                Mentor_Name__c,Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
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
            researchDetailsWrapper.haveYouIdentifiedSponserAtHostInstitution = proposal.Have_you_identified_Sponsor_at_Host_Inst__c;
            researchDetailsWrapper.nameOfSponser = proposal.Sponsor_Name__c;
            researchDetailsWrapper.sponserDesignation = proposal.Sponsor_Designation__c;
            researchDetailsWrapper.sponserDepartment = proposal.Sponsor_Department__c;
            researchDetailsWrapper.sponserOrganisation = proposal.Sponsor_Organisation__c;
            researchDetailsWrapper.haveYouIdentifiedMentorOnYourApplication = proposal.Have_you_identified_mentor_on_your_appli__c;
            researchDetailsWrapper.nameOfMentor = proposal.Mentor_Name__c;
            researchDetailsWrapper.mentorDesignation = proposal.Mentor_Designation__c;
            researchDetailsWrapper.mentorDepartment = proposal.Mentor_Department__c;
            researchDetailsWrapper.mentorOrganisation = proposal.Mentor_Organisation__c;
            researchDetailsWrapper.mentorCity = proposal.Mentor_City__c;
            researchDetailsWrapper.mentorCountry = proposal.Mentor_Country__c;
            researchDetailsWrapper.guidanceReceivedFromMentorAndBenefits = proposal.What_guidance_do_you_expect_to_receive__c;
            researchDetailsWrapper.identifiedExternalSponserFWohiBreifDetails = proposal.If_identified_External_Sponsor_s_for_Wo__c;

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
        public string haveYouIdentifiedSponserAtHostInstitution;
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
        public string identifiedExternalSponserFWohiBreifDetails;
    }    
}