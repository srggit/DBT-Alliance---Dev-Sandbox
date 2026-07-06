@RestResource(urlMapping='/hostInstitution')
global without sharing class HostInstitutionDetailsAPI {
	
    @HttpPost
    global static HostInstitutionResponse insertHostInstituionDetails(){
        
        HostInstitutionResponse response = new HostInstitutionResponse();
        
        try{
            HostInstitutionRequest req = (HostInstitutionRequest) JSON.deserialize(RestContext.request.requestBody.toString(), HostInstitutionRequest.class);
            
			Country__c coun = [SELECT Id, Name FROM Country__c WHERE Name = 'India'];
            
            Account newAcc = new Account();
            newAcc.Name = req.hostInstitutionName;
            newAcc.BillingCity = req.city;
            newAcc.BillingState = req.state;
            newAcc.BillingCountry = req.country;
            newAcc.BillingPostalCode = req.postalCode;
            
            newAcc.Address__c = req.city;
            
            newAcc.City__c = req.city;
            newAcc.BillingState = req.state;
            newAcc.Country__c = coun.Id;
            newAcc.Pincode__c = 560001.00;
            newAcc.Department__c = 'Host Institution';
            newAcc.Institution_Categories__c = 'University';
            
            newAcc.Phone = req.telephoneNumber;
            //newAcc.Email = req.email;
            insert newAcc;
            
            response.success = true;
            response.message = 'Host Institution Details Inserted Successfully !';
            response.hostInstitutionId = newAcc.Id;
            
            return response;
            
        }catch(Exception ex){
            response.success = true;
            response.message = ex.getMessage();
            return response;
        }
    }
    
     global class HostInstitutionRequest {
        public String hostInstitutionName;
        public String city;
        public String district;
        public String state;
        public String country;
        public String postalCode;
		public String telephoneNumber;
		public String email;          
        public String notForProfitInstituition;
    }

    global class HostInstitutionResponse {
        global Boolean success;
        global String message;
        global String hostInstitutionId;
    }
}