trigger EmploymentDetailTrigger on Employment_Details__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        GenericApplicantAssociationHandler.handleAfterInsert(
            'Employment_Details__c',
            Trigger.new
        );
    }

}