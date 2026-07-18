/*@RestResource(urlMapping='/saveApplicantCVDetails')
global without sharing class saveApplicantCVDetailsAPI {

    @HttpPost
    global static ResponseWrapper saveApplicantCVDetails() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if(String.isBlank(req.proposalId) || String.isBlank(req.apaId) || String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required fields: proposalId, apaId and contactId are mandatory';
                return response;
            }

            Proposal__c updatedProposal = new Proposal__c(
                Id = req.proposalId,
                Title_of_Thesis_Dissertation__c = req.titleThesisDissertation,
                Research_Summary_During_Highest_Degree__c = req.researchSummaryDuringHigherDegree,
                Scientific_Meetings__c = req.scientificMeetings,
                Scientific_career_to_date__c = req.scientificCareerToDate
                // Have_you_identified_Sponsor_at_Host_Inst__c = req.haveYouIdentifiedSponserAtHostInstitution,
                // Sponsor_Name__c = req.nameOfSponser,
                // Sponsor_Designation__c = req.sponserDesignation,
                // Sponsor_Department__c = req.sponserDepartment,
                // Sponsor_Organisation__c = req.sponserOrganisation,
                // Have_you_identified_mentor_on_your_appli__c = req.haveYouIdentifiedMentorOnYourApplication,
                // Mentor_Name__c = req.nameOfMentor,
                // Mentor_Designation__c = req.mentorDesignation,
                // Mentor_Department__c = req.mentorDepartment,
                // Mentor_Organisation__c = req.mentorOrganisation,
                // Mentor_City__c = req.mentorCity,
                // Mentor_Country__c = req.mentorCountry,
                // What_guidance_do_you_expect_to_receive__c = req.guidanceReceivedFromMentorAndBenefits,  
                // If_identified_External_Sponsor_s_for_Wo__c = req.identifiedExternalSponserForWohiBreifDetails   
            );
            update updatedProposal;

            Integer educationInsertedCount = 0;
            Integer educationUpdatedCount = 0;
            Integer patentInsertedCount = 0;
            Integer patentUpdatedCount = 0;
            Integer employmentInsertedCount = 0;
            Integer employmentUpdatedCount = 0;

            if(req.educationDetails != null && !req.educationDetails.isEmpty()) {
                List<Education_Details__c> educationToInsertApa = new List<Education_Details__c>();
                List<Education_Details__c> educationToInsertContact = new List<Education_Details__c>();
                List<Education_Details__c> educationToUpdate = new List<Education_Details__c>();

                for(EducationDetailsWrapper education : req.educationDetails) {
                    if(String.isNotBlank(education.educationId)) {
                        Education_Details__c existingEducation = buildEducationRecord(education);
                        existingEducation.Id = education.educationId;
                        educationToUpdate.add(existingEducation);
                    } else {
                        // APA-tagged copy (Contact__c must stay null so trigger does not clone again)
                        Education_Details__c apaEducation = buildEducationRecord(education);
                        apaEducation.Applicant_Proposal_Association__c = req.apaId;
                        educationToInsertApa.add(apaEducation);

                        // Contact-tagged copy (APA must stay null)
                        Education_Details__c contactEducation = buildEducationRecord(education);
                        contactEducation.Contact__c = req.contactId;
                        educationToInsertContact.add(contactEducation);
                    }
                }

                // Bypass trigger sync so Contact insert does not clone a second APA record
                if(!educationToInsertApa.isEmpty() || !educationToInsertContact.isEmpty()) {
                    GenericApplicantAssociationHandler.bypassAssociationSync = true;
                    try {
                        if(!educationToInsertApa.isEmpty()) {
                            insert educationToInsertApa;
                            educationInsertedCount += educationToInsertApa.size();
                        }
                        if(!educationToInsertContact.isEmpty()) {
                            insert educationToInsertContact;
                            educationInsertedCount += educationToInsertContact.size();
                        }
                    } finally {
                        GenericApplicantAssociationHandler.bypassAssociationSync = false;
                    }
                }
                if(!educationToUpdate.isEmpty()) {
                    update educationToUpdate;
                    educationUpdatedCount = educationToUpdate.size();
                }
            }

            if(req.patentsDetails != null && !req.patentsDetails.isEmpty()) {
                List<Patents__c> patentsToInsertApa = new List<Patents__c>();
                List<Patents__c> patentsToInsertContact = new List<Patents__c>();
                List<Patents__c> patentsToUpdate = new List<Patents__c>();

                for(PatentsDetailsWrapper patent : req.patentsDetails) {
                    if(String.isNotBlank(patent.patentId)) {
                        Patents__c existingPatent = buildPatentRecord(patent);
                        existingPatent.Id = patent.patentId;
                        patentsToUpdate.add(existingPatent);
                    } else {
                        Patents__c apaPatent = buildPatentRecord(patent);
                        apaPatent.Applicant_Proposal_Association__c = req.apaId;
                        patentsToInsertApa.add(apaPatent);

                        Patents__c contactPatent = buildPatentRecord(patent);
                        contactPatent.Contact__c = req.contactId;
                        patentsToInsertContact.add(contactPatent);
                    }
                }

                if(!patentsToInsertApa.isEmpty() || !patentsToInsertContact.isEmpty()) {
                    GenericApplicantAssociationHandler.bypassAssociationSync = true;
                    try {
                        if(!patentsToInsertApa.isEmpty()) {
                            insert patentsToInsertApa;
                            patentInsertedCount += patentsToInsertApa.size();
                        }
                        if(!patentsToInsertContact.isEmpty()) {
                            insert patentsToInsertContact;
                            patentInsertedCount += patentsToInsertContact.size();
                        }
                    } finally {
                        GenericApplicantAssociationHandler.bypassAssociationSync = false;
                    }
                }
                if(!patentsToUpdate.isEmpty()) {
                    update patentsToUpdate;
                    patentUpdatedCount = patentsToUpdate.size();
                }
            }

            if(req.employmentDetails != null && !req.employmentDetails.isEmpty()) {
                List<Employment_Details__c> employmentToInsertApa = new List<Employment_Details__c>();
                List<Employment_Details__c> employmentToInsertContact = new List<Employment_Details__c>();
                List<Employment_Details__c> employmentToUpdate = new List<Employment_Details__c>();

                for(EmploymentDetailsWrapper employment : req.employmentDetails) {
                    if(String.isNotBlank(employment.employmentId)) {
                        Employment_Details__c existingEmployment = buildEmploymentRecord(employment);
                        existingEmployment.Id = employment.employmentId;
                        employmentToUpdate.add(existingEmployment);
                    } else {
                        Employment_Details__c apaEmployment = buildEmploymentRecord(employment);
                        apaEmployment.Applicant_Proposal_Association__c = req.apaId;
                        employmentToInsertApa.add(apaEmployment);

                        Employment_Details__c contactEmployment = buildEmploymentRecord(employment);
                        contactEmployment.Contact__c = req.contactId;
                        employmentToInsertContact.add(contactEmployment);
                    }
                }

                if(!employmentToInsertApa.isEmpty() || !employmentToInsertContact.isEmpty()) {
                    GenericApplicantAssociationHandler.bypassAssociationSync = true;
                    try {
                        if(!employmentToInsertApa.isEmpty()) {
                            insert employmentToInsertApa;
                            employmentInsertedCount += employmentToInsertApa.size();
                        }
                        if(!employmentToInsertContact.isEmpty()) {
                            insert employmentToInsertContact;
                            employmentInsertedCount += employmentToInsertContact.size();
                        }
                    } finally {
                        GenericApplicantAssociationHandler.bypassAssociationSync = false;
                    }
                }
                if(!employmentToUpdate.isEmpty()) {
                    update employmentToUpdate;
                    employmentUpdatedCount = employmentToUpdate.size();
                }
            }

            response.success = true;
            List<String> messages = new List<String>{ 'Proposal updated successfully' };
            if(educationInsertedCount > 0) {
                messages.add(educationInsertedCount + ' education record(s) inserted');
            }
            if(educationUpdatedCount > 0) {
                messages.add(educationUpdatedCount + ' education record(s) updated');
            }
            if(patentInsertedCount > 0) {
                messages.add(patentInsertedCount + ' patent record(s) inserted');
            }
            if(patentUpdatedCount > 0) {
                messages.add(patentUpdatedCount + ' patent record(s) updated');
            }
            if(employmentInsertedCount > 0) {
                messages.add(employmentInsertedCount + ' employment record(s) inserted');
            }
            if(employmentUpdatedCount > 0) {
                messages.add(employmentUpdatedCount + ' employment record(s) updated');
            }
            response.message = String.join(messages, '. ');
            response.proposalId = req.proposalId;
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    private static Education_Details__c buildEducationRecord(EducationDetailsWrapper education) {
        return new Education_Details__c(
            Start_Date__c = education.fromDate,
            End_Date__c = education.toDate,
            Qualification__c = education.qualification,
            Subject__c = education.subject,
            Country__c = education.institutionCountry,
            Institution__c = education.institution,
            Department_School_Division__c = education.department,
            Supervisor__c = education.supervisor,
            Pursuing_Higher_Degree__c = education.pursuingHigherDegree
        );
    }

    private static Patents__c buildPatentRecord(PatentsDetailsWrapper patent) {
        return new Patents__c(
            Title__c = patent.title,
            Inventors__c = patent.inventors,
            Patent_Number__c = patent.patentNumber,
            Granting_Agency_Country__c = patent.grantingAgencyCountry,
            Filing_Granted_Date__c = patent.filingGrantedDate
        );
    }

    private static Employment_Details__c buildEmploymentRecord(EmploymentDetailsWrapper employment) {
        return new Employment_Details__c(
            Organisation__c = employment.organisation,
            Position__c = employment.position,
            Roles_Responsibilities__c = employment.description,
            I_am_currently_working_here__c = employment.currentlyWorkingHere,
            Start_Date__c = employment.startDate,
            End_Date__c = employment.endDate,
            Reporting_To__c = employment.reportingTo
        );
    }

    global class RequestWrapper {
        public String proposalId;
        public String apaId;
        public String contactId;
        public String titleThesisDissertation;
        public String researchSummaryDuringHigherDegree;
        public String scientificMeetings;
        public String scientificCareerToDate;
        public List<EducationDetailsWrapper> educationDetails;
        public List<PatentsDetailsWrapper> patentsDetails;
        public List<EmploymentDetailsWrapper> employmentDetails;
        // public String haveYouIdentifiedSponserAtHostInstitution;
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
        // public string identifiedExternalSponserForWohiBreifDetails;
    }

    global class EducationDetailsWrapper {
        public String educationId;
        public Date fromDate;
        public Date toDate;
        public String qualification;
        public String subject;
        public String institutionCountry;
        public String institution;
        public String department;
        public String supervisor;
        public String pursuingHigherDegree;
    }

    global class PatentsDetailsWrapper {
        public String patentId;
        public String title;
        public String inventors;
        public String patentNumber;
        public String grantingAgencyCountry;
        public Date filingGrantedDate;
    }

    global class EmploymentDetailsWrapper {
        public String employmentId;
        public String organisation;
        public String position;
        public String description;
        public Boolean currentlyWorkingHere;
        public Date startDate;
        public Date endDate;
        public String reportingTo;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Id proposalId;
    }
}*/


