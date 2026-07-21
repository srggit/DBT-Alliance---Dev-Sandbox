/*@RestResource(urlMapping='/getApplicantCVDetailsP3')
global without sharing class getApplicantCVDetailsP3 {

    @HttpGet
    global static ResponseWrapper getApplicantCVDetailsP3(){

        RestRequest req = RestContext.request;
        String proposalId = req.params.get('proposalId');
        String apaId = req.params.get('apaId');
        String contactId = req.params.get('contactId');

        System.debug('proposalId: ' + proposalId);
        System.debug('apaId: ' + apaId);
        System.debug('contactId: ' + contactId);


        ResponseWrapper response = new ResponseWrapper();
        ProposalWrapper proposalWrapper = new ProposalWrapper();
        List<EducationDetailsWrapper> educationDetailsWrapperList = new List<EducationDetailsWrapper>();
        List<PatentsDetailsWrapper> patentsDetailsWrapperList = new List<PatentsDetailsWrapper>();
        List<EmploymentDetailsWrapper> employmentDetailsWrapperList = new List<EmploymentDetailsWrapper>();

        try{

            Proposal__c proposal;
            List<Education_Details__c> educationRecords = new List<Education_Details__c>();
            List<Patents__c> patentRecords = new List<Patents__c>();
            List<Employment_Details__c> employmentRecords = new List<Employment_Details__c>();

            // Prefer apaId: Proposal + Education + Patents in one query via APA
            if(String.isNotBlank(apaId)){
                List<Applicant_Proposal_Association__c> apaRecords = [
                    SELECT Id, Contact__c, Proposal__c,
                        Proposal__r.Id,
                        Proposal__r.Title_of_Thesis_Dissertation__c,
                        Proposal__r.Research_Summary_During_Highest_Degree__c,
                        Proposal__r.Scientific_Meetings__c,
                        Proposal__r.Scientific_career_to_date__c,
                        Proposal__r.Have_you_identified_Sponsor_at_Host_Inst__c, Proposal__r.Sponsor_Name__c,Proposal__r.Sponsor_Designation__c, Proposal__r.Sponsor_Department__c,Proposal__r.Sponsor_Organisation__c, Proposal__r.Have_you_identified_mentor_on_your_appli__c,
                        Proposal__r.Mentor_Name__c, Proposal__r.Mentor_Designation__c, Proposal__r.Mentor_Department__c, Proposal__r.Mentor_Organisation__c, Proposal__r.Mentor_City__c, Proposal__r.Mentor_Country__c, Proposal__r.What_guidance_do_you_expect_to_receive__c, Proposal__r.If_identified_External_Sponsor_s_for_Wo__c,
                        (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c,
                            Department_School_Division__c, Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, Pursuing_Higher_Degree__c, Start_Date__c
                         FROM Education_Details__r
                         ORDER BY End_Date__c DESC),
                        (SELECT Id, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c
                         FROM Patents__r
                         ORDER BY Name ASC),
                         (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c, I_am_currently_working_here__c, End_Date__c, Start_Date__c, Reporting_To__c FROM Employment_Details__r ORDER BY End_Date__c DESC)
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :apaId
                    LIMIT 1
                ];

                if(apaRecords.isEmpty()){
                    response.success = false;
                    response.message = 'Applicant Proposal Association not found';
                    return response;
                }
                System.debug('apaRecords: ' + apaRecords);

                Applicant_Proposal_Association__c apa = apaRecords[0];
                if(apa.Proposal__c == null){
                    response.success = false;
                    response.message = 'Proposal not found for the given APA';
                    return response;
                }
                System.debug('apa: ' + apa);
                proposal = apa.Proposal__r;
                educationRecords = apa.Education_Details__r;
                patentRecords = apa.Patents__r;
                employmentRecords = apa.Employment_Details__r;

                System.debug('educationRecords: ' + educationRecords);
                System.debug('patentRecords: ' + patentRecords);
                System.debug('employmentRecords: ' + employmentRecords);
                System.debug('educationRecords.isEmpty(): ' + educationRecords.isEmpty());
                System.debug('patentRecords.isEmpty(): ' + patentRecords.isEmpty());

                // If APA has no education/patents/employment, fall back to Contact
                if(educationRecords.isEmpty() || patentRecords.isEmpty() || employmentRecords.isEmpty()){
                    System.debug('educationRecords is empty or patentRecords is empty or employmentRecords is empty');

                    String fallbackContactId;

                    System.debug('Coming here');

                    fallbackContactId = String.isNotBlank(String.valueOf(apa.Contact__c)) ? String.valueOf(apa.Contact__c) : String.valueOf(contactId);
                    System.debug('fallbackContactId: ' + fallbackContactId);

                    if(String.isNotBlank(fallbackContactId)){
                        Contact contactWithCv = getContactEducationAndPatents(fallbackContactId);
                        if(contactWithCv != null){
                            if(educationRecords.isEmpty()){
                                educationRecords = contactWithCv.Education_Details__r;
                            }
                            if(patentRecords.isEmpty()){
                                patentRecords = contactWithCv.Patents__r;
                            }
                            if(employmentRecords.isEmpty()){
                                employmentRecords = contactWithCv.Employment_Details__r;
                            }
                        }
                    }
                    else{
                        response.success = false;
                        response.message = 'Contact ID is required when apaId is not provided';
                        return response;
                    }
                }
            }
            // Fallback: apaId blank — query Proposal; education/patents from Contact if contactId present
            else {
                System.debug('apaId is blank');
                System.debug('proposalId: ' + proposalId);
                System.debug('contactId: ' + contactId);

                if(String.isBlank(proposalId)){
                    response.success = false;
                    response.message = 'Proposal ID is required when apaId is not provided';
                    return response;
                }

                System.debug('proposalId: ' + proposalId);

                List<Proposal__c> proposals = [
                    SELECT Id, Research_Summary_During_Highest_Degree__c,
                        Scientific_Meetings__c, Scientific_career_to_date__c, Title_of_Thesis_Dissertation__c, Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c, Sponsor_Department__c,Sponsor_Organisation__c, Have_you_identified_mentor_on_your_appli__c,
                        Mentor_Name__c, Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
                    FROM Proposal__c
                    WHERE Id = :proposalId
                    LIMIT 1
                ];

                if(proposals.isEmpty()){
                    response.success = false;
                    response.message = 'Proposal not found';
                    return response;
                }
                System.debug('proposals: ' + proposals);
                proposal = proposals[0];

                if(String.isNotBlank(contactId)){
                    System.debug('contactId: ' + contactId);
                    Contact contactWithCv = getContactEducationAndPatents(contactId);
                    if(contactWithCv != null){
                        educationRecords = contactWithCv.Education_Details__r;
                        patentRecords = contactWithCv.Patents__r;
                        employmentRecords = contactWithCv.Employment_Details__r;
                    }
                }
            }

            for(Education_Details__c educationDetail : educationRecords){
                EducationDetailsWrapper educationDetailsWrapper = new EducationDetailsWrapper();
                educationDetailsWrapper.educationId = educationDetail.Id;
                educationDetailsWrapper.qualification = educationDetail.Qualification__c;
                educationDetailsWrapper.subject = educationDetail.Subject__c;
                educationDetailsWrapper.country = educationDetail.Country__c;
                educationDetailsWrapper.institution = educationDetail.Institution__c;
                educationDetailsWrapper.department = educationDetail.Department_School_Division__c;
                educationDetailsWrapper.supervisor = educationDetail.Supervisor__c;
                educationDetailsWrapper.thesisDissertationTitle = educationDetail.Title_of_thesis_Dissertation__c;
                educationDetailsWrapper.endDate = educationDetail.End_Date__c;
                educationDetailsWrapper.pursuingHigherDegree = educationDetail.Pursuing_Higher_Degree__c;
                educationDetailsWrapper.startDate = educationDetail.Start_Date__c;
                educationDetailsWrapperList.add(educationDetailsWrapper);
            }

            for(Patents__c patent : patentRecords){
                PatentsDetailsWrapper patentsDetailsWrapper = new PatentsDetailsWrapper();
                patentsDetailsWrapper.patentId = patent.Id;
                patentsDetailsWrapper.title = patent.Title__c;
                patentsDetailsWrapper.inventors = patent.Inventors__c;
                patentsDetailsWrapper.patentNumber = patent.Patent_Number__c;
                patentsDetailsWrapper.grantingAgencyCountry = patent.Granting_Agency_Country__c;
                patentsDetailsWrapper.filingGrantedDate = patent.Filing_Granted_Date__c;
                patentsDetailsWrapperList.add(patentsDetailsWrapper);
            }

            for(Employment_Details__c employmentDetail : employmentRecords){
                EmploymentDetailsWrapper employmentDetailsWrapper = new EmploymentDetailsWrapper();
                employmentDetailsWrapper.employmentId = employmentDetail.Id;
                employmentDetailsWrapper.organisation = employmentDetail.Organisation__c;
                employmentDetailsWrapper.position = employmentDetail.Position__c;
                employmentDetailsWrapper.description = employmentDetail.Roles_Responsibilities__c;
                employmentDetailsWrapper.isCurrentlyWorking = employmentDetail.I_am_currently_working_here__c;
                employmentDetailsWrapper.endDate = employmentDetail.End_Date__c;
                employmentDetailsWrapper.startDate = employmentDetail.Start_Date__c;
                employmentDetailsWrapper.reportingTo = employmentDetail.Reporting_To__c;
                employmentDetailsWrapperList.add(employmentDetailsWrapper);
            }

            proposalWrapper.proposalId = proposal.Id;
            proposalWrapper.titleOfThesisDissertation = proposal.Title_of_Thesis_Dissertation__c;
            proposalWrapper.researchSummaryDuringHighestDegree = proposal.Research_Summary_During_Highest_Degree__c;
            proposalWrapper.scientificMeetings = proposal.Scientific_Meetings__c;
            proposalWrapper.scientificCareerToDate = proposal.Scientific_career_to_date__c;
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


            response.proposalDetails = proposalWrapper;
            response.educationDetailsList = educationDetailsWrapperList;
            response.patentsDetailsList = patentsDetailsWrapperList;
            response.employmentDetailsList = employmentDetailsWrapperList;
            response.success = true;
            response.message = 'Proposal details fetched successfully';
            return response;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            return response;
        }
    }

    private static Contact getContactEducationAndPatents(String contactId){
        List<Contact> contacts = [
            SELECT Id,
                (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c,
                    Department_School_Division__c, Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, Pursuing_Higher_Degree__c, Start_Date__c
                 FROM Education_Details__r
                 ORDER BY End_Date__c DESC),
                (SELECT Id, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c
                 FROM Patents__r
                 ORDER BY Name ASC),
                 (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c, I_am_currently_working_here__c, End_Date__c, Start_Date__c, Reporting_To__c FROM Employment_Details__r ORDER BY End_Date__c DESC)
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public ProposalWrapper proposalDetails;
        public List<EducationDetailsWrapper> educationDetailsList;
        public List<PatentsDetailsWrapper> patentsDetailsList;
        public List<EmploymentDetailsWrapper> employmentDetailsList;
    }

    global class ProposalWrapper {
        public String proposalId;
        public String titleOfThesisDissertation;
        public String researchSummaryDuringHighestDegree;
        public String scientificMeetings;
        public String scientificCareerToDate;
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

    global class EducationDetailsWrapper {
        public String educationId;
        public String qualification;
        public String subject;
        public String country;
        public String institution;
        public String department;
        public String supervisor;
        public String thesisDissertationTitle;
        public String pursuingHigherDegree;
        public Date endDate;
        public Date startDate;
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
        public Boolean isCurrentlyWorking;
        public Date endDate;
        public Date startDate;
        public String reportingTo;
    }

}*/

