// @RestResource(urlMapping='/saveResearchEnvironmentDetailsAPI/*')
// global without sharing class SaveResearchEnvironmentDetailsAPI {
//     @HttpPost
//     global static ResponseWrapper saveResearchEnvironmentDetails() {
//         ResponseWrapper response = new ResponseWrapper();
//         try {
//             String requestBody = RestContext.request.requestBody.toString();
//             RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);


//             Proposal__c proposalHostInformation = new Proposal__c(
//                 Id = req.proposalId,
//                 Why_FH_Host_is_Suitable_Choice__c = req.whyHostLaboratoryIsSuitableForWork,
//                 Host_Institution_Infrastructure__c = req.infrastructureFacilitiesOfHostInst,
//                 Alternative_Facility_Arrangements__c = req.alternativeFacilityArrangements,
//                 Previous_Collaboration__c = req.previousCollaboration,
//                 Describe_WOHI_Plan_and_Sponsor_s__c = req.describeWOHIPlanAndSponsor,
//                 Status_at_the_Host_Institution__c = req.statusAtHostInstitution,
//                 Start_Date_of_Host_Appointment__c = req.startDateOfAppointmentAtHostInstitution,
//                 Current_Position_At_Host_Institution__c = req.currentPositionAtHostInstitution,
//                 Have_you_identified_Sponsor_at_Host_Inst__c = req.haveYouIdentifiedSponserAtHostInstitution,
//                 Sponsor_Name__c = req.nameOfSponser,
//                 Sponsor_Designation__c = req.sponserDesignation,
//                 Sponsor_Department__c = req.sponserDepartment,
//                 Sponsor_Organisation__c = req.sponserOrganisation,
//                 Have_you_identified_mentor_on_your_appli__c = req.haveYouIdentifiedMentorOnYourApplication,
//                 Mentor_Name__c = req.nameOfMentor,
//                 Mentor_Designation__c = req.mentorDesignation,
//                 Mentor_Department__c = req.mentorDepartment,
//                 Mentor_Organisation__c = req.mentorOrganisation,
//                 Mentor_City__c = req.mentorCity,
//                 Mentor_Country__c = req.mentorCountry,
//                 What_guidance_do_you_expect_to_receive__c = req.guidanceReceivedFromMentorAndBenefits,  
//                 If_identified_External_Sponsor_s_for_Wo__c = req.identifiedExternalSponserForWohiBreifDetails    
//             );
//             update proposalHostInformation;

//             response.success = true;
//             response.message = 'Research environment details saved successfully.';

//         }
//         catch (Exception e) {
//             response.success = false;
//             response.message = e.getMessage();
//             System.debug('Error: ' + e.getMessage());
//             System.debug('Error: ' + e.getStackTraceString());
//             System.debug('Error: ' + e.getLineNumber());
//         }
//         return response;
//     }


//     global class RequestWrapper {
//         public String proposalId;
//         public String whyHostLaboratoryIsSuitableForWork;
//         public String infrastructureFacilitiesOfHostInst;
//         public String alternativeFacilityArrangements;
//         public String previousCollaboration;
//         public String describeWOHIPlanAndSponsor;
//         public String statusAtHostInstitution;
//         public Date startDateOfAppointmentAtHostInstitution;
//         public String currentPositionAtHostInstitution;
//         public String haveYouIdentifiedSponserAtHostInstitution;
//         public string nameOfSponser;
//         public string sponserDesignation;
//         public string sponserDepartment;
//         public string sponserOrganisation;
//         public string haveYouIdentifiedMentorOnYourApplication;
//         public string nameOfMentor;
//         public string mentorDesignation;
//         public string mentorDepartment;
//         public string mentorOrganisation;
//         public string mentorCity;
//         public string mentorCountry;
//         public string guidanceReceivedFromMentorAndBenefits;
//         public string identifiedExternalSponserForWohiBreifDetails;
//     }

//     global class ResponseWrapper {
//         public Boolean success;
//         public String message;
//     }
// }






