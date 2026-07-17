trigger YearlySchemeTrigger on Yearly_Schemes__c(before insert, before update,after update) {
	YearlySchemeTriggerHandler.validateDuplicateYearScheme(Trigger.new);

	 if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            YearlySchemeTriggerHandler.validateDuplicateYearScheme(Trigger.new);
        }
    }

	 if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            FieldHistoryTrackerUtil.trackChanges(Trigger.new, Trigger.oldMap);

            YearlySchemeTriggerHandler.updateProposalIds(Trigger.newMap, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            NotificationHandler.createNotifications('Yearly_Schemes__c', Trigger.new);
        }
    }
}