@RestResource(urlMapping='/saveApplicantCVDetails')
global without sharing class saveApplicantCVDetailsAPI {

    @HttpPost
    global static ResponseWrapper saveApplicantCVDetails() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if(String.isBlank(req.proposalId) || String.isBlank(req.apaId) || String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required fields: proposalId, apaId and contactId are mandatory';
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

            Integer educationInsertedCount = 0;
            Integer educationUpdatedCount = 0;
            Integer patentInsertedCount = 0;
            Integer patentUpdatedCount = 0;
            Integer employmentInsertedCount = 0;
            Integer employmentUpdatedCount = 0;

            if(req.educationDetails != null && !req.educationDetails.isEmpty()) {
                List<Education_Details__c> educationToInsertApa = new List<Education_Details__c>();
                List<Education_Details__c> educationToInsertContact = new List<Education_Details__c>();
                List<Education_Details__c> educationToUpdate = new List<Education_Details__c>();

                // for(EducationDetailsWrapper education : req.educationDetails) {
                //     if(String.isNotBlank(education.educationId)) {
                //         // UPDATE path — reassert APA scope so a stray Contact-master Id
                //         // can never silently overwrite the shared master record without
                //         // at least becoming visibly re-scoped.
                //         Education_Details__c existingEducation = buildEducationRecord(education);
                //         existingEducation.Id = education.educationId;
                //         existingEducation.Applicant_Proposal_Association__c = req.apaId;
                //         educationToUpdate.add(existingEducation);
                //     } else {
                //         // APA-tagged copy (Contact__c must stay null so trigger does not clone again)
                //         Education_Details__c apaEducation = buildEducationRecord(education);
                //         apaEducation.Applicant_Proposal_Association__c = req.apaId;
                //         educationToInsertApa.add(apaEducation);

                //         // Contact-tagged copy (APA must stay null)
                //         Education_Details__c contactEducation = buildEducationRecord(education);
                //         contactEducation.Contact__c = req.contactId;
                //         educationToInsertContact.add(contactEducation);
                //     }
                // }
                for(EducationDetailsWrapper education : req.educationDetails) {

                if(String.isNotBlank(education.educationId)) {

                    // Existing APA record -> UPDATE
                    if(String.isNotBlank(education.apaId)) {

                        Education_Details__c existingEducation = buildEducationRecord(education);
                        existingEducation.Id = education.educationId;
                        existingEducation.Applicant_Proposal_Association__c = education.apaId;
                        educationToUpdate.add(existingEducation);

                    }
                    // Existing Contact record -> DON'T UPDATE, CREATE APA RECORD
                    else if(String.isNotBlank(education.contactId)) {

                        Education_Details__c apaEducation = buildEducationRecord(education);
                        apaEducation.Applicant_Proposal_Association__c = req.apaId;
                        educationToInsertApa.add(apaEducation);

                    }

                } else {

                    // New record

                    Education_Details__c apaEducation = buildEducationRecord(education);
                    apaEducation.Applicant_Proposal_Association__c = req.apaId;
                    educationToInsertApa.add(apaEducation);

                    Education_Details__c contactEducation = buildEducationRecord(education);
                    contactEducation.Contact__c = req.contactId;
                    educationToInsertContact.add(contactEducation);
                }
            }

                // Bypass trigger sync so Contact insert does not clone a second APA record
                if(!educationToInsertApa.isEmpty() || !educationToInsertContact.isEmpty()) {
                    GenericApplicantAssociationHandler.bypassAssociationSync = true;
                    try {
                        if(!educationToInsertApa.isEmpty()) {
                            insert educationToInsertApa;
                            educationInsertedCount += educationToInsertApa.size();
                        }
                        if(!educationToInsertContact.isEmpty()) {
                            insert educationToInsertContact;
                            educationInsertedCount += educationToInsertContact.size();
                        }
                    } finally {
                        GenericApplicantAssociationHandler.bypassAssociationSync = false;
                    }
                }
                if(!educationToUpdate.isEmpty()) {
                    update educationToUpdate;
                    educationUpdatedCount = educationToUpdate.size();
                }
            }

            if(req.patentsDetails != null && !req.patentsDetails.isEmpty()) {
                List<Patents__c> patentsToInsertApa = new List<Patents__c>();
                List<Patents__c> patentsToInsertContact = new List<Patents__c>();
                List<Patents__c> patentsToUpdate = new List<Patents__c>();

                // for(PatentsDetailsWrapper patent : req.patentsDetails) {
                //     if(String.isNotBlank(patent.patentId)) {
                //         Patents__c existingPatent = buildPatentRecord(patent);
                //         existingPatent.Id = patent.patentId;
                //         existingPatent.Applicant_Proposal_Association__c = req.apaId;
                //         patentsToUpdate.add(existingPatent);
                //     } else {
                //         Patents__c apaPatent = buildPatentRecord(patent);
                //         apaPatent.Applicant_Proposal_Association__c = req.apaId;
                //         patentsToInsertApa.add(apaPatent);

                //         Patents__c contactPatent = buildPatentRecord(patent);
                //         contactPatent.Contact__c = req.contactId;
                //         patentsToInsertContact.add(contactPatent);
                //     }
                // }
                for(PatentsDetailsWrapper patent : req.patentsDetails) {

                    if(String.isNotBlank(patent.patentId)) {

                        // Existing APA record -> UPDATE
                        if(String.isNotBlank(patent.apaId)) {

                            Patents__c existingPatent = buildPatentRecord(patent);
                            existingPatent.Id = patent.patentId;
                            existingPatent.Applicant_Proposal_Association__c = patent.apaId;
                            patentsToUpdate.add(existingPatent);

                        }
                        // Existing Contact record -> DON'T UPDATE
                        else if(String.isNotBlank(patent.contactId)) {

                            Patents__c apaPatent = buildPatentRecord(patent);
                            apaPatent.Applicant_Proposal_Association__c = req.apaId;
                            patentsToInsertApa.add(apaPatent);

                        }

                    } else {

                        Patents__c apaPatent = buildPatentRecord(patent);
                        apaPatent.Applicant_Proposal_Association__c = req.apaId;
                        patentsToInsertApa.add(apaPatent);

                        Patents__c contactPatent = buildPatentRecord(patent);
                        contactPatent.Contact__c = req.contactId;
                        patentsToInsertContact.add(contactPatent);
                    }
                }

                if(!patentsToInsertApa.isEmpty() || !patentsToInsertContact.isEmpty()) {
                    GenericApplicantAssociationHandler.bypassAssociationSync = true;
                    try {
                        if(!patentsToInsertApa.isEmpty()) {
                            insert patentsToInsertApa;
                            patentInsertedCount += patentsToInsertApa.size();
                        }
                        if(!patentsToInsertContact.isEmpty()) {
                            insert patentsToInsertContact;
                            patentInsertedCount += patentsToInsertContact.size();
                        }
                    } finally {
                        GenericApplicantAssociationHandler.bypassAssociationSync = false;
                    }
                }
                if(!patentsToUpdate.isEmpty()) {
                    update patentsToUpdate;
                    patentUpdatedCount = patentsToUpdate.size();
                }
            }

            if(req.employmentDetails != null && !req.employmentDetails.isEmpty()) {
                List<Employment_Details__c> employmentToInsertApa = new List<Employment_Details__c>();
                List<Employment_Details__c> employmentToInsertContact = new List<Employment_Details__c>();
                List<Employment_Details__c> employmentToUpdate = new List<Employment_Details__c>();

                // for(EmploymentDetailsWrapper employment : req.employmentDetails) {
                //     if(String.isNotBlank(employment.employmentId)) {
                //         Employment_Details__c existingEmployment = buildEmploymentRecord(employment);
                //         existingEmployment.Id = employment.employmentId;
                //         existingEmployment.Applicant_Proposal_Association__c = req.apaId;
                //         employmentToUpdate.add(existingEmployment);
                //     } else {
                //         Employment_Details__c apaEmployment = buildEmploymentRecord(employment);
                //         apaEmployment.Applicant_Proposal_Association__c = req.apaId;
                //         employmentToInsertApa.add(apaEmployment);

                //         Employment_Details__c contactEmployment = buildEmploymentRecord(employment);
                //         contactEmployment.Contact__c = req.contactId;
                //         employmentToInsertContact.add(contactEmployment);
                //     }
                // }
                for(EmploymentDetailsWrapper employment : req.employmentDetails) {

                if(String.isNotBlank(employment.employmentId)) {

                    // Existing APA record -> UPDATE
                    if(String.isNotBlank(employment.apaId)) {

                        Employment_Details__c existingEmployment = buildEmploymentRecord(employment);
                        existingEmployment.Id = employment.employmentId;
                        existingEmployment.Applicant_Proposal_Association__c = employment.apaId;
                        employmentToUpdate.add(existingEmployment);

                    }
                    // Existing Contact record -> DON'T UPDATE
                    else if(String.isNotBlank(employment.contactId)) {

                        Employment_Details__c apaEmployment = buildEmploymentRecord(employment);
                        apaEmployment.Applicant_Proposal_Association__c = req.apaId;
                        employmentToInsertApa.add(apaEmployment);

                    }

                } else {

                    Employment_Details__c apaEmployment = buildEmploymentRecord(employment);
                    apaEmployment.Applicant_Proposal_Association__c = req.apaId;
                    employmentToInsertApa.add(apaEmployment);

                    Employment_Details__c contactEmployment = buildEmploymentRecord(employment);
                    contactEmployment.Contact__c = req.contactId;
                    employmentToInsertContact.add(contactEmployment);
                }
            }

                if(!employmentToInsertApa.isEmpty() || !employmentToInsertContact.isEmpty()) {
                    GenericApplicantAssociationHandler.bypassAssociationSync = true;
                    try {
                        if(!employmentToInsertApa.isEmpty()) {
                            insert employmentToInsertApa;
                            employmentInsertedCount += employmentToInsertApa.size();
                        }
                        if(!employmentToInsertContact.isEmpty()) {
                            insert employmentToInsertContact;
                            employmentInsertedCount += employmentToInsertContact.size();
                        }
                    } finally {
                        GenericApplicantAssociationHandler.bypassAssociationSync = false;
                    }
                }
                if(!employmentToUpdate.isEmpty()) {
                    update employmentToUpdate;
                    employmentUpdatedCount = employmentToUpdate.size();
                }
            }

            response.success = true;
            List<String> messages = new List<String>{ 'Proposal updated successfully' };
            if(educationInsertedCount > 0) {
                messages.add(educationInsertedCount + ' education record(s) inserted');
            }
            if(educationUpdatedCount > 0) {
                messages.add(educationUpdatedCount + ' education record(s) updated');
            }
            if(patentInsertedCount > 0) {
                messages.add(patentInsertedCount + ' patent record(s) inserted');
            }
            if(patentUpdatedCount > 0) {
                messages.add(patentUpdatedCount + ' patent record(s) updated');
            }
            if(employmentInsertedCount > 0) {
                messages.add(employmentInsertedCount + ' employment record(s) inserted');
            }
            if(employmentUpdatedCount > 0) {
                messages.add(employmentUpdatedCount + ' employment record(s) updated');
            }
            response.message = String.join(messages, '. ');
            response.proposalId = req.proposalId;
        }
        catch (Exception e) {
            response.success = false;
            response.message = e.getMessage();
        }
        return response;
    }

    private static Education_Details__c buildEducationRecord(EducationDetailsWrapper education) {
        return new Education_Details__c(
            Start_Date__c = education.startDate,
            End_Date__c = education.endDate,
            Qualification__c = education.qualification,
            Subject__c = education.subject,
            Country__c = education.country,
            Institution__c = education.institution,
            Department_School_Division__c = education.department,
            Supervisor__c = education.supervisor,
            Title_of_thesis_Dissertation__c = education.thesisDissertationTitle,
            Pursuing_Higher_Degree__c = education.pursuingHigherDegree
        );
    }

    private static Patents__c buildPatentRecord(PatentsDetailsWrapper patent) {
        return new Patents__c(
            Title__c = patent.title,
            Inventors__c = patent.inventors,
            Patent_Number__c = patent.patentNumber,
            Granting_Agency_Country__c = patent.grantingAgencyCountry,
            Filing_Granted_Date__c = patent.filingGrantedDate
        );
    }

    private static Employment_Details__c buildEmploymentRecord(EmploymentDetailsWrapper employment) {
        return new Employment_Details__c(
            Organisation__c = employment.organisation,
            Position__c = employment.position,
            Roles_Responsibilities__c = employment.description,
            I_am_currently_working_here__c = employment.currentlyWorkingHere == null ? false : employment.currentlyWorkingHere,
            Start_Date__c = employment.startDate,
            End_Date__c = employment.endDate,
            Reporting_To__c = employment.reportingTo
        );
    }

    global class RequestWrapper {
        public String proposalId;
        public String apaId;
        public String contactId;
        public String titleThesisDissertation;
        public String researchSummaryDuringHigherDegree;
        public String scientificMeetings;
        public String scientificCareerToDate;
        public List<EducationDetailsWrapper> educationDetails;
        public List<PatentsDetailsWrapper> patentsDetails;
        public List<EmploymentDetailsWrapper> employmentDetails;
    }

    global class EducationDetailsWrapper {
        public String educationId;
        public String contactId;
        public String apaId;
        public Date startDate;
        public Date endDate;
        public String qualification;
        public String subject;
        public String country;
        public String institution;
        public String department;
        public String supervisor;
        public String thesisDissertationTitle;
        public String pursuingHigherDegree;
    }

    global class PatentsDetailsWrapper {
        public String patentId;
        public String contactId;
        public String apaId;
        public String title;
        public String inventors;
        public String patentNumber;
        public String grantingAgencyCountry;
        public Date filingGrantedDate;
    }

    global class EmploymentDetailsWrapper {
        public String employmentId;
        public String contactId;
        public String apaId;
        public String organisation;
        public String position;
        public String description;
        public Boolean currentlyWorkingHere;
        public Date startDate;
        public Date endDate;
        public String reportingTo;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Id proposalId;
    }
}