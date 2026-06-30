@RestResource(urlMapping='/getEmploymentDetails')
global without sharing class GetEmploymentDetails {


    @HttpGet
    global static ResponseWrapper getEmploymentDetails(){

        ResponseWrapper response = new ResponseWrapper();
        List<EmploymentDetailsWrapper> employmentDetailsWrapperList = new List<EmploymentDetailsWrapper>();

        try {
            RestRequest req = RestContext.request;
            String contactId = req.params.get('contactId');

            if(String.isBlank(contactId)){
                response.success = false;
                response.message = 'Missing required parameter: contactId';
                return response;
            }

            List<Employment_Details__c> employmentDetails = [
                SELECT Id, Name, Start_Date__c, End_Date__c, Organisation__c, Position__c
                FROM Employment_Details__c
                WHERE Contact__c = :contactId
                ORDER BY End_Date__c DESC
            ];

            if(employmentDetails.isEmpty()){
                response.success = false;
                response.message = 'No employment details found';
                return response;
            }
            
            for(Employment_Details__c emp : employmentDetails){
                EmploymentDetailsWrapper employmentDetailsWrapper = new EmploymentDetailsWrapper();
                employmentDetailsWrapper.id = emp.Id;
                employmentDetailsWrapper.organisation = emp.Organisation__c;
                employmentDetailsWrapper.position = emp.Position__c;
                employmentDetailsWrapper.startDate = emp.Start_Date__c;
                employmentDetailsWrapper.endDate = emp.End_Date__c;
                employmentDetailsWrapperList.add(employmentDetailsWrapper);
            }

            response.success = true;
            response.message = 'Employment details fetched successfully';
            response.employmentDetails = employmentDetailsWrapperList;
            return response;
        }
        catch(Exception ex){
            response.success = false;
            response.message = ex.getMessage();
            return response;
        }
    }

    global class ResponseWrapper{
        public Boolean success;
        public String message;
        public List<EmploymentDetailsWrapper> employmentDetailsWrapperList;
    }

    global class EmploymentDetailsWrapper{
        public String id;
        public String organisation;
        public String position;
        public String startDate;
        public String endDate;
    }

}