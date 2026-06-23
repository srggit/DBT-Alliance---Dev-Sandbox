trigger TGR_Grants on Grants__c (after update) {
    if(trigger.isAfter && trigger.isUpdate) {
        //GrantTriggerHandlerClass.sendEmailOnStatusChange(trigger.new, trigger.oldMap);
    }
}