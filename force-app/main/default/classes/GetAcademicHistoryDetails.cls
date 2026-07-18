@RestResource(urlMapping='/getAcademicHistoryDetails')
global without sharing class GetAcademicHistoryDetails {

    @HttpGet
    global static ResponseWrapper getAcademicHistoryDetails(){

        ResponseWrapper response = new ResponseWrapper();
        List<EducationDetailsWrapper> educationDetailsWrapperList = new List<EducationDetailsWrapper>();

        try {
            RestRequest req = RestContext.request;
            String contactId = req.params.get('contactId');

            if(String.isBlank(contactId)){
                response.success = false;
                response.message = 'Missing required parameter: contactId';
                return response;
            }
            System.debug('contactId : ' + contactId);

            List<Education_Details__c> educationDetails = [
                SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c, Department_School_Division__c, 
                Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c, University__c
                FROM Education_Details__c
                WHERE Contact__c = :contactId
                ORDER BY End_Date__c DESC
            ];

            if(educationDetails.isEmpty()){
                response.success = false;
                response.message = 'No education details found';
                return response;
            }

            for(Education_Details__c edu : educationDetails){
                EducationDetailsWrapper eduWrapper = new EducationDetailsWrapper();
                eduWrapper.qualification = edu.Qualification__c;
                eduWrapper.subject = edu.Subject__c;
                eduWrapper.country = edu.Country__c;
                eduWrapper.institution = edu.Institution__c;
                eduWrapper.department = edu.Department_School_Division__c;
                eduWrapper.supervisor = edu.Supervisor__c;
                eduWrapper.thesisDissertationTitle = edu.Title_of_thesis_Dissertation__c;
                eduWrapper.yearOfAward = edu.End_Date__c;
                eduWrapper.university = edu.University__c;
                educationDetailsWrapperList.add(eduWrapper);
            }

            response.success = true;
            response.message = 'Education details fetched successfully';
            response.educationDetails = educationDetailsWrapperList;
            return response;
        } catch (Exception ex) {
            response.success = false;
            response.message = 'An error occurred while fetching education details: ' + ex.getMessage();
            return response;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<EducationDetailsWrapper> educationDetails;
    }

    global class EducationDetailsWrapper {
        public String qualification;
        public String subject;
        public String country;
        public String institution;
        public String department;
        public String supervisor;
        public String thesisDissertationTitle;
        public Date yearOfAward;
        public String university;
    }
}