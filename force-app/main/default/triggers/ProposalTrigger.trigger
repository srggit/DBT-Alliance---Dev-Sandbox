trigger ProposalTrigger on Proposal__c(before insert, before update, after insert, after update) {
	if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            FieldHistoryTrackerUtil.trackChanges(Trigger.new, Trigger.oldMap);
        }
    }
     if (Trigger.isAfter && Trigger.isInsert) {
      //  ProposalTriggerHandler.generateProposalId(Trigger.newMap.keySet());
    }
}