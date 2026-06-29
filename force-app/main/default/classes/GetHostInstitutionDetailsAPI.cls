@RestResource(urlMapping='/getHostInstitutionDetails')
global without sharing class GetHostInstitutionDetailsAPI {
    
    @HttpGet
    global static ResponseWrapper getHostInstitutionDetails(){
        
        ResponseWrapper response = new ResponseWrapper();
        
        RestRequest req = RestContext.request;
        String hostAccountId = req.params.get('hostAccountId');
        
        if(String.isBlank(hostAccountId)){
            response.success = false;
            response.message = 'Missing required parameter: hostAccountId';
            return response;
        }
        
        try{
            List<Account> lstAccounts = [
                SELECT Id, Name, Type, Email__c, Phone, Website,
                Address__c, City__c, Country__c, Pincode__c, Department__c, Institution_Categories__c,
                BillingCity, BillingState, BillingCountry, BillingPostalCode
                FROM Account
                WHERE Id = :hostAccountId
            ];
            System.debug('## Account Found : ' + lstAccounts);
            
            Account acc = lstAccounts[0];
            
            response.success = true;
            response.message = 'Host account record found.';
            response.hostAccountId = acc.Id;
            response.hostInstitutionName = acc.Name;
            response.city = acc.BillingCity;
            // response.district 
            response.state = acc.BillingState;
            response.country = acc.BillingCountry;
            response.postalCode = acc.BillingPostalCode;
            response.telephoneNumber = acc.Phone;
            response.email = acc.Email__c;
            //response.notForProfitInstituition;
            
        }catch(QueryException e){
            response.success = false;
            response.message = 'Host account record not found.';
            
        }catch(Exception e){
            response.success = false;
            response.message = 'An error occurred: ' + e.getMessage();
        }
        
        return response;
    }
	
    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public String hostAccountId;
        
        public String hostInstitutionName;
        public String city;
        public String district;
        public String state;
        public String country;
        public String postalCode;
		public String telephoneNumber;
		public String email;          
        public Boolean notForProfitInstituition;
    }
}