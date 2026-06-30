@RestResource(urlMapping='/getActiveSchemes')
global without sharing class GetAllSchemes {
    
    @HttpGet
    global static ResponseWrapper getAllSchemes(){

        List<SchemeWrapper> schemesWrapper = new List<SchemeWrapper>();
        ResponseWrapper response = new ResponseWrapper();

        try {
            List<Scheme__c> schemes = [
                SELECT Id, Name, Scheme_Type__c, Duration__c, Outcome__c, Total_Requested_Amount__c, Status__c, Start_Date__c, End_Date__c, 
                Extension__c
                FROM Scheme__c 
                WHERE Status__c = 'Open' 
                AND End_Date__c >=: System.today() 
            ];

            if(schemes.isEmpty()){
                response.status = 'Error';
                response.message = 'No schemes found';
                response.success = false;
                return response;
            }

            for(Scheme__c scheme : schemes){
                SchemeWrapper schemeWrapper = new SchemeWrapper();
                schemeWrapper.schemeId = scheme.Id;
                schemeWrapper.schemeName = scheme.Name;
                schemeWrapper.schemeType = scheme.Scheme_Type__c;
                schemeWrapper.duration = scheme.Duration__c;
                schemeWrapper.outcome = scheme.Outcome__c;
                schemeWrapper.startDate = scheme.Start_Date__c;
                schemeWrapper.endDate = scheme.End_Date__c;
                schemeWrapper.extension = scheme.Extension__c;
                schemesWrapper.add(schemeWrapper);
            }
            response.schemes = schemesWrapper;
            response.status  = 'Success';
            response.message = 'Schemes fetched successfully';
            response.success = true;
            return response;
        }
        catch(Exception ex){
            response.status = 'Error';
            response.message = 'An error occurred while fetching schemes: ' + ex.getMessage();
            response.success = false;
            return response;
        }
    }
    

    global class ResponseWrapper {
        public List<SchemeWrapper> schemes;
        public String status;
        public String message;
        public Boolean success;
    }

    global class SchemeWrapper {
        public String schemeId;
        public String schemeName;
        public String schemeType;
        public Decimal duration;
        public String outcome;
        public Date startDate;
        public Date endDate;
        public String extension;
    }
}