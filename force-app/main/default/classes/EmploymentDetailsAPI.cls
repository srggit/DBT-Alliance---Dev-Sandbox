@RestResource(urlMapping='/employmentDetails')
global with sharing class EmploymentDetailsAPI {

    @HttpPost
    global static ResponseWrapper saveEmploymentDetails(){

        ResponseWrapper response = new ResponseWrapper();
        
        try{
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if(String.isBlank(req.contactId) || req.employmentList == null || req.employmentList.isEmpty()){
                response.success = false;
                response.message = 'Missing required fields: contactId or employmentList.';
                return response;
            }

            List<Employment_Details__c> empDetailsToInsert = new List<Employment_Details__c>();
            
            for(EmploymentItem item : req.employmentList){

                Employment_Details__c emp = new Employment_Details__c();
                emp.Contact__c = req.contactId;
                emp.Start_Year__c = item.fromDate;
                emp.End_Year_Present__c = item.toDate;
                emp.Organisation__c = item.organisation;
                emp.Position__c = item.position;
                empDetailsToInsert.add(emp);
            }

            if(! empDetailsToInsert.isEmpty()){
                insert empDetailsToInsert;
            }

            response.success = true;
            response.message = 'Employment details saved successfully.';
            response.totalInsertedRecords = empDetailsToInsert.size();
        } catch(Exception ex){
            response.success = false;
            response.message = 'An error occurred: ' + ex.getMessage();
            response.totalInsertedRecords = 0;
        }

        return response;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Integer totalInsertedRecords;
    }

    global class RequestWrapper {
        public String contactId;
        public List<EmploymentItem> employmentList;
    }

    global class EmploymentItem {
        public String fromDate;
        public String toDate;
        public String organisation;
        public String position;
    }
}
/*
@RestResource(urlMapping='/employmentDetails')
global with sharing class EmploymentDetailsAPI {

    @HttpPost
    global static ResponseWrapper saveEmploymentDetails(){

        ResponseWrapper response = new ResponseWrapper();
        
        try{
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if(String.isBlank(req.contactId) || req.employmentList == null || req.employmentList.isEmpty()){
                response.success = false;
                response.message = 'Missing required fields: contactId or employmentList.';
                return response;
            }

            List<Employment_Details__c> empDetailsToInsert = new List<Employment_Details__c>();
            
            for(EmploymentItem item : req.employmentList){

                Employment_Details__c emp = new Employment_Details__c();
                emp.Contact__c = req.contactId;
                emp.Start_Year__c = item.fromDate;
                emp.End_Year_Present__c = item.toDate;
                emp.Organisation__c = item.organisation;
                emp.Position__c = item.position;
                empDetailsToInsert.add(emp);
            }

            if(! empDetailsToInsert.isEmpty()){
                insert empDetailsToInsert;
            }

            response.success = true;
            response.message = 'Employment details saved successfully.';
            response.totalInsertedRecords = empDetailsToInsert.size();
        } catch(Exception ex){
            response.success = false;
            response.message = 'An error occurred: ' + ex.getMessage();
            response.totalInsertedRecords = 0;
        }

        return response;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public Integer totalInsertedRecords;
    }

    global class RequestWrapper {
        public String contactId;
        public List<EmploymentItem> employmentList;
    }

    global class EmploymentItem {
        public String fromDate;
        public String toDate;
        public String organisation;
        public String position;
    }

}
*/