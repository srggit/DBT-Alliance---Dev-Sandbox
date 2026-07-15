trigger PublicationsTrigger on Publications__c(before insert, before update, after update, after insert) {
	if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            FieldHistoryTrackerUtil.trackChanges(Trigger.new, Trigger.oldMap);
        }
    }
}