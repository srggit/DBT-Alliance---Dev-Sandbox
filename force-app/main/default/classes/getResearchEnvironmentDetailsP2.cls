// @RestResource(urlMapping='/getResearchEnvironmentDetailsP2')
// global without sharing class getResearchEnvironmentDetailsP2 {

//     @HttpGet
//     global static ResponseWrapper getResearchEnvironmentDetailsP2(){
//         ResponseWrapper response = new ResponseWrapper();

//         try{
//             String proposalId = RestContext.request.params.get('proposalId');
//             if(String.isBlank(proposalId)){
//                 response.success = false;
//                 response.message = 'Proposal ID is required';
//                 return response;
//             }

//             Proposal__c proposal = [
//                 SELECT Id, Why_FH_Host_is_Suitable_Choice__c, Host_Institution_Infrastructure__c, Alternative_Facility_Arrangements__c, Previous_Collaboration__c, Describe_WOHI_Plan_and_Sponsor_s__c, Status_at_the_Host_Institution__c, Start_Date_of_Host_Appointment__c, Current_Position_At_Host_Institution__c,
//                 Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c,Sponsor_Department__c,Sponsor_Organisation__c,Have_you_identified_mentor_on_your_appli__c,
//                 Mentor_Name__c,Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
//                 FROM Proposal__c
//                 WHERE Id = :proposalId
//             ];

//             if(proposal == null){
//                 response.success = false;
//                 response.message = 'Proposal not found';
//                 return response;
//             }

//             List<ResearchDetailsWrapper> researchEnvironmentDetails = new List<ResearchDetailsWrapper>();
//             ResearchDetailsWrapper researchDetailsWrapper = new ResearchDetailsWrapper();
//             researchDetailsWrapper.whyHostLaboratoryIsSuitableForWork = proposal.Why_FH_Host_is_Suitable_Choice__c;
//             researchDetailsWrapper.infrastructureFacilitiesOfHostInst = proposal.Host_Institution_Infrastructure__c;
//             researchDetailsWrapper.alternativeFacilityArrangements = proposal.Alternative_Facility_Arrangements__c;
//             researchDetailsWrapper.previousCollaboration = proposal.Previous_Collaboration__c;
//             researchDetailsWrapper.describeWOHIPlanAndSponsor = proposal.Describe_WOHI_Plan_and_Sponsor_s__c;
//             researchDetailsWrapper.statusAtHostInstitution = proposal.Status_at_the_Host_Institution__c;
//             researchDetailsWrapper.startDateOfAppointmentAtHostInstitution = proposal.Start_Date_of_Host_Appointment__c;
//             researchDetailsWrapper.currentPositionAtHostInstitution = proposal.Current_Position_At_Host_Institution__c;
//             researchDetailsWrapper.haveYouIdentifiedSponserAtHostInstitution = proposal.Have_you_identified_Sponsor_at_Host_Inst__c;
//             researchDetailsWrapper.nameOfSponser = proposal.Sponsor_Name__c;
//             researchDetailsWrapper.sponserDesignation = proposal.Sponsor_Designation__c;
//             researchDetailsWrapper.sponserDepartment = proposal.Sponsor_Department__c;
//             researchDetailsWrapper.sponserOrganisation = proposal.Sponsor_Organisation__c;
//             researchDetailsWrapper.haveYouIdentifiedMentorOnYourApplication = proposal.Have_you_identified_mentor_on_your_appli__c;
//             researchDetailsWrapper.nameOfMentor = proposal.Mentor_Name__c;
//             researchDetailsWrapper.mentorDesignation = proposal.Mentor_Designation__c;
//             researchDetailsWrapper.mentorDepartment = proposal.Mentor_Department__c;
//             researchDetailsWrapper.mentorOrganisation = proposal.Mentor_Organisation__c;
//             researchDetailsWrapper.mentorCity = proposal.Mentor_City__c;
//             researchDetailsWrapper.mentorCountry = proposal.Mentor_Country__c;
//             researchDetailsWrapper.guidanceReceivedFromMentorAndBenefits = proposal.What_guidance_do_you_expect_to_receive__c;
//             researchDetailsWrapper.identifiedExternalSponserFWohiBreifDetails = proposal.If_identified_External_Sponsor_s_for_Wo__c;

