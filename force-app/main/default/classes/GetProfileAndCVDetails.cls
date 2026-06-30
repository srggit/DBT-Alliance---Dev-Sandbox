@RestResource(urlMapping='/getProfileAndCVDetails')
global without sharing class GetProfileAndCVDetails {

    @HttpGet
    global static ResponseWrapper getProfileAndCVDetails(){

        ResponseWrapper response = new ResponseWrapper();
        List<EducationDetailsWrapper> educationDetailsWrapperList = new List<EducationDetailsWrapper>();
        List<EmploymentDetailsWrapper> employmentDetailsWrapperList = new List<EmploymentDetailsWrapper>();

        RestRequest req = RestContext.request;
        String email = req.params.get('email');
        String contactId = req.params.get('contactId');

        if(String.isBlank(email) && String.isBlank(contactId)){
            response.success = false;
            response.message = 'Missing required parameter: email or contactId';
            return response;
        }
        System.debug('email : ' + email);
        System.debug('contactId : ' + contactId);

        try {
            List<Contact> contacts = [
                SELECT Id, Title, Title__c, FirstName, LastName, Phone, Email, BirthDate, Position__c, Department, MailingCity, 
                MailingState, MailingCountry, MailingPostalCode, AccountId, Account.Name,
                    (SELECT Id, Qualification__c, Subject__c, Country__c, Institution__c, Department_School_Division__c, 
                    Supervisor__c, Title_of_thesis_Dissertation__c, End_Date__c
                    FROM Education_Details__r ORDER BY End_Date__c DESC),
                    (SELECT Id, Name, Start_Date__c, End_Date__c, Organisation__c, Position__c
                    FROM Employment_Details__r ORDER BY End_Date__c DESC)
                FROM Contact 
                WHERE (Email = :email OR Id = :contactId)
                LIMIT 1
            ];

            if(contacts.isEmpty()){
                response.success = false;
                response.message = 'Contact not found';
                return response;
            }
            
            Contact con = contacts[0];
            ProfileDetailsWrapper profileDetailsWrapper = new ProfileDetailsWrapper();
            profileDetailsWrapper.title = con.Title;
            profileDetailsWrapper.firstName = con.FirstName;
            profileDetailsWrapper.lastName = con.LastName;
            profileDetailsWrapper.mobileNuber = con.Phone;
            profileDetailsWrapper.email = con.Email;
            profileDetailsWrapper.dob = con.BirthDate;
            profileDetailsWrapper.currentOrg = con.Account?.Name;
            profileDetailsWrapper.currentPosition = con.Position__c;
            profileDetailsWrapper.department = con.Department;
            profileDetailsWrapper.contactId = con.Id;

            for(Education_Details__c edu : con.Education_Details__r){
                EducationDetailsWrapper educationDetailsWrapper = new EducationDetailsWrapper();
                educationDetailsWrapper.educationId = edu.Id;
                educationDetailsWrapper.qualification = edu.Qualification__c;
                educationDetailsWrapper.institution = edu.Institution__c;
                educationDetailsWrapper.yearOfAward = edu.End_Date__c;
                educationDetailsWrapper.thesisDissertationTitle = edu.Title_of_thesis_Dissertation__c;
                educationDetailsWrapperList.add(educationDetailsWrapper);
            }

            for(Employment_Details__c emp : con.Employment_Details__r){
                EmploymentDetailsWrapper employmentDetailsWrapper = new EmploymentDetailsWrapper();
                employmentDetailsWrapper.employmentId = emp.Id;
                employmentDetailsWrapper.organisation = emp.Organisation__c;
                employmentDetailsWrapper.position = emp.Position__c;
                employmentDetailsWrapper.startDate = emp.Start_Date__c;
                employmentDetailsWrapper.endDate = emp.End_Date__c;
                employmentDetailsWrapperList.add(employmentDetailsWrapper);
            }
            
            response.success = true;
            response.message = 'Profile and CV details fetched successfully.';
            response.profileDetails = profileDetailsWrapper;
            response.educationDetails = educationDetailsWrapperList;
            response.employmentDetails = employmentDetailsWrapperList;
            return response;
            
        } catch (QueryException e) {
            response.success = false;
            response.message = 'Contact record not found.';
            return response;
        } catch (Exception ex) {
            response.success = false;
            response.message = 'An error occurred: ' + ex.getMessage();
            return response;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public ProfileDetailsWrapper profileDetails;
        public List<EducationDetailsWrapper> educationDetails;
        public List<EmploymentDetailsWrapper> employmentDetails;
    }   

    global class ProfileDetailsWrapper{
        public String contactId;
        public String title;
        public String firstName;
        public String lastName;
        public String mobileNuber;
        public String email;
        public Date dob;
        
        public String currentOrg;	// Account
        public String currentPosition;
        public String department;
    }

    global class EducationDetailsWrapper {
        public String educationId;
        public String qualification;
        public String subject;
        public String country;
        public String institution;
        public String department;
        public String supervisor;
        public String thesisDissertationTitle;
        public Date yearOfAward;
    }

    global class EmploymentDetailsWrapper {
        public String employmentId;
        public String organisation;
        public String position;
        public Date startDate;
        public Date endDate;
        public String description;
    }
}