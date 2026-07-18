@RestResource(urlMapping='/notificationMarkSeenAPI')
global with sharing class notificationMarkSeenAPI {

    @HttpPost
    global static ResponseWrapper markNotificationSeen() {

        ResponseWrapper response = new ResponseWrapper();

        try {

            MarkSeenRequest input = (MarkSeenRequest)JSON.deserialize(
                RestContext.request.requestBody.toString(),
                MarkSeenRequest.class
            );

            if (String.isBlank(input.contactId) ||
                input.notificationId == null ||
                input.notificationId.isEmpty()) {

                response.success = false;
                response.message = 'contactId and notificationId are required';
                return response;
            }

            List<Notification_Status__c> statusRecords = [
                SELECT Id, Status__c
                FROM Notification_Status__c
                WHERE Contact__c = :input.contactId
                AND Id IN :input.notificationId 
            ];

            if (!statusRecords.isEmpty()) {

                for (Notification_Status__c ns : statusRecords) {
                    ns.Status__c = 'Read';
                }

                update statusRecords;
            }

            response.success = true;
            response.message = statusRecords.size() + ' notification(s) marked as read.';

        } catch (Exception e) {

            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    // Response Wrapper
    global class ResponseWrapper {
        public Boolean success;
        public String message;
    }

    // Request Wrapper
    global class MarkSeenRequest {
        public String contactId;
        public List<String> notificationId;
    }
}