@RestResource(urlMapping='/resetpassword/*')
global without sharing class ResetPasswordAPI {
	
    @HttpPost
    global static ResetResponse resetPassword(){
        
        ResetResponse response = new ResetResponse();
        try{
            
            ResetRequest req = (ResetRequest) JSON.deserialize(RestContext.request.requestBody.toString(), ResetRequest.class);
            System.debug('Received Req : ' + req);
            
            List<Contact> contacts = [
                SELECT Id, Email
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
            
            con.Password__c = req.newPassword;
            
            update con;
            System.debug('Contact Password Updated Successfully !!');
            
            response.success = true;
            response.message = 'Password updated successfully !!';
            response.contactId = con.Id;
            
            return response;
        }
        catch(Exception ex){
            response.success = false;
            response.message = ex.getMessage();
            
            return response;
        }
        
        
    } 
    
    global class ResetRequest{
        public String email;
        public String newPassword;
    }
    
    global class ResetResponse{
        public Boolean success;
        public String message;
        public String contactId;
    }
}