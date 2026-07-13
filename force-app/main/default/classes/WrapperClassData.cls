global with sharing class WrapperClassData {

    global class ProfileDetailsWrapper{
        public String contactId;
        public String title;
        public String firstName;
        public String lastName;
        public String mobileNumber;
        public String email;
        public Date dob;
        
        public String currentOrg;	// Account
        public String designationRole;
        public String department;

        public String qualifyingDegree;
        public Date qualifyingDegreeVivaDate;
        public Integer durationOfResearchExperienceAfterQualifyingVivaDate_Years;
        public Integer durationOfResearchExperienceAfterQualifyingVivaDate_Months;
        public Date nonResearchCareerBreak_From;
        public Date nonResearchCareerBreak_To;
        public String nonReserchCareerBreak_Explaination;
        public String orcidID;
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
        public Date yearOfAward;
    }

    global class EmploymentDetailsWrapper {
        public String employmentId;
        public String organisation;
        public String position;
        public String startDate;
        public String endDate;
        public String description;
    }

    global class AchievementsDetailsWrapper {
        public String achievementId;
        public String name;
        public String anyOtherAchievements;
        public String applicantProposalAssociation;
    }

    global class PublicationsDetailsWrapper {
        public String publicationId;
        public String name;
        public String applicantProposalAssociation;
    }

    global class PatentsDetailsWrapper {
        public String patentId;
        public String name;
        public String applicantProposalAssociation;
        public String contact;
        public String title;
        public String investors;
        public String patentNumber;
        public String grantingAgencyCountry;
        public Date filing_granted_date;
        public String status;
    }

    global class ExistingGrantsDetailsWrapper {
        public String existingGrantId;
        public String name;
        public String applicantProposalAssociation;
        public String contact;
        public String title;
        public String roleOfApplicant;
        public Integer durationInMonths;
        public String fundingAgency;

        public Date startDate;
        public Date endDate;
        public Decimal totalAwardAmount;
        public String currencyCode;
        public String type;
        public String otherCurrency;
        public String abstractsOfOngoingGrantsFellowship;
    }
}