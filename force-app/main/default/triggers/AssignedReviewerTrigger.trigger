trigger AssignedReviewerTrigger on Assigned_Reviewer__c (before insert, before update, after insert, after update, after delete, after undelete) {
    if(trigger.isBefore){
        if(trigger.isInsert || trigger.isUpdate){
            new AssignedReviewerTriggerHandler().checkDuplicateUser();
        }
    }
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate || trigger.isDelete|| trigger.isUndelete){
            new AssignedReviewerTriggerHandler().createManualSharing();
        }
    }
}