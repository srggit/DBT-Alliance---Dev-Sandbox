@RestResource(urlMapping='/profileInfoApi')
global without sharing class ProfileInfoAPI {
	
    @HttpPost
    global static ProfileResponse saveProfileInfo(){
        
        ProfileResponse response = new ProfileResponse();
        
        try{
            ProfileDataRequest req = (ProfileDataRequest) JSON.deserialize(RestContext.request.requestBody.toString(), ProfileDataRequest.class);
            System.debug('Received Req : ' + req);
            
            List<Contact> contacts = [
                SELECT Id, FirstName, LastName, Email, BirthDate, Nationality__c, Gender__c, Position__c, Department, Phone, MailingCity, 
                MailingState, MailingCountry, MailingPostalCode, Google_Scholar_Profile__c
                FROM Contact 
                WHERE Email = :req.email
                LIMIT 1
            ];
            
            if(contacts.isEmpty()) {
                response.success = false;
                response.message = 'User not found';

                return response;
            }
            
            Contact con = contacts[0];
            
            con.FirstName = req.firstName;
            con.LastName = req.lastName;
            con.Email = req.email;
            con.Phone = req.mobileNuber;
            con.BirthDate = req.dob;

            con.AccountId = req.organisation_institution; // Account Id
            con.Department = req.department;
            con.Position__c = req.designationRole;

            con.Qualifying_Degree__c = req.qualifyingDegree;
            con.Qualifying_Degree_Viva_Date__c = req.qualifyingDegreeVivaDate;
            con.Research_Experience_After_Viva_Date_Yrs__c = req.durationOfResearchExperienceAfterQualifyingVivaDate_Years;
            con.Research_Experience_After_Viva_Date_Mont__c = req.durationOfResearchExperienceAfterQualifyingVivaDate_Months;

            con.Non_Research_Career_Break_From__c = req.nonResearchCareerBreak_From;
            con.Non_Research_Career_Break_To__c = req.nonResearchCareerBreak_To;
            con.Non_Research_Career_Break_Explanation__c = req.nonReserchCareerBreak_Explaination;

            con.ORCID_ID__c = req.orcidID;
            con.Google_Scholar_Profile__c = req.googleScholarProfileLink;
            update con;
            
            response.success = true;
            response.message = 'Profile data updated successfully !!';
            response.contactId = con.Id;
            
            return response;
        }
        catch(Exception ex){
            response.success = false;
            response.message = ex.getMessage();
            
            return response;
        }
    }
    
    
    global class ProfileDataRequest{
        public String firstName;
        public String lastName;
        public String email;
        public String mobileNuber;
        public Date dob;

        public String qualifyingDegree;
        public Date qualifyingDegreeVivaDate;

        public String organisation_institution;
        public String department;
        public String designationRole;
        public Integer durationOfResearchExperienceAfterQualifyingVivaDate_Years;
        public Integer durationOfResearchExperienceAfterQualifyingVivaDate_Months;
        public Date nonResearchCareerBreak_From;
        public Date nonResearchCareerBreak_To;
        public String nonReserchCareerBreak_Explaination;     
        public String orcidID;
        public String googleScholarProfileLink;
    }
    
    global class ProfileResponse{
        public Boolean success;
        public String message;
        public String contactId;
    }
    
}