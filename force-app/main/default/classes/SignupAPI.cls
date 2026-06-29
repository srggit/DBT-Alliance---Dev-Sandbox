@RestResource(urlMapping='/signup/*')
global without sharing class SignupAPI {

    @HttpPost
    global static SignupResponse signup() {

        SignupResponse response = new SignupResponse();

        try {
			System.debug('RestContext.request.requestBody.toString() : ' + RestContext.request.requestBody.toString());
            SignupRequest req = (SignupRequest) JSON.deserialize(RestContext.request.requestBody.toString(), SignupRequest.class);
            System.debug('req data received : ' + req);

            List<Contact> existingContacts = [
                SELECT Id, Email
                FROM Contact
                WHERE Email = :req.email
                LIMIT 1
            ];

            if(!existingContacts.isEmpty()) {
                response.success = false;
                response.message = 'Email already exists';
                return response;
            }
	
            String passwordHash =
                EncodingUtil.convertToHex(
                    Crypto.generateDigest(
                        'SHA-256',
                        Blob.valueOf(req.password)
                    )
                );
            
            Contact con = new Contact();
            con.FirstName = req.firstName;
            con.LastName = req.lastName;
            con.Email = req.email;
            con.Password__c = req.password;
            con.Password_Hash__c = passwordHash;
            con.BirthDate = req.dob;
            con.Firebase_UID__c = req.uid;
            insert con;

            response.success = true;
            response.message = 'Signup Successful';
            response.contactId = con.Id;

        } catch(Exception e) {

            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    global class SignupRequest {
        public String firstName;
        public String lastName;
        //public String username;
        public String password;
        public String email;
        public Date dob;
        public String uid;
    }

    global class SignupResponse {
        public Boolean success;
        public String message;
        public String contactId;
    }
}