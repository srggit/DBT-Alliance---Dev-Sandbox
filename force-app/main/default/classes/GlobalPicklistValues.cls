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
    }
    
    global class FieldResult {
        public String status;
        public String errorMessage;
        public List<String> values;
    }   
}