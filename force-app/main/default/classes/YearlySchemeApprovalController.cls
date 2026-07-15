public with sharing class YearlySchemeApprovalController {

    @AuraEnabled
    public static void submitForApproval(Id recordId){

        Approval.ProcessSubmitRequest req =
            new Approval.ProcessSubmitRequest();

        req.setObjectId(recordId);

        Approval.ProcessResult result =
            Approval.process(req);

        if(!result.isSuccess()){
            throw new AuraHandledException('Unable to submit for approval.');
        }
    }
}