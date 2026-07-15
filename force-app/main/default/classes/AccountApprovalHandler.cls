public class AccountApprovalHandler {

    public static void submitForApproval(List<Account> accounts) {

        for (Account acc : accounts) {

            if (acc.Organization_Status__c == 'Under Approval') {

                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(acc.Id);
                // Uncomment if you have multiple approval processes
                 req.setProcessDefinitionNameOrId('Account_approval');              

                Approval.ProcessResult result = Approval.process(req);

                if (!result.isSuccess()) {
                    System.debug('Approval submission failed: ' + result.getErrors()[0].getMessage());
                }
            }
        }
    }
}