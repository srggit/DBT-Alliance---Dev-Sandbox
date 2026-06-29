@RestResource(urlMapping='/login/*')
global without sharing class LoginAPI {

    @HttpPost
    global static LoginResponse login() {

        LoginResponse response = new LoginResponse();

        try {
			// RestRequest request = RestContext.request;
            // LoginRequest req = (LoginRequest) JSON.deserialize(request.requestBody.toString(), LoginRequest.class);
            
            LoginRequest req = (LoginRequest) JSON.deserialize(RestContext.request.requestBody.toString(), LoginRequest.class);
			System.debug('req : ' + req);
            
            System.debug('Current User = ' + UserInfo.getUserName());
            System.debug('User Id => ' + UserInfo.getUserId());
            System.debug('User Type => ' + UserInfo.getUserType());
			            
            List<Contact> contacts = [
                SELECT Id, FirstName, LastName, Email, Password__c, Password_Hash__c
                FROM Contact
                WHERE Email = :req.email
              	LIMIT 1
            ]; 
            System.debug('contacts : ' + contacts);

            if(contacts.isEmpty()) {
                response.success = false;
                response.message = 'User not found';

                return response;
            }

            Contact con = contacts[0];
	
            String incomingHash =
                EncodingUtil.convertToHex(
                    Crypto.generateDigest(
                        'SHA-256',
                        Blob.valueOf(req.password)
                    )                );
		
            if(con.Password_Hash__c != incomingHash) {

                response.success = false;
                response.message = 'Invalid Password';

                return response;
            }

            response.success = true;
            response.message = 'Login Successful';
            response.contactId = con.Id;
            response.name = con.FirstName + ' ' + con.LastName;

        } catch(Exception e) {

            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    global class LoginRequest {
        public String email;
        public String password;
    }

    global class LoginResponse {
        public Boolean success;
        public String message;
        public String contactId;
        public String name;
    }
}