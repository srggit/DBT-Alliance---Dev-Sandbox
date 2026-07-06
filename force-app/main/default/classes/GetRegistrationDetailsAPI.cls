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

            if(existingContact.isEmpty()){
                response.success = false;
                response.message = 'Contact record not found.';
                response.contactDetailsWrapper = null;
                return response;
            }
            
            Contact con = existingContact[0];
            ContactDetailsWrapper contactDetailsWrapper = new ContactDetailsWrapper();

            contactDetailsWrapper.contactId = con.Id;
            contactDetailsWrapper.title = con.Title;
            contactDetailsWrapper.firstName = con.FirstName;
            contactDetailsWrapper.lastName = con.LastName;
            contactDetailsWrapper.gender = con.Gender__c;
            contactDetailsWrapper.dob = con.BirthDate;
            contactDetailsWrapper.nationality = con.Nationality__c;
            
            contactDetailsWrapper.currentPosition = con.Position__c;
            contactDetailsWrapper.department = con.Department;
            
            contactDetailsWrapper.city = con.MailingCity;
            contactDetailsWrapper.district = con.MailingState;
            contactDetailsWrapper.state = con.MailingState;
            contactDetailsWrapper.country = con.MailingCountry;
            contactDetailsWrapper.postalCode = con.MailingPostalCode;

            contactDetailsWrapper.mobileNuber = con.Phone;
            contactDetailsWrapper.email = con.Email;
            
            contactDetailsWrapper.uid = con.Firebase_UID__c;
            
            // contactDetailsWrapper.qualifyingDegree = con.Qualifying_Degree__c;
            // contactDetailsWrapper.qualifyingDegreeVivaDate = con.Qualifying_Degree_Viva_Date__c;
                        
            response.success = true;
            response.message = 'Contact record found.';
            response.contactDetailsWrapper = contactDetailsWrapper;

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
        public ContactDetailsWrapper contactDetailsWrapper;
    }

    global class ContactDetailsWrapper{
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