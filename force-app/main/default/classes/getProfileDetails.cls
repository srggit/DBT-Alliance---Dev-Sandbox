@RestResource(urlMapping='/getProfileDetails')
global with sharing class getProfileDetails {

    @HttpGet
    global static ResponseWrapper doGet() {

        ResponseWrapper response = new ResponseWrapper();

        try {
            RestRequest req = RestContext.request;
            String contactId = req.params.get('contactId');

            if (String.isBlank(contactId)) {
                response.success = false;
                response.message = 'Contact Id is required';
                return response;
            }

            // ---- Query Contact fields + related Education, Employment & Keywords ----
            List<Contact> contacts = [
                SELECT Id, Title__c, FirstName, LastName, Email, Phone, ReviewerType__c,Title,
                       Position__c, Department, Organisation__r.Name,
                       MailingCountry, MailingState, MailingCity,
                       (SELECT Id, Qualification__c, Institution__c, University__c, Start_Date__c,
                               End_Date__c, Specify_the_University__c, Specify_Other_Degree__c,
                               Specify_the_pursuing_degree__c, Pursuing_Higher_Degree__c,
                               Likely_date_of_completion__c, Title_of_thesis_Dissertation__c,
                               Research_Summary_During_Highest_Degree__c,Division__c, Grade__c
                        FROM Education_Details__r
                        ORDER BY End_Date__c DESC),
                       (SELECT Id, Organisation__c, Position__c, Roles_Responsibilities__c,
                               Start_Date__c, End_Date__c, I_am_currently_working_here__c
                        FROM Employment_Details__r
                        ORDER BY Start_Date__c DESC),
                       (SELECT Id, Keyword_Name__c
                        FROM keywords__r
                        ORDER BY Keyword_Name__c DESC)
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                response.success = false;
                response.message = 'Contact not found';
                return response;
            }

            Contact con = contacts[0];

            // ---- Build wrapper ----
            response.success = true;
            response.message = 'Success';
            response.contactDetails = wrapContact(con);
            response.educationDetails = wrapEducationDetails(con.Education_Details__r);
            response.employmentDetails = wrapEmploymentDetails(con.Employment_Details__r);
            response.keywordDetails = wrapKeywordDetails(con.keywords__r);

        } catch (Exception e) {
            response.success = false;
            response.message = 'Error: ' + e.getMessage();
        }

        return response;
    }

    // ---- Helper: map Contact sObject to typed wrapper ----
    private static ContactWrapper wrapContact(Contact con) {
        ContactWrapper cw = new ContactWrapper();
        cw.id = con.Id;
        cw.title = con.Title__c;
        cw.firstName = con.FirstName;
        cw.lastName = con.LastName;
        cw.email = con.Email;
        cw.phone = con.Phone;
        cw.reviewerType = con.ReviewerType__c;
        cw.position = con.Position__c;
        cw.department = con.Department;
        cw.organisationName = con.Organisation__r?.Name;
        cw.city = con.MailingCity;
        cw.state = con.MailingState;
        cw.country = con.MailingCountry;
        return cw;
    }

    // ---- Helper: map Education_Details__c list to typed wrapper list ----
    private static List<EducationDetailsWrapper> wrapEducationDetails(List<Education_Details__c> records) {
        List<EducationDetailsWrapper> wrappedList = new List<EducationDetailsWrapper>();

        for (Education_Details__c edu : records) {
            EducationDetailsWrapper ew = new EducationDetailsWrapper();
            ew.educationId = edu.Id;
            ew.qualification = edu.Qualification__c;
            ew.institution = edu.Institution__c;
            ew.university = edu.University__c;
            ew.startDate = edu.Start_Date__c;
            ew.endDate = edu.End_Date__c;
            ew.titleOfThesisDissertation = edu.Title_of_thesis_Dissertation__c;
            ew.division = edu.Division__c;
            ew.grade = edu.Grade__c;
            ew.researchSummaryDuringHighestDegree = edu.Research_Summary_During_Highest_Degree__c;
            wrappedList.add(ew);
        }

        return wrappedList;
    }

    // ---- Helper: map Employment_Details__c list to typed wrapper list ----
    private static List<EmploymentDetailsWrapper> wrapEmploymentDetails(List<Employment_Details__c> records) {
        List<EmploymentDetailsWrapper> wrappedList = new List<EmploymentDetailsWrapper>();

        for (Employment_Details__c emp : records) {
            EmploymentDetailsWrapper ew = new EmploymentDetailsWrapper();
            ew.employmentId = emp.Id;
            ew.organisation = emp.Organisation__c;
            ew.position = emp.Position__c;
            ew.description = emp.Roles_Responsibilities__c;
            ew.isCurrentlyWorking = emp.I_am_currently_working_here__c;
            ew.startDate = emp.Start_Date__c;
            ew.endDate = emp.End_Date__c;
            wrappedList.add(ew);
        }

        return wrappedList;
    }

    // ---- Helper: map Keywords__c list to typed wrapper list ----
    private static List<KeywordDetailsWrapper> wrapKeywordDetails(List<Keywords__c> records) {
        List<KeywordDetailsWrapper> wrappedList = new List<KeywordDetailsWrapper>();

        for (Keywords__c ky : records) {
            KeywordDetailsWrapper kw = new KeywordDetailsWrapper();
            kw.keywordDetailId = ky.Id;
            kw.keywordName = ky.Keyword_Name__c;
            wrappedList.add(kw);
        }

        return wrappedList;
    }

    // ---- Wrapper classes ----
    global class ResponseWrapper {
        global Boolean success;
        global String message;
        global ContactWrapper contactDetails;
        global List<EducationDetailsWrapper> educationDetails;
        global List<EmploymentDetailsWrapper> employmentDetails;
        global List<KeywordDetailsWrapper> keywordDetails;
    }

    global class ContactWrapper {
        global String id;
        global String title;
        global String firstName;
        global String lastName;
        global String email;
        global String phone;
        global String reviewerType;
        global String position;
        global String department;
        global String organisationName;
        global String city;
        global String state;
        global String country;
        // PLACEHOLDER: additional fields
    }

    global class EducationDetailsWrapper {
        global String educationId;
        global String qualification;
        global String institution;
        global String university;
        global Date startDate;
        global Date endDate;
        global String division;
        global Decimal grade;
        global Date likelyDateOfCompletion;
        global String titleOfThesisDissertation;
        global String researchSummaryDuringHighestDegree;
    }

    global class EmploymentDetailsWrapper {
        global String employmentId;
        global String organisation;
        global String position;
        global String description;
        global Boolean isCurrentlyWorking;
        global Date startDate;
        global Date endDate;
    }

    global class KeywordDetailsWrapper {
        global String keywordDetailId;
        global String keywordName;
    }
}