//             researchEnvironmentDetails.add(researchDetailsWrapper);
//             response.success = true;
//             response.message = 'Research environment details fetched successfully.';
//             response.researchEnvironmentDetails = researchEnvironmentDetails;
//         }
//         catch(Exception e){
//             response.success = false;
//             response.message = e.getMessage();
//             System.debug('Error: ' + e.getMessage());
//             System.debug('Error: ' + e.getStackTraceString());
//             System.debug('Error: ' + e.getLineNumber());
//         }

//         return response;
//     }
    
//     global class ResponseWrapper {
//         public Boolean success;
//         public String message;
//         public List<ResearchDetailsWrapper> researchEnvironmentDetails;
//     }

//     global class ResearchDetailsWrapper {
//         public String whyHostLaboratoryIsSuitableForWork;
//         public String infrastructureFacilitiesOfHostInst;
//         public String alternativeFacilityArrangements;
//         public String previousCollaboration;
//         public String describeWOHIPlanAndSponsor;
//         public String statusAtHostInstitution;
//         public Date startDateOfAppointmentAtHostInstitution;
//         public String currentPositionAtHostInstitution;
//         public string haveYouIdentifiedSponserAtHostInstitution;
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
//         public string identifiedExternalSponserFWohiBreifDetails;
//     }    
// }








/*
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

            List<Proposal__c> proposalList = [
                SELECT Id, Why_FH_Host_is_Suitable_Choice__c, Host_Institution_Infrastructure__c, Alternative_Facility_Arrangements__c, Previous_Collaboration__c, Describe_WOHI_Plan_and_Sponsor_s__c, Status_at_the_Host_Institution__c, Start_Date_of_Host_Appointment__c, Current_Position_At_Host_Institution__c,
                Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c,Sponsor_Department__c,Sponsor_Organisation__c,Have_you_identified_mentor_on_your_appli__c,
                Mentor_Name__c,Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
                FROM Proposal__c
                WHERE Id = :proposalId
            ];

            if(proposalList.isEmpty()){
                response.success = false;
                response.message = 'Proposal not found';
                return response;
            }

            Proposal__c proposal = proposalList[0];

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

            // ---- Host Contact details, derived from Applicant_Host_Association__c on this Proposal ----
            List<HostContactWrapper> hostContactDetails = new List<HostContactWrapper>();

            List<Applicant_Host_Association__c> ahaList = [
                SELECT Id, Host__c
                FROM Applicant_Host_Association__c
                WHERE Proposal__c = :proposalId
                AND Host__c != null
            ];

            if(!ahaList.isEmpty()){
                Set<Id> hostAccountIds = new Set<Id>();
                for(Applicant_Host_Association__c aha : ahaList){
                    hostAccountIds.add(aha.Host__c);
                }

                List<Contact> contacts = [
                    SELECT Id, Name, Salutation, FirstName, MiddleName, LastName, Suffix,Account.Name,
                           AccountId, Email, Birthdate, Department, Gender__c, Nationality__c,
                           MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                           OwnerId, CreatedById, LastModifiedById, CurrencyIsoCode
                    FROM Contact
                    WHERE AccountId IN :hostAccountIds
                ];

                for(Contact con : contacts){
                    HostContactWrapper hostWrapper = new HostContactWrapper();
                    hostWrapper.contactId = con.Id;
                    hostWrapper.name = con.Name;
                    hostWrapper.salutation = con.Salutation;
                    hostWrapper.firstName = con.FirstName;
                    hostWrapper.middleName = con.MiddleName;
                    hostWrapper.lastName = con.LastName;
                    hostWrapper.suffix = con.Suffix;
                    hostWrapper.accountId = con.AccountId;
                    hostWrapper.accountName = con.Account.Name;
                    hostWrapper.email = con.Email;
                    hostWrapper.birthdate = con.Birthdate;
                    hostWrapper.department = con.Department;
                    hostWrapper.gender = con.Gender__c;
                    hostWrapper.nationality = con.Nationality__c;
                    hostWrapper.mailingStreet = con.MailingStreet;
                    hostWrapper.mailingCity = con.MailingCity;
                    hostWrapper.mailingState = con.MailingState;
                    hostWrapper.mailingPostalCode = con.MailingPostalCode;
                    hostWrapper.mailingCountry = con.MailingCountry;
                    hostWrapper.currencyPicklist = con.CurrencyIsoCode;
                    hostContactDetails.add(hostWrapper);
                }
            }

            response.success = true;
            response.message = 'Research environment details fetched successfully.';
            response.researchEnvironmentDetails = researchEnvironmentDetails;
            response.hostContactDetails = hostContactDetails;
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
        public List<HostContactWrapper> hostContactDetails;
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

    global class HostContactWrapper {
        public Id contactId;
        public String name;
        public String salutation;
        public String firstName;
        public String middleName;
        public String lastName;
        public String suffix;
        public Id accountId;
        public String accountName;
        public String email;
        public Date birthdate;
        public String department;
        public String gender;
        public String nationality;
        public String mailingStreet;
        public String mailingCity;
        public String mailingState;
        public String mailingPostalCode;
        public String mailingCountry;
        public String currencyPicklist;
    }
}*/









