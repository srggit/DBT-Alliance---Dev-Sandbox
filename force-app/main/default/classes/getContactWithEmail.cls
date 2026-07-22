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
                response.contactId = null;
                return response;
            }

            // ---- Case-insensitive email match ----
            List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE Email = :email
                LIMIT 1
            ];

            if (!contacts.isEmpty()) {
                response.exists = true;
                response.message = 'Contact exist';
                response.contactId = contacts[0].Id;
            } else {
                response.exists = false;
                response.message = 'Contact do not Exist';
                response.contactId = null;
            }

        } catch (Exception e) {
            response.exists = false;
            response.message = 'Error: ' + e.getMessage();
            response.contactId = null;
        }

        return response;
    }

    // ---- Wrapper class ----
    global class ResponseWrapper {
        global Boolean exists;
        global String message;
        global String contactId;
    }
}