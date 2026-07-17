@RestResource(urlMapping='/getProjectSummaryDetailsP1')
global with sharing class getProjectSummaryDetailsP1 {

    @HttpGet
    global static ResponseWrapper getProjectSummaryDetailsP1(){

        ResponseWrapper response = new ResponseWrapper();
        try{
            String proposalId = RestContext.request.params.get('proposalId');
            String contactId = RestContext.request.params.get('contactId');
            String apaId = RestContext.request.params.get('apaId');

            System.debug('proposalId: ' + proposalId);
            System.debug('contactId: ' + contactId);
            System.debug('apaId: ' + apaId);

            if(String.isBlank(proposalId) && String.isBlank(apaId)){
                response.success = false;   
                response.message = 'Proposal ID or APA ID is required';
                return response;
            }

            List<Proposal__c> proposals = [
                SELECT Id, 
                Project_Title__c, 
                Outline_of_proposed_research__c, 
                Keywords__c, 
                Significance_of_the_proposed_work__c, 
                Research_References__c
                FROM Proposal__c
                WHERE Id = :proposalId
            ];
            System.debug('proposals: ' + proposals);

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

            List<PublicationRequestWrapper> publicationRequestWrappers = new List<PublicationRequestWrapper>();

            if(String.isNotBlank(apaId)){
                List<Applicant_Proposal_Association__c> applicantProposalAssociations = [
                    SELECT Id, Contact__c,
                    (SELECT Id, Name, Journal_Name__c, Number_of_Citations_at_Present__c, PMID_DOI_URL__c, SR_No__c, Title__c, Author_Names__c
                    FROM Publications_Patents__r)
                    FROM Applicant_Proposal_Association__c 
                    WHERE Id = :apaId
                ];
                if(applicantProposalAssociations.isEmpty()){
                    response.success = false;
                    response.message = 'Applicant proposal association not found';
                }

                for(Publications__c publication : applicantProposalAssociations[0].Publications_Patents__r){
                    PublicationRequestWrapper publicationRequestWrapper = new PublicationRequestWrapper();
                    publicationRequestWrapper.publicationId = publication.Id;
                    publicationRequestWrapper.apaId = applicantProposalAssociations[0].Id;
                    publicationRequestWrapper.contactId = applicantProposalAssociations[0].Contact__c;
                    publicationRequestWrapper.applicantRole = 'Primary';
                    publicationRequestWrapper.authorNames = publication.Author_Names__c;
                    publicationRequestWrapper.journalName = publication.Journal_Name__c;
                    publicationRequestWrapper.numberOfCitationsAtPresent = publication.Number_of_Citations_at_Present__c;
                    publicationRequestWrapper.pmidDoiUrl = publication.PMID_DOI_URL__c;
                    publicationRequestWrapper.srNo = publication.SR_No__c;
                    publicationRequestWrapper.title = publication.Title__c;
                    publicationRequestWrappers.add(publicationRequestWrapper);
                }
            }
            else if(String.isNotBlank(contactId)){
                List<Contact> contacts = [
                    SELECT Id, Name, Email,
                    (SELECT Id, Name, Journal_Name__c, Number_of_Citations_at_Present__c, PMID_DOI_URL__c, SR_No__c, Title__c
                    FROM Publications__r)
                    FROM Contact
                    WHERE Id = :contactId
                ];

                System.debug('contacts: ' + contacts);


                if(contacts.isEmpty()){
                    response.success = false;
                    response.message = 'Contact not found';
                }

                for(Publications__c publication : contacts[0].Publications__r){
                    PublicationRequestWrapper publicationRequestWrapper = new PublicationRequestWrapper();
                    publicationRequestWrapper.publicationId = publication.Id;
                    publicationRequestWrapper.contactId = contacts[0].Id;
                    publicationRequestWrapper.applicantRole = 'Primary';
                    publicationRequestWrapper.authorNames = publication.Author_Names__c;
                    publicationRequestWrapper.journalName = publication.Journal_Name__c;
                    publicationRequestWrapper.numberOfCitationsAtPresent = publication.Number_of_Citations_at_Present__c;
                    publicationRequestWrapper.pmidDoiUrl = publication.PMID_DOI_URL__c;
                    publicationRequestWrapper.srNo = publication.SR_No__c;
                    publicationRequestWrapper.title = publication.Title__c;
                    publicationRequestWrappers.add(publicationRequestWrapper);
                }
            }
            else{
                response.success = false;
                response.message = 'Proposal ID or APA ID is required';
                return response;
            }

            response.proposalWrapper = proposalWrapper;
            response.publicationRequestWrappersList = publicationRequestWrappers;

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
        public List<PublicationRequestWrapper> publicationRequestWrappersList;
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
        // public string haveYouIdentifiedSponserAtHostInstitution;
        // public string nameOfSponser;
        // public string sponserDesignation;
        // public string sponserDepartment;
        // public string sponserOrganisation;
        // public string haveYouIdentifiedMentorOnYourApplication;
        // public string nameOfMentor;
        // public string mentorDesignation;
        // public string mentorDepartment;
        // public string mentorOrganisation;
        // public string mentorCity;
        // public string mentorCountry;
        // public string guidanceReceivedFromMentorAndBenefits;
        // public string identifiedExternalSponserFWohiBreifDetails;
    }

    global class PublicationRequestWrapper {
        public String publicationId;
        public String apaId;
        public String contactId;
        public String applicantRole;
        public String authorNames;
        public String journalName;
        public Decimal numberOfCitationsAtPresent;
        public String pmidDoiUrl;
        public Decimal srNo;
        public String title;
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