@RestResource(urlMapping='/getResearchEnvironmentDetailsP2')
global without sharing class getResearchEnvironmentDetailsP2 {

    @HttpGet
    global static ResponseWrapper getResearchEnvironmentDetailsP2(){
        ResponseWrapper response = new ResponseWrapper();

        try{
            String proposalId = RestContext.request.params.get('proposalId');
            String apaId = RestContext.request.params.get('apaId');
            System.debug('proposalId: ' + proposalId);
            System.debug('apaId: ' + apaId);
            if(String.isBlank(proposalId)){
                response.success = false;
                response.message = 'Proposal ID is required';
                return response;
            }

            List<Proposal__c> proposalList = [
                SELECT Id, Why_FH_Host_is_Suitable_Choice__c, Host_Institution_Infrastructure__c, Alternative_Facility_Arrangements__c, Previous_Collaboration__c, Describe_WOHI_Plan_and_Sponsor_s__c, Status_at_the_Host_Institution__c, Start_Date_of_Host_Appointment__c, Current_Position_At_Host_Institution__c,
                Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c,Sponsor_Department__c,Sponsor_Organisation__c,Have_you_identified_mentor_on_your_appli__c,
                Mentor_Name__c,Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
                FROM Proposal__c
                WHERE Id = :proposalId
            ];
            List<Scheme_Section__c> schemeSectionList = [
                SELECT Id, Name, Applicant_Proposal_Association__c, Data_Filled_Successfully__c, Section_Name__c
                FROM Scheme_Section__c
                WHERE Applicant_Proposal_Association__c = :apaId
            ];
            System.debug('schemeSectionList: ' + schemeSectionList);
             List<SectionWrapper> sectionWrappers = new List<SectionWrapper>();
            for(Scheme_Section__c section : schemeSectionList){
                SectionWrapper sw = new SectionWrapper();
                sw.sectionId = section.Id;
                sw.sectionName = section.Section_Name__c;
                sw.sectionStatus = section.Data_Filled_Successfully__c;
                sectionWrappers.add(sw);
            }
            response.sections = sectionWrappers;


            if(proposalList.isEmpty()){
                response.success = false;
                response.message = 'Proposal not found';
                return response;
            }

            Proposal__c proposal = proposalList[0];

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

            // ---- Host Contact details ----
            // Priority 1: contacts already saved as Proposal_Participant_Association__c for this proposal
            // Priority 2 (fallback): all contacts under the Host Account(s) linked via Applicant_Host_Association__c
            List<HostContactWrapper> hostContactDetails = new List<HostContactWrapper>();
            Boolean hostContactsSourcedFromParticipants = false;

            List<Proposal_Participant_Association__c> ppaList = [
                SELECT Id, Participant__c, Roles__c
                FROM Proposal_Participant_Association__c
                WHERE Proposal__c = :proposalId
                AND Participant__c != null
            ];

            Set<Id> contactIdsToQuery = new Set<Id>();
            Map<Id, String> contactIdToRole = new Map<Id, String>();

            if(!ppaList.isEmpty()){
                hostContactsSourcedFromParticipants = true;
                for(Proposal_Participant_Association__c ppa : ppaList){
                    contactIdsToQuery.add(ppa.Participant__c);
                    contactIdToRole.put(ppa.Participant__c, ppa.Roles__c);
                }
            }
            else{
                List<Applicant_Host_Association__c> ahaList = [
                    SELECT Id, Host__c
                    FROM Applicant_Host_Association__c
                    WHERE Proposal__c = :proposalId
                    AND Host__c != null
                ];

                if(!ahaList.isEmpty()){
                    Set<Id> hostAccountIds = new Set<Id>();
                    for(Applicant_Host_Association__c aha : ahaList){
                        hostAccountIds.add(aha.Host__c);
                    }

                    List<Contact> hostAccountContacts = [
                        SELECT Id FROM Contact WHERE AccountId IN :hostAccountIds
                    ];
                    for(Contact con : hostAccountContacts){
                        contactIdsToQuery.add(con.Id);
                    }
                }
            }

            if(!contactIdsToQuery.isEmpty()){
                List<Contact> contacts = [
                    SELECT Id, Name, Salutation, FirstName, MiddleName, LastName, Suffix, Account.Name,
                           AccountId, Email, Birthdate, Department, Gender__c, Nationality__c,
                           MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                           OwnerId, CreatedById, LastModifiedById, CurrencyIsoCode
                    FROM Contact
                    WHERE Id IN :contactIdsToQuery
                ];

                for(Contact con : contacts){
                    HostContactWrapper hostWrapper = new HostContactWrapper();
                    hostWrapper.contactId = con.Id;
                    hostWrapper.name = con.Name;
                    hostWrapper.salutation = con.Salutation;
                    hostWrapper.firstName = con.FirstName;
                    hostWrapper.middleName = con.MiddleName;
                    hostWrapper.lastName = con.LastName;
                    hostWrapper.suffix = con.Suffix;
                    hostWrapper.accountId = con.AccountId;
                    hostWrapper.accountName = con.Account.Name;
                    hostWrapper.email = con.Email;
                    hostWrapper.birthdate = con.Birthdate;
                    hostWrapper.department = con.Department;
                    hostWrapper.gender = con.Gender__c;
                    hostWrapper.nationality = con.Nationality__c;
                    hostWrapper.mailingStreet = con.MailingStreet;
                    hostWrapper.mailingCity = con.MailingCity;
                    hostWrapper.mailingState = con.MailingState;
                    hostWrapper.mailingPostalCode = con.MailingPostalCode;
                    hostWrapper.mailingCountry = con.MailingCountry;
                    hostWrapper.currencyPicklist = con.CurrencyIsoCode;
                    hostWrapper.role = contactIdToRole.get(con.Id);
                    hostContactDetails.add(hostWrapper);
                }
            }

            response.success = true;
            response.message = 'Research environment details fetched successfully.';
            response.researchEnvironmentDetails = researchEnvironmentDetails;
            response.hostContactDetails = hostContactDetails;
            response.hostContactsSourcedFromParticipants = hostContactsSourcedFromParticipants;
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
        public List<HostContactWrapper> hostContactDetails;
        public Boolean hostContactsSourcedFromParticipants;
        public List<SectionWrapper> sections;
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

    global class HostContactWrapper {
        public Id contactId;
        public String name;
        public String salutation;
        public String firstName;
        public String middleName;
        public String lastName;
        public String suffix;
        public Id accountId;
        public String accountName;
        public String email;
        public Date birthdate;
        public String department;
        public String gender;
        public String nationality;
        public String mailingStreet;
        public String mailingCity;
        public String mailingState;
        public String mailingPostalCode;
        public String mailingCountry;
        public String currencyPicklist;
        public String role;
    }
    global class SectionWrapper {
        public String sectionId;
        public String sectionName;
        public Boolean sectionStatus;
    }
}