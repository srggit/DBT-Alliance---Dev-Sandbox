trigger EmploymentDetailTrigger on Employment_Details__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        GenericApplicantAssociationHandler.syncAssociationRecords(
            'Employment_Details__c',
            Trigger.new
        );
    }

}