/*
@RestResource(urlMapping='/getApplicantCVDetailsP3')
global without sharing class getApplicantCVDetailsP3 {

    @HttpGet
    global static ResponseWrapper getApplicantCVDetailsP3(){

        RestRequest req = RestContext.request;
        String proposalId = req.params.get('proposalId');
        String apaId = req.params.get('apaId');
        String contactId = req.params.get('contactId');

        System.debug('proposalId: ' + proposalId);
        System.debug('apaId: ' + apaId);
        System.debug('contactId: ' + contactId);


        ResponseWrapper response = new ResponseWrapper();
        ProposalWrapper proposalWrapper = new ProposalWrapper();
        List<EducationDetailsWrapper> educationDetailsWrapperList = new List<EducationDetailsWrapper>();
        List<PatentsDetailsWrapper> patentsDetailsWrapperList = new List<PatentsDetailsWrapper>();
        List<EmploymentDetailsWrapper> employmentDetailsWrapperList = new List<EmploymentDetailsWrapper>();

        // NEW: flags to track whether each list was sourced from the Contact master
        // rather than being genuinely scoped to this APA/proposal
        Boolean educationFromContact = false;
        Boolean patentFromContact = false;
        Boolean employmentFromContact = false;

        try{

            Proposal__c proposal;
            List<Education_Details__c> educationRecords = new List<Education_Details__c>();
            List<Patents__c> patentRecords = new List<Patents__c>();
            List<Employment_Details__c> employmentRecords = new List<Employment_Details__c>();

            Applicant_Proposal_Association__c apa;
            // Prefer apaId: Proposal + Education + Patents in one query via APA
            if(String.isNotBlank(apaId)){
                List<Applicant_Proposal_Association__c> apaRecords = [
                    SELECT Id, Contact__c, Proposal__c,
                        Contact__r.Google_Scholar_Profile__c,
                        Contact__r.ORCID_ID__c,
                        Proposal__r.Id,
                        Proposal__r.Title_of_Thesis_Dissertation__c,
                        Proposal__r.Research_Summary_During_Highest_Degree__c,
                        Proposal__r.Scientific_Meetings__c,
                        Proposal__r.Scientific_career_to_date__c,
                        Proposal__r.Have_you_identified_Sponsor_at_Host_Inst__c, Proposal__r.Sponsor_Name__c,Proposal__r.Sponsor_Designation__c, Proposal__r.Sponsor_Department__c,Proposal__r.Sponsor_Organisation__c, Proposal__r.Have_you_identified_mentor_on_your_appli__c,
                        Proposal__r.Mentor_Name__c, Proposal__r.Mentor_Designation__c, Proposal__r.Mentor_Department__c, Proposal__r.Mentor_Organisation__c, Proposal__r.Mentor_City__c, Proposal__r.Mentor_Country__c, Proposal__r.What_guidance_do_you_expect_to_receive__c, Proposal__r.If_identified_External_Sponsor_s_for_Wo__c,
                        (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c,
                            Department_School_Division__c, Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, Pursuing_Higher_Degree__c, Start_Date__c
                         FROM Education_Details__r
                         ORDER BY End_Date__c DESC),
                        (SELECT Id, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c
                         FROM Patents__r
                         ORDER BY Name ASC),
                         (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c, I_am_currently_working_here__c, End_Date__c, Start_Date__c, Reporting_To__c FROM Employment_Details__r ORDER BY End_Date__c DESC)
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :apaId
                    LIMIT 1
                ];

                if(apaRecords.isEmpty()){
                    response.success = false;
                    response.message = 'Applicant Proposal Association not found';
                    return response;
                }
                System.debug('apaRecords: ' + apaRecords);

                apa = apaRecords[0];
                
                if(apa.Proposal__c == null){
                    response.success = false;
                    response.message = 'Proposal not found for the given APA';
                    return response;
                }
                System.debug('apa: ' + apa);
                proposal = apa.Proposal__r;
                educationRecords = apa.Education_Details__r;
                patentRecords = apa.Patents__r;
                employmentRecords = apa.Employment_Details__r;

                System.debug('educationRecords: ' + educationRecords);
                System.debug('patentRecords: ' + patentRecords);
                System.debug('employmentRecords: ' + employmentRecords);
                System.debug('educationRecords.isEmpty(): ' + educationRecords.isEmpty());
                System.debug('patentRecords.isEmpty(): ' + patentRecords.isEmpty());

                // If APA has no education/patents/employment, fall back to Contact
                if(educationRecords.isEmpty() || patentRecords.isEmpty() || employmentRecords.isEmpty()){
                    System.debug('educationRecords is empty or patentRecords is empty or employmentRecords is empty');

                    String fallbackContactId;

                    System.debug('Coming here');

                    fallbackContactId = String.isNotBlank(String.valueOf(apa.Contact__c)) ? String.valueOf(apa.Contact__c) : String.valueOf(contactId);
                    System.debug('fallbackContactId: ' + fallbackContactId);

                    if(String.isNotBlank(fallbackContactId)){
                        Contact contactWithCv = getContactEducationAndPatents(fallbackContactId);
                        if(contactWithCv != null){
                            if(educationRecords.isEmpty()){
                                educationRecords = contactWithCv.Education_Details__r;
                                educationFromContact = true; // NEW
                            }
                            if(patentRecords.isEmpty()){
                                patentRecords = contactWithCv.Patents__r;
                                patentFromContact = true; // NEW
                            }
                            if(employmentRecords.isEmpty()){
                                employmentRecords = contactWithCv.Employment_Details__r;
                                employmentFromContact = true; // NEW
                            }
                        }
                    }
                    else{
                        response.success = false;
                        response.message = 'Contact ID is required when apaId is not provided';
                        return response;
                    }
                }
            }
            // Fallback: apaId blank — query Proposal; education/patents from Contact if contactId present
            else {
                System.debug('apaId is blank');
                System.debug('proposalId: ' + proposalId);
                System.debug('contactId: ' + contactId);

                if(String.isBlank(proposalId)){
                    response.success = false;
                    response.message = 'Proposal ID is required when apaId is not provided';
                    return response;
                }

                System.debug('proposalId: ' + proposalId);

                List<Proposal__c> proposals = [
                    SELECT Id, Research_Summary_During_Highest_Degree__c,
                        Scientific_Meetings__c, Scientific_career_to_date__c, Title_of_Thesis_Dissertation__c, Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c, Sponsor_Department__c,Sponsor_Organisation__c, Have_you_identified_mentor_on_your_appli__c,
                        Mentor_Name__c, Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
                    FROM Proposal__c
                    WHERE Id = :proposalId
                    LIMIT 1
                ];

                if(proposals.isEmpty()){
                    response.success = false;
                    response.message = 'Proposal not found';
                    return response;
                }
                System.debug('proposals: ' + proposals);
                proposal = proposals[0];

                if(String.isNotBlank(contactId)){
                    System.debug('contactId: ' + contactId);
                    Contact contactWithCv = getContactEducationAndPatents(contactId);
                    if(contactWithCv != null){
                        educationRecords = contactWithCv.Education_Details__r;
                        patentRecords = contactWithCv.Patents__r;
                        employmentRecords = contactWithCv.Employment_Details__r;
                        // NEW: this whole branch has no APA yet, so everything here
                        // is by definition sourced from the Contact master
                        educationFromContact = !educationRecords.isEmpty();
                        patentFromContact = !patentRecords.isEmpty();
                        employmentFromContact = !employmentRecords.isEmpty();
                    }
                }
            }

            for(Education_Details__c educationDetail : educationRecords){
                EducationDetailsWrapper educationDetailsWrapper = new EducationDetailsWrapper();
                educationDetailsWrapper.educationId = educationDetail.Id;
                educationDetailsWrapper.qualification = educationDetail.Qualification__c;
                educationDetailsWrapper.subject = educationDetail.Subject__c;
                educationDetailsWrapper.country = educationDetail.Country__c;
                educationDetailsWrapper.institution = educationDetail.Institution__c;
                educationDetailsWrapper.department = educationDetail.Department_School_Division__c;
                educationDetailsWrapper.supervisor = educationDetail.Supervisor__c;
                educationDetailsWrapper.thesisDissertationTitle = educationDetail.Title_of_thesis_Dissertation__c;
                educationDetailsWrapper.endDate = educationDetail.End_Date__c;
                educationDetailsWrapper.pursuingHigherDegree = educationDetail.Pursuing_Higher_Degree__c;
                educationDetailsWrapper.startDate = educationDetail.Start_Date__c;
                educationDetailsWrapper.sourcedFromContact = educationFromContact; // NEW
                educationDetailsWrapperList.add(educationDetailsWrapper);
            }

            for(Patents__c patent : patentRecords){
                PatentsDetailsWrapper patentsDetailsWrapper = new PatentsDetailsWrapper();
                patentsDetailsWrapper.patentId = patent.Id;
                patentsDetailsWrapper.title = patent.Title__c;
                patentsDetailsWrapper.inventors = patent.Inventors__c;
                patentsDetailsWrapper.patentNumber = patent.Patent_Number__c;
                patentsDetailsWrapper.grantingAgencyCountry = patent.Granting_Agency_Country__c;
                patentsDetailsWrapper.filingGrantedDate = patent.Filing_Granted_Date__c;
                patentsDetailsWrapper.sourcedFromContact = patentFromContact; // NEW
                patentsDetailsWrapperList.add(patentsDetailsWrapper);
            }

            for(Employment_Details__c employmentDetail : employmentRecords){
                EmploymentDetailsWrapper employmentDetailsWrapper = new EmploymentDetailsWrapper();
                employmentDetailsWrapper.employmentId = employmentDetail.Id;
                employmentDetailsWrapper.organisation = employmentDetail.Organisation__c;
                employmentDetailsWrapper.position = employmentDetail.Position__c;
                employmentDetailsWrapper.description = employmentDetail.Roles_Responsibilities__c;
                employmentDetailsWrapper.isCurrentlyWorking = employmentDetail.I_am_currently_working_here__c;
                employmentDetailsWrapper.endDate = employmentDetail.End_Date__c;
                employmentDetailsWrapper.startDate = employmentDetail.Start_Date__c;
                employmentDetailsWrapper.reportingTo = employmentDetail.Reporting_To__c;
                employmentDetailsWrapper.sourcedFromContact = employmentFromContact; // NEW
                employmentDetailsWrapperList.add(employmentDetailsWrapper);
            }

            proposalWrapper.proposalId = proposal.Id;
            proposalWrapper.googleScholarProfileLink = apa.Contact__r.Google_Scholar_Profile__c;
            proposalWrapper.orcidId = apa.Contact__r.ORCID_ID__c;
            proposalWrapper.titleOfThesisDissertation = proposal.Title_of_Thesis_Dissertation__c;
            proposalWrapper.researchSummaryDuringHighestDegree = proposal.Research_Summary_During_Highest_Degree__c;
            proposalWrapper.scientificMeetings = proposal.Scientific_Meetings__c;
            proposalWrapper.scientificCareerToDate = proposal.Scientific_career_to_date__c;
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


            response.proposalDetails = proposalWrapper;
            response.educationDetailsList = educationDetailsWrapperList;
            response.patentsDetailsList = patentsDetailsWrapperList;
            response.employmentDetailsList = employmentDetailsWrapperList;
            response.success = true;
            response.message = 'Proposal details fetched successfully';
            return response;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            return response;
        }
    }

    private static Contact getContactEducationAndPatents(String contactId){
        List<Contact> contacts = [
            SELECT Id,
                (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c,
                    Department_School_Division__c, Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, Pursuing_Higher_Degree__c, Start_Date__c
                 FROM Education_Details__r
                 ORDER BY End_Date__c DESC),
                (SELECT Id, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c
                 FROM Patents__r
                 ORDER BY Name ASC),
                 (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c, I_am_currently_working_here__c, End_Date__c, Start_Date__c, Reporting_To__c FROM Employment_Details__r ORDER BY End_Date__c DESC)
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public ProposalWrapper proposalDetails;
        public List<EducationDetailsWrapper> educationDetailsList;
        public List<PatentsDetailsWrapper> patentsDetailsList;
        public List<EmploymentDetailsWrapper> employmentDetailsList;
    }

    global class ProposalWrapper {
        public String proposalId;
        public String googleScholarProfileLink;
        public String orcidId;
        public String titleOfThesisDissertation;
        public String researchSummaryDuringHighestDegree;
        public String scientificMeetings;
        public String scientificCareerToDate;
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

    global class EducationDetailsWrapper {
        public String educationId;
        public String qualification;
        public String subject;
        public String country;
        public String institution;
        public String department;
        public String supervisor;
        public String thesisDissertationTitle;
        public String pursuingHigherDegree;
        public Date endDate;
        public Date startDate;
        public Boolean sourcedFromContact; // NEW: true if this record is the Contact master, not yet linked to this APA
    }

    global class PatentsDetailsWrapper {
        public String patentId;
        public String title;
        public String inventors;
        public String patentNumber;
        public String grantingAgencyCountry;
        public Date filingGrantedDate;
        public Boolean sourcedFromContact; // NEW
    }

    global class EmploymentDetailsWrapper {
        public String employmentId;
        public String organisation;
        public String position;
        public String description;
        public Boolean isCurrentlyWorking;
        public Date endDate;
        public Date startDate;
        public String reportingTo;
        public Boolean sourcedFromContact; // NEW
    }

}
*/

