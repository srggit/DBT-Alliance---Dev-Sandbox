@RestResource(urlMapping='/getProfileAndCVDetails')
global without sharing class GetProfileAndCVDetails {

    @HttpGet
    global static ResponseWrapper getProfileAndCVDetails(){

        RestRequest req = RestContext.request;
        String email = req.params.get('email');
        String contactId = req.params.get('contactId');

        ResponseWrapper response = new ResponseWrapper();

        if(String.isBlank(email) && String.isBlank(contactId)){
            response.success = false;
            response.message = 'Missing required parameter: email or contactId';
            return response;
        }
        System.debug('email : ' + email);
        System.debug('contactId : ' + contactId);

        try {
            List<Contact> contacts = [
                SELECT Id, Title, Title__c, FirstName, LastName, Phone, Email, BirthDate, Position__c, Department, MailingCity, 
                MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Name, Qualifying_Degree__c, Qualifying_Degree_Viva_Date__c, Research_Experience_After_Viva_Date_Yrs__c, Research_Experience_After_Viva_Date_Mont__c, Non_Research_Career_Break_From__c, Non_Research_Career_Break_To__c, Non_Research_Career_Break_Explanation__c, ORCID_ID__c,

                    (SELECT Id, Applicant_Proposal_Association__c, Contact__c, Country__c, CreatedById, CreatedDate, CurrencyIsoCode, Department_School_Division__c, End_Date__c, Institution__c, IsDeleted, Likely_date_of_completion__c, Name, OwnerId, Pursuing_Higher_Degree__c, Qualification__c, Research_Summary_During_Highest_Degree__c, Specify_Other_Degree__c, Specify_the_pursuing_degree__c, Specify_the_University__c, Start_Date__c, Subject__c, Supervisor__c, Title_of_thesis_Dissertation__c, University__c 
                    FROM Education_Details__r ORDER BY End_Date__c DESC),
                    
                    (SELECT Id, Applicant_Proposal_Association__c, Contact__c, End_Date__c, I_am_currently_working_here__c, Name, Organisation__c, Position__c, Reporting_To__c, Roles_Responsibilities__c, Start_Date__c 
                    FROM Employment_Details__r ORDER BY End_Year_Present__c DESC),

                    (SELECT Id, Achievement_Title__c, Any_Other_Achievements__c, Applicant_Proposal_Association__c, Contact__c, CreatedById, CreatedDate, Description__c, Name, Organization__c, Year__c 
                    FROM Achievements__r ORDER BY Achievement_Title__c ASC),          

                    (SELECT Id, Name, Applicant_Proposal_Association__c, Sr_No__c, Title__c, Journal_Name__c, Author_Names__c, Applicant_Role__c, Number_of_citations_at_present__c, PMID_DOI_URL__c 
                    FROM Publications__r ORDER BY Name ASC),

                    (SELECT Id, Name, Applicant_Proposal_Association__c, Contact__c, Title__c, Inventors__c, Patent_Number__c, Granting_Agency_Country__c, Filing_Granted_Date__c, Status__c
                    FROM Patents__r ORDER BY Name ASC),

                    (SELECT Id, Name, Contact__c, Applicant_Proposal_Association__c, Title__c, Role_Of_Applicant__c, Duration_In_Months__c, Funding_Agency__c, Start_Date__c, End_Date__c, Total_Award_Amount__c, Currency__c, Type__c, Other_Currency__c, Abstracts_of_ongoing_grants_fellowship__c
                    FROM Existing_Grants__r ORDER BY Name ASC)

                FROM Contact
                WHERE (Email = :email OR Id = :contactId)
                LIMIT 1
            ];

            if(contacts.isEmpty()){
                response.success = false;
                response.message = 'Contact not found';
                return response;
            }
            
            Contact con = contacts[0];

            WrapperClassData.ProfileDetailsWrapper profileDetails = new WrapperClassData.ProfileDetailsWrapper();
            List<WrapperClassData.EducationDetailsWrapper> educationDetailsWrapperList = new List<WrapperClassData.EducationDetailsWrapper>();
            List<WrapperClassData.EmploymentDetailsWrapper> employmentDetailsWrapperList = new List<WrapperClassData.EmploymentDetailsWrapper>();
            List<WrapperClassData.AchievementsDetailsWrapper> achievementsDetailsWrapperList = new List<WrapperClassData.AchievementsDetailsWrapper>();
            List<WrapperClassData.PublicationsDetailsWrapper> publicationsDetailsWrapperList = new List<WrapperClassData.PublicationsDetailsWrapper>();
            List<WrapperClassData.PatentsDetailsWrapper> patentsDetailsWrapperList = new List<WrapperClassData.PatentsDetailsWrapper>();
            List<WrapperClassData.ExistingGrantsDetailsWrapper> existingGrantsDetailsWrapperList = new List<WrapperClassData.ExistingGrantsDetailsWrapper>();    
            
            profileDetails.contactId = con.Id;  
            profileDetails.title = con.Title;
            profileDetails.firstName = con.FirstName;
            profileDetails.email = con.Email;
            profileDetails.lastName = con.LastName;
            profileDetails.mobileNumber = con.Phone;
            profileDetails.dob = con.BirthDate;

            profileDetails.currentOrg = con.Account?.Name;
            profileDetails.department = con.Department;
            profileDetails.designationRole = con.Position__c;

            profileDetails.qualifyingDegree = con.Qualifying_Degree__c;
            profileDetails.qualifyingDegreeVivaDate = con.Qualifying_Degree_Viva_Date__c;
            profileDetails.durationOfResearchExperienceAfterQualifyingVivaDate_Years = Integer.valueOf(con.Research_Experience_After_Viva_Date_Yrs__c);
            profileDetails.durationOfResearchExperienceAfterQualifyingVivaDate_Months = Integer.valueOf(con.Research_Experience_After_Viva_Date_Mont__c);

            profileDetails.nonResearchCareerBreak_From = con.Non_Research_Career_Break_From__c;
            profileDetails.nonResearchCareerBreak_To = con.Non_Research_Career_Break_To__c;
            profileDetails.nonReserchCareerBreak_Explaination = con.Non_Research_Career_Break_Explanation__c;
            profileDetails.orcidID = con.ORCID_ID__c;

            for(Education_Details__c edu : con.Education_Details__r){
                WrapperClassData.EducationDetailsWrapper educationDetailsWrapper = new WrapperClassData.EducationDetailsWrapper();
                educationDetailsWrapper.educationId = edu.Id;
                educationDetailsWrapper.qualification = edu.Qualification__c;
                educationDetailsWrapper.institution = edu.Institution__c;
                educationDetailsWrapper.yearOfAward = edu.End_Date__c;
                educationDetailsWrapper.thesisDissertationTitle = edu.Title_of_thesis_Dissertation__c;
                educationDetailsWrapper.likelyDateOfCompletion = edu.Likely_date_of_completion__c;
                educationDetailsWrapper.pursuingHigherDegree = edu.Pursuing_Higher_Degree__c;
                educationDetailsWrapper.researchSummaryDuringHighestDegree = edu.Research_Summary_During_Highest_Degree__c;
                educationDetailsWrapper.specifyOtherDegree = edu.Specify_Other_Degree__c;
                educationDetailsWrapper.specifyThePursuingDegree = edu.Specify_the_pursuing_degree__c;
                educationDetailsWrapper.specifyTheUniversity = edu.Specify_the_University__c;
                educationDetailsWrapper.titleOfThesisDissertation = edu.Title_of_thesis_Dissertation__c;
                educationDetailsWrapper.university = edu.University__c;
                educationDetailsWrapperList.add(educationDetailsWrapper);
            }

            for(Employment_Details__c emp : con.Employment_Details__r){
                WrapperClassData.EmploymentDetailsWrapper employmentDetailsWrapper = new WrapperClassData.EmploymentDetailsWrapper();
                employmentDetailsWrapper.employmentId = emp.Id;
                employmentDetailsWrapper.organisation = emp.Organisation__c;
                employmentDetailsWrapper.position = emp.Position__c;
                employmentDetailsWrapper.description = emp.Roles_Responsibilities__c;
                employmentDetailsWrapper.isCurrentlyWorking = emp.I_am_currently_working_here__c;
                employmentDetailsWrapper.endDate = emp.End_Date__c;
                employmentDetailsWrapper.startDate = emp.Start_Date__c;

                employmentDetailsWrapperList.add(employmentDetailsWrapper);
            }

            for(Achievements__c ach : con.Achievements__r){
                WrapperClassData.AchievementsDetailsWrapper achievementsDetailsWrapper = new WrapperClassData.AchievementsDetailsWrapper();
                achievementsDetailsWrapper.achievementId = ach.Id;
                achievementsDetailsWrapper.name = ach.Name;
                achievementsDetailsWrapper.anyOtherAchievements = ach.Any_Other_Achievements__c;
                achievementsDetailsWrapper.applicantProposalAssociation = ach.Applicant_Proposal_Association__c;
                achievementsDetailsWrapper.achievementTitle = ach.Achievement_Title__c;
                achievementsDetailsWrapper.organization = ach.Organization__c;
                achievementsDetailsWrapper.year = ach.Year__c;
                achievementsDetailsWrapperList.add(achievementsDetailsWrapper);
            }

            for(Publications__c pub : con.Publications__r){
                WrapperClassData.PublicationsDetailsWrapper publicationsDetailsWrapper = new WrapperClassData.PublicationsDetailsWrapper();
                publicationsDetailsWrapper.publicationId = pub.Id;
                publicationsDetailsWrapper.name = pub.Name;
                publicationsDetailsWrapper.applicantProposalAssociation = pub.Applicant_Proposal_Association__c;
                publicationsDetailsWrapper.srNo = pub.Sr_No__c;
                publicationsDetailsWrapper.title = pub.Title__c;    
                publicationsDetailsWrapper.journalName = pub.Journal_Name__c;
                publicationsDetailsWrapper.authorNames = pub.Author_Names__c;
                publicationsDetailsWrapper.applicantRole = pub.Applicant_Role__c;
                publicationsDetailsWrapper.numberOfCitationsAtPresent = pub.Number_of_citations_at_present__c;
                publicationsDetailsWrapper.pmidDoiUrl = pub.PMID_DOI_URL__c;

                publicationsDetailsWrapperList.add(publicationsDetailsWrapper);
            }

            for(Patents__c pat : con.Patents__r){
                WrapperClassData.PatentsDetailsWrapper patentsDetailsWrapper = new WrapperClassData.PatentsDetailsWrapper();
                patentsDetailsWrapper.patentId = pat.Id;
                patentsDetailsWrapper.name = pat.Name;
                patentsDetailsWrapper.applicantProposalAssociation = pat.Applicant_Proposal_Association__c;
                patentsDetailsWrapper.contact = pat.Contact__c;
                patentsDetailsWrapper.title = pat.Title__c;
                patentsDetailsWrapper.inventors = pat.Inventors__c;
                patentsDetailsWrapper.patentNumber = pat.Patent_Number__c;
                patentsDetailsWrapper.grantingAgencyCountry = pat.Granting_Agency_Country__c;
                patentsDetailsWrapper.filing_granted_date = pat.Filing_Granted_Date__c;
                patentsDetailsWrapper.status = pat.Status__c;
                patentsDetailsWrapperList.add(patentsDetailsWrapper);
            }

            for(Existing_Grants__c eg : con.Existing_Grants__r){
                WrapperClassData.ExistingGrantsDetailsWrapper existingGrantsDetailsWrapper = new WrapperClassData.ExistingGrantsDetailsWrapper();
                existingGrantsDetailsWrapper.existingGrantId = eg.Id;
                existingGrantsDetailsWrapper.name = eg.Name;
                existingGrantsDetailsWrapper.applicantProposalAssociation = eg.Applicant_Proposal_Association__c;
                existingGrantsDetailsWrapper.contact = eg.Contact__c;
                existingGrantsDetailsWrapper.title = eg.Title__c;
                existingGrantsDetailsWrapper.roleOfApplicant = eg.Role_Of_Applicant__c;
                existingGrantsDetailsWrapper.durationInMonths = Integer.valueOf(eg.Duration_In_Months__c);
                existingGrantsDetailsWrapper.fundingAgency = eg.Funding_Agency__c;
                existingGrantsDetailsWrapper.startDate = eg.Start_Date__c;
                existingGrantsDetailsWrapper.endDate = eg.End_Date__c;
                existingGrantsDetailsWrapper.totalAwardAmount = eg.Total_Award_Amount__c;
                existingGrantsDetailsWrapper.currencyCode = eg.Currency__c;
                existingGrantsDetailsWrapper.type = eg.Type__c;
                existingGrantsDetailsWrapper.otherCurrency = eg.Other_Currency__c;

                existingGrantsDetailsWrapperList.add(existingGrantsDetailsWrapper);
            }

            response.achievementsDetails = achievementsDetailsWrapperList;
            response.publicationsDetails = publicationsDetailsWrapperList;
            response.patentsDetails = patentsDetailsWrapperList;
            response.existingGrantsDetails = existingGrantsDetailsWrapperList;

            response.success = true;
            response.message = 'Profile and CV details fetched successfully.';
            response.profileDetails = profileDetails;
            response.educationDetails = educationDetailsWrapperList;
            response.employmentDetails = employmentDetailsWrapperList;
            return response;
            
        } catch (QueryException e) {
            response.success = false;
            response.message = 'Contact record not found.';
            return response;
        } catch (Exception ex) {
            response.success = false;
            response.message = 'An error occurred: ' + ex.getMessage();
            return response;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public WrapperClassData.ProfileDetailsWrapper profileDetails;
        public List<WrapperClassData.EducationDetailsWrapper> educationDetails;
        public List<WrapperClassData.EmploymentDetailsWrapper> employmentDetails;
        public List<WrapperClassData.AchievementsDetailsWrapper> achievementsDetails;
        public List<WrapperClassData.PublicationsDetailsWrapper> publicationsDetails;
        public List<WrapperClassData.PatentsDetailsWrapper> patentsDetails;
        public List<WrapperClassData.ExistingGrantsDetailsWrapper> existingGrantsDetails;
    }   
}