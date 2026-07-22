@IsTest
private class ReviewerController_Test {
    @IsTest
    static void getReviewerContactsReturnsOnlyReviewerRecordType() {
        Id reviewerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Reviewer')?.getRecordTypeId();
        if (reviewerRecordTypeId == null) {
            return;
        }

        Contact reviewer = new Contact(
            FirstName = 'Test',
            LastName = 'Reviewer',
            Email = 'testreviewer@example.com',
            RecordTypeId = reviewerRecordTypeId
        );
        insert reviewer;

        Test.startTest();
        List<Contact> results = ReviewerController.getReviewerContacts();
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Expected at least one reviewer contact');
        System.assertEquals(reviewer.Id, results[0].Id, 'Expected the reviewer contact to be returned');
    }

    @IsTest
    static void createReviewerMappingsCreatesRecordsForSelectedContacts() {
        Contact reviewer = new Contact(
            FirstName = 'Test',
            LastName = 'ReviewerMapping',
            Email = 'testmapping@example.com'
        );
        insert reviewer;

        Proposal__c proposal = new Proposal__c(
            Project_Title__c = 'Test Proposal'
        );
        insert proposal;

        Test.startTest();
        ReviewerController.createReviewerMappings(proposal.Id, new List<Id>{ reviewer.Id });
        Test.stopTest();

        List<Reviewer_Mapping__c> mappings = [
            SELECT Id, Contact__c, Proposal__c
            FROM Reviewer_Mapping__c
            WHERE Proposal__c = :proposal.Id
        ];
        System.assertEquals(1, mappings.size(), 'Expected one reviewer mapping to be created');
        System.assertEquals(reviewer.Id, mappings[0].Contact__c, 'Expected mapping to reference selected contact');
        System.assertEquals(proposal.Id, mappings[0].Proposal__c, 'Expected mapping to reference proposal');
    }
}