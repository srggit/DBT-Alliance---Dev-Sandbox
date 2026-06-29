@RestResource(urlMapping='/getRegistrationDetails')
global without sharing class GetRegistrationDetailsAPI {
	
    @HttpGet
    global static ResponseWrapper getContactDetails(){
        
        ResponseWrapper response = new ResponseWrapper();
        
        RestRequest req = RestContext.request;
        String contactId = req.params.get('contactId');
        
        System.debug('### Received Contact Id : ' + contactId);
        
        if (String.isBlank(contactId)) {
            response.success = false;
            response.message = 'Missing required parameter: contactId';
            return response;
        }
            
        try {
            
            List<Contact> existingContact = [
                SELECT Id, Title, Title__c, FirstName, LastName, Gender__c, BirthDate, Nationality__c, 
                AccountId, Position__c, Department, 
                MailingCity, MailingState, MailingCountry, MailingPostalCode,
                Phone, Email, Password__c, Password_Hash__c, Firebase_UID__c
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
            System.debug('## Contact Found : ' + existingContact);
            
            Contact con = existingContact[0];
                        
            response.success = true;
            response.message = 'Contact record found.';
            response.contactId = con.Id;
			
            response.title = con.Title;
            response.title = con.Title;
            response.firstName = con.FirstName;
            response.lastName = con.LastName;
            response.gender = con.Gender__c;
            response.dob = con.BirthDate;
            response.nationality = con.Nationality__c;
            
            //con.AccountId = ;
            response.currentPosition = con.Position__c;
            response.department = con.Department;
            
            response.city = con.MailingCity;
            //con. = req.district;
            response.state = con.MailingState;
            response.country = con.MailingCountry;
            response.postalCode = con.MailingPostalCode;
            
            response.mobileNuber = con.Phone;
            response.email = con.Email;
            
            response.uid = con.Firebase_UID__c;
            
        } catch (QueryException e) {
            response.success = false;
            response.message = 'Contact record not found.';
        } catch (Exception e) {
            response.success = false;
            response.message = 'An error occurred: ' + e.getMessage();
        }
        
        return response;
    }


    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public String contactId;
        
        public String title;
        public String firstName;
        public String lastName;
        public String gender;
        public Date dob;
        public String nationality;
        
        public String currentOrg;	// Account
        public String currentPosition;
        public String department;
        public String city;
        public String district;
        public String state;
        public String country;
        public String postalCode;
        
        public String mobileNuber;
        public String email;
        public String password;      
        
        public String uid;
        
        public String qualifyingDegree;
        public Date qualifyingDegreeVivaDate;
        
        // Doubts here to store the data
        /*
        public String durationOfResearchExperienceAfterQualifyingDegreeVivaDate;
        public String nonResearchCareerBreak;
		*/
    }
}