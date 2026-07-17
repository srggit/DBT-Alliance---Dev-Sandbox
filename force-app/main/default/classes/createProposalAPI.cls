/*@RestResource(urlMapping='/createProposal')
global without sharing class createProposalAPI {

    @HttpPost
    global static ResponseWrapper createProposal() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if (String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required field: contactId';
                return response;        
            }

            if (String.isBlank(req.proposalId)) {
                Proposal__c proposal = new Proposal__c();
                proposal.Project_Title__c = req.projectTitle;
                proposal.Outline_of_proposed_research__c = req.outlineOfProposedWord;
                proposal.Keywords__c = req.keywords;
                proposal.Significance_of_the_proposed_work__c = req.signinficanceOfProposedWork;
                proposal.Research_References__c = req.researchReferences;
                proposal.Yearly_Scheme__c = req.yearlySchemeId;
                proposal.Have_you_identified_Sponsor_at_Host_Inst__c = req.haveYouIdentifiedSponserAtHostInstitution;
                proposal.Sponsor_Name__c = req.nameOfSponser;
                proposal.Sponsor_Designation__c = req.sponserDesignation;
                proposal.Sponsor_Department__c = req.sponserDepartment;
                proposal.Sponsor_Organisation__c = req.sponserOrganisation;
                proposal.Have_you_identified_mentor_on_your_appli__c = req.haveYouIdentifiedMentorOnYourApplication;
                proposal.Mentor_Name__c = req.nameOfMentor;
                proposal.Mentor_Designation__c = req.mentorDesignation;
                proposal.Mentor_Department__c = req.mentorDepartment;
                proposal.Mentor_Organisation__c = req.mentorOrganisation;
                proposal.Mentor_City__c = req.mentorCity;
                proposal.Mentor_Country__c = req.mentorCountry;
                proposal.What_guidance_do_you_expect_to_receive__c = req.guidanceReceivedFromMentorAndBenefits;
                proposal.If_identified_External_Sponsor_s_for_Wo__c = req.identifiedExternalSponserForWohiBreifDetails;   
                insert proposal;

                Applicant_Proposal_Association__c association = new Applicant_Proposal_Association__c(
                    Contact__c = req.contactId,
                    Proposal__c = proposal.Id
                );
                insert association;

                response.success = true;
                response.message = 'Proposal & APA created successfully.';
                response.proposalId = proposal.Id;
                response.apaId = association.Id;
                response.proposal = proposal;
            } else {
                Proposal__c proposal = new Proposal__c(
                    Id = req.proposalId,
                    Project_Title__c = req.projectTitle,
                    Outline_of_proposed_research__c = req.outlineOfProposedWord,
                    Keywords__c = req.keywords,
                    Significance_of_the_proposed_work__c = req.signinficanceOfProposedWork,
                    Research_References__c = req.researchReferences,
                    Yearly_Scheme__c = req.yearlySchemeId,
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
                update proposal;

                List<Applicant_Proposal_Association__c> associations = [
                    SELECT Id
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :req.proposalId
                    AND Contact__c = :req.contactId
                    AND Proposal__r.Yearly_Scheme__c = :req.yearlySchemeId
                    LIMIT 1
                ];

                response.success = true;
                response.message = 'Proposal updated successfully.';
                response.proposalId = proposal.Id;

                if (!associations.isEmpty()) {
                    response.apaId = associations[0].Id;
                }

                response.proposal = [
                    SELECT Id, Project_Title__c, Outline_of_proposed_research__c, Keywords__c,
                           Significance_of_the_proposed_work__c, Research_References__c, Yearly_Scheme__c
                    FROM Proposal__c
                    WHERE Id = :proposal.Id
                    LIMIT 1
                ];
            }
        }
        catch (System.JSONException e) {
            response.success = false;
            response.message = 'Invalid request body.';
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    global class RequestWrapper {
        public String proposalId;
        public String projectTitle;
        public String outlineOfProposedWord;
        public String keywords;
        public String signinficanceOfProposedWork;
        public String researchReferences;
        public String contactId;
        public String yearlySchemeId;
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
        public Proposal__c proposal;
        public String proposalId;
        public String apaId;
    }
}*/


