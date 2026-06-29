@RestResource(urlMapping='/register')
global class RegistrationAPI {

    @HttpPost
    global static RegisterResponse registerUser() {

        RegisterResponse response = new RegisterResponse();

        try {
			System.debug('RestContext.request.requestBody.toString() : ' + RestContext.request.requestBody.toString());
            RegisterRequest req = (RegisterRequest) JSON.deserialize(RestContext.request.requestBody.toString(), RegisterRequest.class);
            System.debug('req data received : ' + req);
            System.debug('conact email : ' + req.email);
	        Set<String> emails = new Set<String>();
            emails.add(req.email);
            System.debug('emails====>'+emails);
            List<Contact> existingContacts = [
                SELECT Id, Email
                FROM Contact
                WHERE Email = : req.email
                LIMIT 1
            ];
            System.debug('existingContacts : ' + existingContacts);
            
            if(!existingContacts.isEmpty()){
                response.success = false;
                response.message = 'Contact already exits with this credentials';
                response.contactId = existingContacts[0].Id;
                
                return response;
            }
	
            String passwordHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(req.password)));
            
            Contact con = new Contact();
            con.Title = req.title;
            con.Title__c = req.title;
            con.FirstName = req.firstName;
            con.LastName = req.lastName;
            con.Gender__c = req.gender;
            con.BirthDate = req.dob;
            con.Nationality__c = req.nationality;
            
            con.AccountId = req.accountId;
            con.Position__c = req.currentPosition;
            con.Department = req.department;
            
            con.MailingCity = req.city;
            //con. = req.district;
            con.MailingState = req.state;
            con.MailingCountry = req.country;
            con.MailingPostalCode = req.postalCode;
            
            con.Phone = req.mobileNuber;
            con.MobilePhone = req.mobileNuber;
            con.Email = req.email;
            con.Password__c = req.password;
            con.Password_Hash__c = passwordHash;
            
            con.Firebase_UID__c = req.uid;
            con.Qualifying_Degree__c = req.qualifyingDegree;
            con.Other_Degree__c = req.otherDegree;
            insert con;

            response.success = true;
            response.message = 'Registered Successful';
            response.contactId = con.Id;

        } catch(Exception e) {
	
            System.debug('###### e.getMessage : ' + e.getMessage());
            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    public class RegisterRequest {
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
        public String otherDegree;
        public Date qualifyingDegreeVivaDate;
        
        public String accountId;
        
        // Doubts here to store the data
        /*
        public String durationOfResearchExperienceAfterQualifyingDegreeVivaDate;
        public String nonResearchCareerBreak;
		*/
    }

    global class RegisterResponse {
        global Boolean success;
        global String message;
        global String contactId;
    }
}