@RestResource(urlMapping='/getProjectSummaryDetailsP1')
global with sharing class getProjectSummaryDetailsP1 {

    @HttpGet
    global static ResponseWrapper getProjectSummaryDetailsP1(){

        ResponseWrapper response = new ResponseWrapper();
        try{
            // String contactId = RestContext.request.params.get('contactId');
            // if(String.isBlank(contactId)){
            //     response.success = false;   
            //     response.message = 'Contact ID is required';
            //     return response;
            // }

            String proposalId = RestContext.request.params.get('proposalId');
            String contactId = RestContext.request.params.get('contactId');

            System.debug('proposalId: ' + proposalId);
            System.debug('contactId: ' + contactId);
            
            if(String.isBlank(proposalId)){
                response.success = false;   
                response.message = 'Proposal ID is required';
                return response;
            }

            List<Proposal__c> proposals = [
                SELECT Id, Project_Title__c, Outline_of_proposed_research__c, Keywords__c, Significance_of_the_proposed_work__c, Research_References__c,
                Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c, Sponsor_Designation__c, Sponsor_Department__c, Sponsor_Organisation__c, Have_you_identified_mentor_on_your_appli__c,
                Mentor_Name__c, Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
                FROM Proposal__c
                WHERE Id = :proposalId
            ];

            if(proposals.isEmpty()){
                response.success = false;
                response.message = 'Proposal not found';
                return response;
            }

            Proposal__c proposal = proposals[0];

            ProposalWrapper proposalWrapper = new ProposalWrapper();
            proposalWrapper.projectTitle = proposal.Project_Title__c;
            proposalWrapper.outlineOfProposedWord = proposal.Outline_of_proposed_research__c;
            proposalWrapper.keywords = proposal.Keywords__c;
            proposalWrapper.signinficanceOfProposedWork = proposal.Significance_of_the_proposed_work__c;
            proposalWrapper.researchReferences = proposal.Research_References__c;
            proposalWrapper.proposalId = proposal.Id;
            proposalWrapper.haveYouIdentifiedSponserAtHostInstitution = proposal.Have_you_identified_Sponsor_at_Host_Inst__c;
            proposalWrapper.nameOfSponser = proposal.Sponsor_Name__c;
            proposalWrapper.sponserDesignation = proposal.Sponsor_Designation__c;
            proposalWrapper.sponserDepartment = proposal.Sponsor_Department__c;
            proposalWrapper.sponserOrganisation = proposal.Sponsor_Organisation__c;
            proposalWrapper.haveYouIdentifiedMentorOnYourApplication = proposal.Have_you_identified_mentor_on_your_appli__c;
            proposalWrapper.nameOfMentor = proposal.Mentor_Name__c;
            proposalWrapper.mentorDesignation = proposal.Mentor_Designation__c;
            proposalWrapper.mentorDepartment = proposal.Mentor_Department__c;
            proposalWrapper.mentorOrganisation = proposal.Mentor_Organisation__c;
            proposalWrapper.mentorCity = proposal.Mentor_City__c;
            proposalWrapper.mentorCountry = proposal.Mentor_Country__c;
            proposalWrapper.guidanceReceivedFromMentorAndBenefits = proposal.What_guidance_do_you_expect_to_receive__c;
            proposalWrapper.identifiedExternalSponserFWohiBreifDetails = proposal.If_identified_External_Sponsor_s_for_Wo__c;

            response.proposalWrapper = proposalWrapper;

            response.success = true;
            response.message = 'Proposal fetched successfully';
            return response;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            return response;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public ProposalWrapper proposalWrapper;
    }

    global class ProposalWrapper {
        public String projectTitle;
        public String outlineOfProposedWord;
        public String keywords;
        public String signinficanceOfProposedWork;
        public String researchReferences;
        public String contactId;
        public String apaId;
        public String proposalId;
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


/*

            List<Applicant_Proposal_Association__c> applicantProposalAssociations = [
                SELECT Id, Contact__c, Proposal__c, Proposal__r.Project_Title__c, Proposal__r.Outline_of_proposed_research__c, Proposal__r.Keywords__c, Proposal__r.Significance_of_the_proposed_work__c, Proposal__r.Research_References__c,
                Proposal__r.Have_you_identified_Sponsor_at_Host_Inst__c, Proposal__r.Sponsor_Name__c,Proposal__r.Sponsor_Designation__c, Proposal__r.Sponsor_Department__c,Proposal__r.Sponsor_Organisation__c, Proposal__r.Have_you_identified_mentor_on_your_appli__c,
                Proposal__r.Mentor_Name__c, Proposal__r.Mentor_Designation__c, Proposal__r.Mentor_Department__c, Proposal__r.Mentor_Organisation__c, Proposal__r.Mentor_City__c, Proposal__r.Mentor_Country__c, Proposal__r.What_guidance_do_you_expect_to_receive__c, Proposal__r.If_identified_External_Sponsor_s_for_Wo__c
                FROM Applicant_Proposal_Association__c 
                WHERE Contact__c = :contactId
            ];

            List<ProposalWrapper> proposalWrappers = new List<ProposalWrapper>();
            for(Applicant_Proposal_Association__c applicantProposalAssociation : applicantProposalAssociations){
                ProposalWrapper proposalWrapper = new ProposalWrapper();
                proposalWrapper.projectTitle = applicantProposalAssociation.Proposal__r.Project_Title__c;
                proposalWrapper.outlineOfProposedWord = applicantProposalAssociation.Proposal__r.Outline_of_proposed_research__c;
                proposalWrapper.keywords = applicantProposalAssociation.Proposal__r.Keywords__c;
                proposalWrapper.signinficanceOfProposedWork = applicantProposalAssociation.Proposal__r.Significance_of_the_proposed_work__c;
                proposalWrapper.researchReferences = applicantProposalAssociation.Proposal__r.Research_References__c;
                proposalWrapper.contactId = applicantProposalAssociation.Contact__c;
                proposalWrapper.apaId = applicantProposalAssociation.Id;
                proposalWrapper.proposalId = applicantProposalAssociation.Proposal__c;
                proposalWrapper.haveYouIdentifiedSponserAtHostInstitution = applicantProposalAssociation.Proposal__r.Have_you_identified_Sponsor_at_Host_Inst__c;
                proposalWrapper.nameOfSponser = applicantProposalAssociation.Proposal__r.Sponsor_Name__c;
                proposalWrapper.sponserDesignation = applicantProposalAssociation.Proposal__r.Sponsor_Designation__c;
                proposalWrapper.sponserDepartment = applicantProposalAssociation.Proposal__r.Sponsor_Department__c;
                proposalWrapper.sponserOrganisation = applicantProposalAssociation.Proposal__r.Sponsor_Organisation__c;
                proposalWrapper.haveYouIdentifiedMentorOnYourApplication = applicantProposalAssociation.Proposal__r.Have_you_identified_mentor_on_your_appli__c;
                proposalWrapper.nameOfMentor = applicantProposalAssociation.Proposal__r.Mentor_Name__c;
                proposalWrapper.mentorDesignation = applicantProposalAssociation.Proposal__r.Mentor_Designation__c;
                proposalWrapper.mentorDepartment = applicantProposalAssociation.Proposal__r.Mentor_Department__c;
                proposalWrapper.mentorOrganisation = applicantProposalAssociation.Proposal__r.Mentor_Organisation__c;
                proposalWrapper.mentorCity = applicantProposalAssociation.Proposal__r.Mentor_City__c;
                proposalWrapper.mentorCountry = applicantProposalAssociation.Proposal__r.Mentor_Country__c;
                proposalWrapper.guidanceReceivedFromMentorAndBenefits = applicantProposalAssociation.Proposal__r.What_guidance_do_you_expect_to_receive__c;
                proposalWrapper.identifiedExternalSponserFWohiBreifDetails = applicantProposalAssociation.Proposal__r.If_identified_External_Sponsor_s_for_Wo__c;

                proposalWrappers.add(proposalWrapper);
            }

            response.proposalWrappersList = proposalWrappers;

            if(proposalWrappers.isEmpty()){
                response.success = false;
                response.message = 'Applicant proposal association not found';
                return response;
            }


            response.success = true;
            response.message = 'Applicant proposal association fetched successfully';
            return response;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            return response;
        }
    }

    global class RequestWrapper {
        public String contactId;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<ProposalWrapper> proposalWrappersList;
    }

    global class ProposalWrapper {
        public String projectTitle;
        public String outlineOfProposedWord;
        public String keywords;
        public String signinficanceOfProposedWork;
        public String researchReferences;
        public String contactId;
        public String apaId;
        public String proposalId;
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
*/