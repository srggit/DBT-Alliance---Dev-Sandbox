@RestResource(urlMapping='/academicHistoryDetails')
global without sharing class AcademicHistoryDetailsAPI {

    @HttpPost
    global static ResponseWrapper saveAcademicHistoryDetails() {

        ResponseWrapper response = new ResponseWrapper();

        try {

            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper)JSON.deserialize(requestBody, RequestWrapper.class);

            if (String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required field: applicantId.';
                response.totalInsertedRecords = 0;
                return response;
            }

            Education_Details__c edu = new Education_Details__c();

                edu.Contact__c = req.contactId;
                edu.Institution__c = req.institution;
                edu.Qualification__c = req.degree;
                edu.Subject__c = req.specialization;
                edu.Department_School_Division__c = req.grade;
                edu.Start_Date__c = req.admissionDate;
                edu.End_Date__c = req.passingDate;
                edu.University__c = req.university;
                edu.Pursuing_Higher_Degree__c = req.pursuingHigherDegree;
                edu.Specify_Other_Degree__c = req.otherDegree;
                edu.Specify_the_University__c = req.otherInstitution;

                if (String.isNotBlank(req.educationId)) {
                    edu.Id = req.educationId;
                }
    
            if (edu != null) {
                if (String.isNotBlank(req.educationId)) {
                    update edu;
                    response.success = true;
                    response.message = 'Academic history updated successfully.';
                    response.totalInsertedRecords = 1;
                    response.educationId = edu.Id;
                } else {
                    insert edu;
                    response.success = true;
                    response.message = 'Academic history inserted successfully.';
                    response.totalInsertedRecords = 1;
                    response.educationId = edu.Id;
                }
            }
        }
        catch (Exception ex) {
            response.success = false;
            response.message = 'An error occurred while saving details: ' + ex.getMessage();
            response.totalInsertedRecords = 0;
        }
        return response;
    }

    global class RequestWrapper {
        public String contactId;
        public String educationId;
        public String institution;
        public String degree;
        public String specialization;
        public String grade;
        public Date admissionDate;
        public Date passingDate;
        public String university;
        public String pursuingHigherDegree;
        public String specifyOtherDegree;
        public String otherInstitution;
        public String otherDegree;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public String educationId;
        public Integer totalInsertedRecords;
    }

}

// @RestResource(urlMapping='/academicHistoryDetails')
// global without sharing class AcademicHistoryDetailsAPI {
    
//     @HttpPost
//     global static ResponseWrapper saveAcademicHistoryDetails(){
        
//         ResponseWrapper response = new ResponseWrapper();
        
//         try{
//             String requestBody = RestContext.request.requestBody.toString();
//             RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);
            
//             if(String.isBlank(req.contactId) || req.educationList == null || req.educationList.isEmpty()){
//                 response.success = false;
//                 response.message = 'Missing required fields: contactId or educationList.';
//                 return response;
//             }
            
//             List<Education_Details__c> eduDetailsToInsert = new List<Education_Details__c>();
            
//             for(EducationItem item : req.educationList){
                
//                 Education_Details__c edu = new Education_Details__c();
                
//                 edu.Contact__c = req.contactId;
//                 edu.Start_Date__c = item.fromDate;
//                 edu.End_Date__c = item.toDate;
//                 edu.Qualification__c = item.qualification;
//                 edu.Subject__c = item.subject;
//                 edu.Country__c = item.country;
//                 edu.Institution__c = item.institution;
//                 edu.Department_School_Division__c = item.department;
//                 edu.Supervisor__c = item.supervisor;
//                 edu.Pursuing_Higher_Degree__c = item.pursuingHigherDegree;
//                 edu.Specify_the_pursuing_degree__c = item.specifyHigherDegree;
//                 edu.Likely_date_of_completion__c = item.likelyDateOfCompletion;
//                 edu.Title_of_thesis_Dissertation__c = item.thesisDissertationTitle;
                
//                 eduDetailsToInsert.add(edu);
//             }
            
//             if(! eduDetailsToInsert.isEmpty()){
//                 insert eduDetailsToInsert;
//             }
            
//             response.success = true;
//             response.message = 'Academic history saved successfully.';
//             response.totalInsertedRecords = eduDetailsToInsert.size();
//         }
//         catch(Exception ex){
//             response.success = false;
//             response.message = 'An error occurred while saving details: ' + ex.getMessage();
//             response.totalInsertedRecords = 0;
//         }
        
//         return response;
        
//     }
    
//     global class RequestWrapper {
//         public String contactId;
//         public List<EducationItem> educationList;
//     }
    
//     global class EducationItem {     
//         public Date fromDate;
//         public Date toDate;
//         public String qualification;
//         public String subject;
//         public String country;
//         public String institution;
//         public String department;
//         public String supervisor;        
        
//         public String pursuingHigherDegree;
//         public String specifyHigherDegree;
//         public Date likelyDateOfCompletion;
//         public String thesisDissertationTitle;
//     }

//     global class ResponseWrapper {
//         public Boolean success;
//         public String message;
//         public Integer totalInsertedRecords;
//     }
    

    
    
// }