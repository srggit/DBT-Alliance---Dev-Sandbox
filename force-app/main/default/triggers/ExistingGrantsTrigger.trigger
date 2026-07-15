trigger ExistingGrantsTrigger on Existing_Grants__c(before insert, before update, after insert, after update) {
	if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            FieldHistoryTrackerUtil.trackChanges(Trigger.new, Trigger.oldMap);
        }
    }
}