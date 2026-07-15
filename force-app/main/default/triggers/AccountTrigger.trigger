trigger AccountTrigger on Account(before insert, before update, after insert, after update) {
	
	if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AccountApprovalHandler.submitForApproval(Trigger.new);
        }
    }
}