@RestResource(urlMapping='/createProposal')
global without sharing class createProposalAPI {

    @HttpPost
    global static ResponseWrapper createProposal() {
        ResponseWrapper response = new ResponseWrapper();
        Savepoint sp = Database.setSavepoint();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if (String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required field: contactId';
                return response;
            }

            String associationId;

            if (String.isBlank(req.proposalId)) {
                Proposal__c proposal = new Proposal__c();
                proposal.Project_Title__c = req.projectTitle;
                proposal.Outline_of_proposed_research__c = req.outlineOfProposedWord;
                proposal.Keywords__c = req.keywords;
                proposal.Significance_of_the_proposed_work__c = req.signinficanceOfProposedWork;
                proposal.Research_References__c = req.researchReferences;
                proposal.Yearly_Scheme__c = req.yearlySchemeId;
                proposal.Have_you_identified_Sponsor_at_Host_Inst__c = req.haveYouIdentifiedSponserAtHostInstitution;
                proposal.Sponsor_Name__c = req.nameOfSponser;
                proposal.Sponsor_Designation__c = req.sponserDesignation;
                proposal.Sponsor_Department__c = req.sponserDepartment;
                proposal.Sponsor_Organisation__c = req.sponserOrganisation;
                proposal.Have_you_identified_mentor_on_your_appli__c = req.haveYouIdentifiedMentorOnYourApplication;
                proposal.Mentor_Name__c = req.nameOfMentor;
                proposal.Mentor_Designation__c = req.mentorDesignation;
                proposal.Mentor_Department__c = req.mentorDepartment;
                proposal.Mentor_Organisation__c = req.mentorOrganisation;
                proposal.Mentor_City__c = req.mentorCity;
                proposal.Mentor_Country__c = req.mentorCountry;
                proposal.What_guidance_do_you_expect_to_receive__c = req.guidanceReceivedFromMentorAndBenefits;
                proposal.If_identified_External_Sponsor_s_for_Wo__c = req.identifiedExternalSponserForWohiBreifDetails;
                insert proposal;

                Applicant_Proposal_Association__c association = new Applicant_Proposal_Association__c(
                    Contact__c = req.contactId,
                    Proposal__c = proposal.Id
                );
                insert association;

                associationId = association.Id;

                response.success = true;
                response.message = 'Proposal & APA created successfully.';
                response.proposalId = proposal.Id;
                response.apaId = association.Id;
                response.proposal = proposal;
            } else {
                Proposal__c proposal = new Proposal__c(
                    Id = req.proposalId,
                    Project_Title__c = req.projectTitle,
                    Outline_of_proposed_research__c = req.outlineOfProposedWord,
                    Keywords__c = req.keywords,
                    Significance_of_the_proposed_work__c = req.signinficanceOfProposedWork,
                    Research_References__c = req.researchReferences,
                    Yearly_Scheme__c = req.yearlySchemeId,
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
                update proposal;

                List<Applicant_Proposal_Association__c> associations = [
                    SELECT Id
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :req.proposalId
                    AND Contact__c = :req.contactId
                    AND Proposal__r.Yearly_Scheme__c = :req.yearlySchemeId
                    LIMIT 1
                ];

                response.success = true;
                response.message = 'Proposal updated successfully.';
                response.proposalId = proposal.Id;

                if (!associations.isEmpty()) {
                    response.apaId = associations[0].Id;
                    associationId = associations[0].Id;
                }

                response.proposal = [
                    SELECT Id, Project_Title__c, Outline_of_proposed_research__c, Keywords__c,
                           Significance_of_the_proposed_work__c, Research_References__c, Yearly_Scheme__c
                    FROM Proposal__c
                    WHERE Id = :proposal.Id
                    LIMIT 1
                ];
            }

            // ---- Publications__c processing ----
            if (req.publications != null && !req.publications.isEmpty()) {
                if (String.isBlank(associationId)) {
                    // No APA found/created to attach publications to - skip and flag it
                    response.publicationsMessage = 'Publications not processed: no Applicant Proposal Association could be resolved.';
                } else {
                    PublicationProcessResult result = processPublications(req.publications, req.contactId, associationId);
                    response.publicationsCreatedCount = result.createdCount;
                    response.publicationsUpdatedCount = result.updatedCount;
                    response.publicationsMessage = 'Publications processed successfully.';
                }
            }
        }
        catch (System.JSONException e) {
            Database.rollback(sp);
            response.success = false;
            response.message = 'Invalid request body.';
        }
        catch (Exception e) {
            Database.rollback(sp);
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    // Handles the 3-way branching for Publications__c described by the caller
    private static PublicationProcessResult processPublications(List<PublicationRequestWrapper> pubs, String contactId, String associationId) {
        List<Publications__c> toInsert = new List<Publications__c>();
        List<Publications__c> toUpdate = new List<Publications__c>();

        for (PublicationRequestWrapper item : pubs) {

            // Case 1: already belongs to this APA -> update in place
            if (String.isNotBlank(item.publicationId) && String.isNotBlank(item.apaId)) {
                Publications__c pubToUpdate = new Publications__c(Id = item.publicationId);
                applyFields(pubToUpdate, item);
                toUpdate.add(pubToUpdate);
                continue;
            }

            // Case 2: sourced from a contact-fallback record (older publication tied to Contact only)
            // -> create a new record scoped to this APA, leave the original contact record untouched
            if (String.isNotBlank(item.contactId) && String.isBlank(item.apaId)) {
                Publications__c apaCopy = new Publications__c();
                apaCopy.Applicant_Proposal_Association__c = associationId;
                applyFields(apaCopy, item);
                toInsert.add(apaCopy);
                continue;
            }

            // Case 3: brand new publication added by the user this session
            // -> create two mirrored records: one under the APA, one under the Contact
            Publications__c apaRecord = new Publications__c();
            apaRecord.Applicant_Proposal_Association__c = associationId;
            applyFields(apaRecord, item);
            toInsert.add(apaRecord);

            Publications__c contactRecord = new Publications__c();
            contactRecord.Contact__c = contactId;
            applyFields(contactRecord, item);
            toInsert.add(contactRecord);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        PublicationProcessResult result = new PublicationProcessResult();
        result.createdCount = toInsert.size();
        result.updatedCount = toUpdate.size();
        return result;
    }

    private static void applyFields(Publications__c pub, PublicationRequestWrapper item) {
        pub.Applicant_Role__c = item.applicantRole;
        pub.Author_Names__c = item.authorNames;
       // pub.CurrencyIsoCode = item.currencyPicklist;
        pub.Journal_Name__c = item.journalName;
        pub.Number_of_citations_at_present__c = item.numberOfCitationsAtPresent;
        pub.PMID_DOI_URL__c = item.pmidDoiUrl;
        pub.Sr_No__c = item.srNo;
        pub.Title__c = item.title;
    }

    global class RequestWrapper {
        public String proposalId;
        public String projectTitle;
        public String outlineOfProposedWord;
        public String keywords;
        public String signinficanceOfProposedWork;
        public String researchReferences;
        public String contactId;
        public String yearlySchemeId;
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
        public List<PublicationRequestWrapper> publications;
    }

    global class PublicationRequestWrapper {
        public String publicationId;
        public String apaId;
        public String contactId;
        public String applicantRole;
        public String authorNames;
      //  public String currencyPicklist;
        public String journalName;
        public Decimal numberOfCitationsAtPresent;
        public String pmidDoiUrl;
        public Decimal srNo;
        public String title;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Proposal__c proposal;
        public String proposalId;
        public String apaId;
        public Integer publicationsCreatedCount;
        public Integer publicationsUpdatedCount;
        public String publicationsMessage;
    }

    private class PublicationProcessResult {
        public Integer createdCount;
        public Integer updatedCount;
    }
}