@RestResource(urlMapping='/saveResearchEnvironmentDetailsAPI/*')
global without sharing class SaveResearchEnvironmentDetailsAPI {
    @HttpPost
    global static ResponseWrapper saveResearchEnvironmentDetails() {
        ResponseWrapper response = new ResponseWrapper();
        Savepoint sp = Database.setSavepoint();

        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if(String.isBlank(req.proposalId)){
                response.success = false;
                response.message = 'Proposal ID is required';
                return response;
            }

            Proposal__c proposalHostInformation = new Proposal__c(
                Id = req.proposalId,
                Why_FH_Host_is_Suitable_Choice__c = req.whyHostLaboratoryIsSuitableForWork,
                Host_Institution_Infrastructure__c = req.infrastructureFacilitiesOfHostInst,
                Alternative_Facility_Arrangements__c = req.alternativeFacilityArrangements,
                Previous_Collaboration__c = req.previousCollaboration,
                Describe_WOHI_Plan_and_Sponsor_s__c = req.describeWOHIPlanAndSponsor,
                Status_at_the_Host_Institution__c = req.statusAtHostInstitution,
                Start_Date_of_Host_Appointment__c = req.startDateOfAppointmentAtHostInstitution,
                Current_Position_At_Host_Institution__c = req.currentPositionAtHostInstitution,
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
            update proposalHostInformation;
            String apaId = req.apaId;
            
            System.debug('apaId: ' + apaId);
            String sectionName = req.sectionName;
            if (String.isNotBlank(req.sectionName) && String.isNotBlank(req.apaId)) { 
                List<Scheme_Section__c> schemeSectionList = [
                    SELECT Id, Name, Applicant_Proposal_Association__c, Data_Filled_Successfully__c, Section_Name__c
                    FROM Scheme_Section__c
                    WHERE Applicant_Proposal_Association__c = :req.apaId
                    AND Section_Name__c = :req.sectionName
                ];
                 System.debug('Line 144 schemeSectionList: ' + schemeSectionList);

                if (!schemeSectionList.isEmpty()) {
                    schemeSectionList[0].Data_Filled_Successfully__c = true;
                    update schemeSectionList;
                    response.sectionUpdateResult = true;
                } 
                else {
                    response.sectionUpdateResult = false;
                }
            }


            // ---- Proposal Participant Association creation from selected host contacts ----
            List<Id> ppaIds = new List<Id>();

            if(req.participants != null && !req.participants.isEmpty()){

                List<Proposal_Participant_Association__c> ppaListToInsert = new List<Proposal_Participant_Association__c>();

                for(ParticipantWrapper participant : req.participants){
                    if(String.isBlank(participant.contactId)){
                        continue;
                    }
                    ppaListToInsert.add(new Proposal_Participant_Association__c(
                        Proposal__c = req.proposalId,
                        Participant__c = participant.contactId,
                        Roles__c = participant.role
                    ));
                }

                if(!ppaListToInsert.isEmpty()){
                    insert ppaListToInsert;
                    for(Proposal_Participant_Association__c ppa : ppaListToInsert){
                        ppaIds.add(ppa.Id);
                    }
                }
            }

            response.success = true;
            response.message = 'Research environment details saved successfully.';
            response.ppaIds = ppaIds;

        }
        catch (Exception e) {
            Database.rollback(sp);
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
        public String apaId;
        public String sectionName;
        public String whyHostLaboratoryIsSuitableForWork;
        public String infrastructureFacilitiesOfHostInst;
        public String alternativeFacilityArrangements;
        public String previousCollaboration;
        public String describeWOHIPlanAndSponsor;
        public String statusAtHostInstitution;
        public Date startDateOfAppointmentAtHostInstitution;
        public String currentPositionAtHostInstitution;
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
        public List<ParticipantWrapper> participants;
    }

    global class ParticipantWrapper {
        public String contactId;
        public String role;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<Id> ppaIds;
        public Boolean sectionUpdateResult;
    }
}