trigger EducationDetailTrigger on Education_Details__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
       // TriggerHandlerforEducation.handleAfterInsert(Trigger.new);
        GenericApplicantAssociationHandler.handleAfterInsert(
            'Education_Details__c',
            Trigger.new
        );
    }
}