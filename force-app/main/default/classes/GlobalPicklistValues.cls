@RestResource(urlMapping='/getGlobalPicklistValues')
global without sharing class GlobalPicklistValues {
	
    @HttpGet
    global static ResponseWrapper getPicklistValues(){
        
        ResponseWrapper response = new ResponseWrapper();
        
        Contact.Nationality__c.getDescribe();
        
        Schema.DescribeFieldResult nationalityFieldResult = Contact.Nationality__c.getDescribe();
        response.nationalityValues = getSafePicklistValues(nationalityFieldResult);
        
        Schema.DescribeFieldResult institutionCategoriesFieldResult = Account.Institution_Categories__c.getDescribe();
		response.institutionalCategoriesValues = getSafePicklistValues(institutionCategoriesFieldResult);

        Schema.DescribeFieldResult titleFieldResult = Contact.Title__c.getDescribe();
        response.titleFieldResultValues = getSafePicklistValues(titleFieldResult);

        Schema.DescribeFieldResult rolesFieldResult = Proposal_Participant_Association__c.Roles__c.getDescribe();
        response.rolesValues = getSafePicklistValues(rolesFieldResult);


        Map<String, String> accountMap = new Map<String, String>();
        for (Account acc : [ SELECT Id, Name FROM Account Where Organization_Status__c='Listed'
                             ORDER BY Name]) {
            accountMap.put(acc.Id, acc.Name);
        }
        response.accounts = accountMap;

        return response;
    }
    
    
    private static FieldResult getSafePicklistValues(Schema.DescribeFieldResult fieldDescribe){
        
        FieldResult result = new FieldResult();
        
        try{    
            List<String> activeValues = new List<String>();

            List<Schema.PicklistEntry> nList = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : nList) {
                if (pickListVal.isActive()) {
                    activeValues.add(pickListVal.getLabel()); // Use getValue() for API names
                }
            }
            
            result.status = 'Success';
            result.values = activeValues;
            
        }catch(Exception ex){
            result.status = 'Error';
            result.errorMessage = 'Error fetching picklist values: ' + ex.getMessage();
        }
        
        return result;
    }
    
    global class ResponseWrapper {
        public FieldResult nationalityValues;
        public FieldResult institutionalCategoriesValues;
        public FieldResult titleFieldResultValues;
        public FieldResult rolesValues;
        public Map<String, String> accounts;
    }
    
    global class FieldResult {
        public String status;
        public String errorMessage;
        public List<String> values;
    }   
}