@RestResource(urlMapping='/getContactWithEmail')
global with sharing class getContactWithEmail {

    @HttpGet
    global static ResponseWrapper doGet() {

        ResponseWrapper response = new ResponseWrapper();

        try {
            RestRequest req = RestContext.request;
            String email = req.params.get('email');

            if (String.isBlank(email)) {
                response.exists = false;
                response.message = 'Email is required';
                response.reviwerId = null;
                return response;
            }

            // ---- Case-insensitive email match ----
            List<Reviewer__c> reviwers = [
                SELECT Id
                FROM Reviewer__c
                WHERE Email_Address__c = :email
                LIMIT 1
            ];

            if (!reviwers.isEmpty()) {
                response.exists = true;
                response.message = 'Reviewer exist';
                response.reviwerId = reviwers[0].Id;
            } else {
                response.exists = false;
                response.message = 'Reviewer do not Exist';
                response.reviwerId = null;
            }

        } catch (Exception e) {
            response.exists = false;
            response.message = 'Error: ' + e.getMessage();
            response.reviwerId = null;
        }

        return response;
    }

    // ---- Wrapper class ----
    global class ResponseWrapper {
        global Boolean exists;
        global String message;
        global String reviwerId;
    }
}