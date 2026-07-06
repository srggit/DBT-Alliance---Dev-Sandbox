trigger YearlySchemeTrigger on Yearly_Schemes__c(before insert, before update) {
	YearlySchemeTriggerHandler.validateDuplicateYearScheme(Trigger.new);
}