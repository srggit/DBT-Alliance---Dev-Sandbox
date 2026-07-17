trigger EducationDetailTrigger on Education_Details__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Handler respects GenericApplicantAssociationHandler.bypassAssociationSync
        // (set by APIs that insert both APA-tagged and Contact-tagged records themselves)

        GenericApplicantAssociationHandler.syncAssociationRecords(
            'Education_Details__c',
            Trigger.new
        );
    }
}