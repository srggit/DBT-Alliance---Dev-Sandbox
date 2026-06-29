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
                MailingState, MailingCountry, MailingPostalCode
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
            //con.Email = req.email;
            con.BirthDate = req.dob;
            con.Nationality__c = req.nationality;
            con.Gender__c = req.gender;
            
            con.Position__c = req.currentPosition;
            con.Department = req.department;
            con.Phone = req.mobileNuber;
            
            con.MailingCity = req.city;
            con.MailingState = req.state;
            con.MailingCountry = req.country;
            con.MailingPostalCode = req.postalCode;
            
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
        public Date dob;
        
        public String nationality;
        public String gender;
        public String currentOrg;	// Account
        public String currentPosition;
        public String department;
        public String city;
        public String district;
        public String state;
        public String country;
        public String postalCode;
        public String mobileNuber;
        public String qualifyingDegree;
        public Date qualifyingDegreeVivaDate;
        public String durationOfResearchExperienceAfterQualifyingDegreeVivaDate;
        public String nonResearchCareerBreak;
    }
    
    global class ProfileResponse{
        public Boolean success;
        public String message;
        public String contactId;
    }
    
}