@RestResource(urlMapping='/getApplicantCVDetailsP3')
global without sharing class getApplicantCVDetailsP3 {

    @HttpGet
    global static ResponseWrapper getApplicantCVDetailsP3(){

        RestRequest req = RestContext.request;
        String proposalId = req.params.get('proposalId');
        String apaId = req.params.get('apaId');
        String contactId = req.params.get('contactId');

        System.debug('proposalId: ' + proposalId);
        System.debug('apaId: ' + apaId);
        System.debug('contactId: ' + contactId);


        ResponseWrapper response = new ResponseWrapper();
        ProposalWrapper proposalWrapper = new ProposalWrapper();
        List<EducationDetailsWrapper> educationDetailsWrapperList = new List<EducationDetailsWrapper>();
        List<PatentsDetailsWrapper> patentsDetailsWrapperList = new List<PatentsDetailsWrapper>();
        List<EmploymentDetailsWrapper> employmentDetailsWrapperList = new List<EmploymentDetailsWrapper>();

        // NEW: flags to track whether each list was sourced from the Contact master
        // rather than being genuinely scoped to this APA/proposal
        Boolean educationFromContact = false;
        Boolean patentFromContact = false;
        Boolean employmentFromContact = false;

        try{

            Proposal__c proposal;
            List<Education_Details__c> educationRecords = new List<Education_Details__c>();
            List<Patents__c> patentRecords = new List<Patents__c>();
            List<Employment_Details__c> employmentRecords = new List<Employment_Details__c>();

            Applicant_Proposal_Association__c apa;
            // Prefer apaId: Proposal + Education + Patents in one query via APA
            if(String.isNotBlank(apaId)){
                List<Applicant_Proposal_Association__c> apaRecords = [
                    SELECT Id, Contact__c, Proposal__c,Contact__r.Google_Scholar_Profile__c,Contact__r.ORCID_ID__c,
                        Proposal__r.Id,
                        Proposal__r.Title_of_Thesis_Dissertation__c,
                        Proposal__r.Research_Summary_During_Highest_Degree__c,
                        Proposal__r.Scientific_Meetings__c,
                        Proposal__r.Scientific_career_to_date__c,
                        Proposal__r.Have_you_identified_Sponsor_at_Host_Inst__c, Proposal__r.Sponsor_Name__c,Proposal__r.Sponsor_Designation__c, Proposal__r.Sponsor_Department__c,Proposal__r.Sponsor_Organisation__c, Proposal__r.Have_you_identified_mentor_on_your_appli__c,
                        Proposal__r.Mentor_Name__c, Proposal__r.Mentor_Designation__c, Proposal__r.Mentor_Department__c, Proposal__r.Mentor_Organisation__c, Proposal__r.Mentor_City__c, Proposal__r.Mentor_Country__c, Proposal__r.What_guidance_do_you_expect_to_receive__c, Proposal__r.If_identified_External_Sponsor_s_for_Wo__c,
                        (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c,
                            Department_School_Division__c, Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, Pursuing_Higher_Degree__c, Start_Date__c,
                            Applicant_Proposal_Association__c, Contact__c
                         FROM Education_Details__r
                         ORDER BY End_Date__c DESC),
                        (SELECT Id, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c,Status__c,
                            Applicant_Proposal_Association__c, Contact__c
                         FROM Patents__r
                         ORDER BY Name ASC),
                         (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c, I_am_currently_working_here__c, End_Date__c, Start_Date__c, Reporting_To__c,
                            Applicant_Proposal_Association__c, Contact__c
                          FROM Employment_Details__r ORDER BY End_Date__c DESC)
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :apaId
                    LIMIT 1
                ];

                if(apaRecords.isEmpty()){
                    response.success = false;
                    response.message = 'Applicant Proposal Association not found';
                    return response;
                }
                System.debug('apaRecords: ' + apaRecords);

                apa = apaRecords[0];
                if(apa.Proposal__c == null){
                    response.success = false;
                    response.message = 'Proposal not found for the given APA';
                    return response;
                }
                System.debug('apa: ' + apa);
                proposal = apa.Proposal__r;
                educationRecords = apa.Education_Details__r;
                patentRecords = apa.Patents__r;
                employmentRecords = apa.Employment_Details__r;

                System.debug('educationRecords: ' + educationRecords);
                System.debug('patentRecords: ' + patentRecords);
                System.debug('employmentRecords: ' + employmentRecords);
                System.debug('educationRecords.isEmpty(): ' + educationRecords.isEmpty());
                System.debug('patentRecords.isEmpty(): ' + patentRecords.isEmpty());

                // If APA has no education/patents/employment, fall back to Contact
                if(educationRecords.isEmpty() || patentRecords.isEmpty() || employmentRecords.isEmpty()){
                    System.debug('educationRecords is empty or patentRecords is empty or employmentRecords is empty');

                    String fallbackContactId;

                    System.debug('Coming here');

                    fallbackContactId = String.isNotBlank(String.valueOf(apa.Contact__c)) ? String.valueOf(apa.Contact__c) : String.valueOf(contactId);
                    System.debug('fallbackContactId: ' + fallbackContactId);

                    if(String.isNotBlank(fallbackContactId)){
                        Contact contactWithCv = getContactEducationAndPatents(fallbackContactId);
                        if(contactWithCv != null){
                            if(educationRecords.isEmpty()){
                                educationRecords = contactWithCv.Education_Details__r;
                                educationFromContact = true; // NEW
                            }
                            if(patentRecords.isEmpty()){
                                patentRecords = contactWithCv.Patents__r;
                                patentFromContact = true; // NEW
                            }
                            if(employmentRecords.isEmpty()){
                                employmentRecords = contactWithCv.Employment_Details__r;
                                employmentFromContact = true; // NEW
                            }
                        }
                    }
                    else{
                        response.success = false;
                        response.message = 'Contact ID is required when apaId is not provided';
                        return response;
                    }
                }
            }
            // Fallback: apaId blank — query Proposal; education/patents from Contact if contactId present
            else {
                System.debug('apaId is blank');
                System.debug('proposalId: ' + proposalId);
                System.debug('contactId: ' + contactId);

                if(String.isBlank(proposalId)){
                    response.success = false;
                    response.message = 'Proposal ID is required when apaId is not provided';
                    return response;
                }

                System.debug('proposalId: ' + proposalId);

                List<Proposal__c> proposals = [
                    SELECT Id, Research_Summary_During_Highest_Degree__c,
                        Scientific_Meetings__c, Scientific_career_to_date__c, Title_of_Thesis_Dissertation__c, Have_you_identified_Sponsor_at_Host_Inst__c, Sponsor_Name__c,Sponsor_Designation__c, Sponsor_Department__c,Sponsor_Organisation__c, Have_you_identified_mentor_on_your_appli__c,
                        Mentor_Name__c, Mentor_Designation__c, Mentor_Department__c, Mentor_Organisation__c, Mentor_City__c, Mentor_Country__c, What_guidance_do_you_expect_to_receive__c, If_identified_External_Sponsor_s_for_Wo__c
                    FROM Proposal__c
                    WHERE Id = :proposalId
                    LIMIT 1
                ];

                if(proposals.isEmpty()){
                    response.success = false;
                    response.message = 'Proposal not found';
                    return response;
                }
                System.debug('proposals: ' + proposals);
                proposal = proposals[0];

                if(String.isNotBlank(contactId)){
                    System.debug('contactId: ' + contactId);
                    Contact contactWithCv = getContactEducationAndPatents(contactId);
                    if(contactWithCv != null){
                        educationRecords = contactWithCv.Education_Details__r;
                        patentRecords = contactWithCv.Patents__r;
                        employmentRecords = contactWithCv.Employment_Details__r;
                        // NEW: this whole branch has no APA yet, so everything here
                        // is by definition sourced from the Contact master
                        educationFromContact = !educationRecords.isEmpty();
                        patentFromContact = !patentRecords.isEmpty();
                        employmentFromContact = !employmentRecords.isEmpty();
                    }
                }
            }

            for(Education_Details__c educationDetail : educationRecords){
                EducationDetailsWrapper educationDetailsWrapper = new EducationDetailsWrapper();
                educationDetailsWrapper.educationId = educationDetail.Id;
                educationDetailsWrapper.qualification = educationDetail.Qualification__c;
                educationDetailsWrapper.subject = educationDetail.Subject__c;
                educationDetailsWrapper.country = educationDetail.Country__c;
                educationDetailsWrapper.institution = educationDetail.Institution__c;
                educationDetailsWrapper.department = educationDetail.Department_School_Division__c;
                educationDetailsWrapper.supervisor = educationDetail.Supervisor__c;
                educationDetailsWrapper.thesisDissertationTitle = educationDetail.Title_of_thesis_Dissertation__c;
                educationDetailsWrapper.endDate = educationDetail.End_Date__c;
                educationDetailsWrapper.pursuingHigherDegree = educationDetail.Pursuing_Higher_Degree__c;
                educationDetailsWrapper.startDate = educationDetail.Start_Date__c;
                educationDetailsWrapper.sourcedFromContact = educationFromContact; // NEW
                educationDetailsWrapper.apaId = educationDetail.Applicant_Proposal_Association__c; // NEW
                educationDetailsWrapper.contactId = educationDetail.Contact__c; // NEW
                educationDetailsWrapperList.add(educationDetailsWrapper);
            }

            for(Patents__c patent : patentRecords){
                PatentsDetailsWrapper patentsDetailsWrapper = new PatentsDetailsWrapper();
                patentsDetailsWrapper.patentId = patent.Id;
                patentsDetailsWrapper.title = patent.Title__c;
                patentsDetailsWrapper.inventors = patent.Inventors__c;
                patentsDetailsWrapper.patentNumber = patent.Patent_Number__c;
                patentsDetailsWrapper.status = patent.Status__c;
                patentsDetailsWrapper.grantingAgencyCountry = patent.Granting_Agency_Country__c;
                patentsDetailsWrapper.filingGrantedDate = patent.Filing_Granted_Date__c;
                patentsDetailsWrapper.sourcedFromContact = patentFromContact; // NEW
                patentsDetailsWrapper.apaId = patent.Applicant_Proposal_Association__c; // NEW
                patentsDetailsWrapper.contactId = patent.Contact__c; // NEW
                patentsDetailsWrapperList.add(patentsDetailsWrapper);
            }

            for(Employment_Details__c employmentDetail : employmentRecords){
                EmploymentDetailsWrapper employmentDetailsWrapper = new EmploymentDetailsWrapper();
                employmentDetailsWrapper.employmentId = employmentDetail.Id;
                employmentDetailsWrapper.organisation = employmentDetail.Organisation__c;
                employmentDetailsWrapper.position = employmentDetail.Position__c;
                employmentDetailsWrapper.description = employmentDetail.Roles_Responsibilities__c;
                employmentDetailsWrapper.isCurrentlyWorking = employmentDetail.I_am_currently_working_here__c;
                employmentDetailsWrapper.endDate = employmentDetail.End_Date__c;
                employmentDetailsWrapper.startDate = employmentDetail.Start_Date__c;
                employmentDetailsWrapper.reportingTo = employmentDetail.Reporting_To__c;
                employmentDetailsWrapper.sourcedFromContact = employmentFromContact; // NEW
                employmentDetailsWrapper.apaId = employmentDetail.Applicant_Proposal_Association__c; // NEW
                employmentDetailsWrapper.contactId = employmentDetail.Contact__c; // NEW
                employmentDetailsWrapperList.add(employmentDetailsWrapper);
            }

            proposalWrapper.proposalId = proposal.Id;
            proposalWrapper.googleScholarProfileLink = apa.Contact__r.Google_Scholar_Profile__c;
            proposalWrapper.orcidId = apa.Contact__r.ORCID_ID__c;
            proposalWrapper.titleOfThesisDissertation = proposal.Title_of_Thesis_Dissertation__c;
            proposalWrapper.researchSummaryDuringHighestDegree = proposal.Research_Summary_During_Highest_Degree__c;
            proposalWrapper.scientificMeetings = proposal.Scientific_Meetings__c;
            proposalWrapper.scientificCareerToDate = proposal.Scientific_career_to_date__c;
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

            List<Scheme_Section__c> schemeSectionList = [
                SELECT Id, Name, Applicant_Proposal_Association__c, Data_Filled_Successfully__c, Section_Name__c
                FROM Scheme_Section__c
                WHERE Applicant_Proposal_Association__c = :apaId
            ];

            List<SectionWrapper> sectionWrappers = new List<SectionWrapper>();
            for(Scheme_Section__c section : schemeSectionList){
                SectionWrapper sw = new SectionWrapper();
                sw.sectionId = section.Id;
                sw.sectionName = section.Section_Name__c;
                sw.sectionStatus = section.Data_Filled_Successfully__c;
                sectionWrappers.add(sw);
            }

            response.proposalDetails = proposalWrapper;
            response.educationDetails = educationDetailsWrapperList;
            response.patentsDetails = patentsDetailsWrapperList;
            response.employmentDetails = employmentDetailsWrapperList;
            response.sectionDetails = sectionWrappers;
            response.success = true;
            response.message = 'Proposal details fetched successfully';
            return response;
        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
            return response;
        }
    }

    private static Contact getContactEducationAndPatents(String contactId){
        List<Contact> contacts = [
            SELECT Id,
                (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c,
                    Department_School_Division__c, Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, Pursuing_Higher_Degree__c, Start_Date__c,
                    Applicant_Proposal_Association__c, Contact__c
                 FROM Education_Details__r
                 ORDER BY End_Date__c DESC),
                (SELECT Id, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c,Status__c,
                    Applicant_Proposal_Association__c, Contact__c
                 FROM Patents__r
                 ORDER BY Name ASC),
                 (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c, I_am_currently_working_here__c, End_Date__c, Start_Date__c, Reporting_To__c,
                    Applicant_Proposal_Association__c, Contact__c
                  FROM Employment_Details__r ORDER BY End_Date__c DESC)
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public ProposalWrapper proposalDetails;
        public List<EducationDetailsWrapper> educationDetails;
        public List<PatentsDetailsWrapper> patentsDetails;
        public List<EmploymentDetailsWrapper> employmentDetails;
        public List<SectionWrapper> sectionDetails;
    }

    global class ProposalWrapper {
        public String proposalId;
        public String googleScholarProfileLink;
        public String orcidId;
        public String titleOfThesisDissertation;
        public String researchSummaryDuringHighestDegree;
        public String scientificMeetings;
        public String scientificCareerToDate;
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

    global class EducationDetailsWrapper {
        public String educationId;
        public String qualification;
        public String subject;
        public String country;
        public String institution;
        public String department;
        public String supervisor;
        public String thesisDissertationTitle;
        public String pursuingHigherDegree;
        public Date endDate;
        public Date startDate;
        public Boolean sourcedFromContact; // true if this record is the Contact master, not yet linked to this APA
        public String apaId; // NEW: Applicant_Proposal_Association__c on the underlying record (null if not yet APA-scoped)
        public String contactId; // NEW: Contact__c on the underlying record (null if it's an APA-scoped copy)
    }

    global class PatentsDetailsWrapper {
        public String patentId;
        public String title;
        public String inventors;
        public String patentNumber;
        public String status;
        public String grantingAgencyCountry;
        public Date filingGrantedDate;
        public Boolean sourcedFromContact;
        public String apaId; // NEW
        public String contactId; // NEW
    }

    global class EmploymentDetailsWrapper {
        public String employmentId;
        public String organisation;
        public String position;
        public String description;
        public Boolean isCurrentlyWorking;
        public Date endDate;
        public Date startDate;
        public String reportingTo;
        public Boolean sourcedFromContact;
        public String apaId; // NEW
        public String contactId; // NEW
    }

    global class SectionWrapper {
        public String sectionId;
        public String sectionName;
        public Boolean sectionStatus;
    }
}