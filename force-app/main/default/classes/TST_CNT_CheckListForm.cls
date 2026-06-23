@isTest
private class TST_CNT_CheckListForm {
    static testMethod void testCheckListForm() {
    	Grants__c testGrant = new Grants__c();
        insert testGrant;
        
        Country__c testCountry = new Country__c();
        insert testCountry;
        
        Account testAcc = new Account();
        testAcc.Name = 'Test Account';
        testAcc.Department__c = 'test';
        testAcc.Country__c = testCountry.Id;
        testAcc.Address__c = 'test';
        testAcc.City__c = 'test';
        testAcc.Pincode__c = 1234;
        testAcc.Institution_Categories__c = 'Hospital';
        insert testAcc;
        
        Investigator__c testInvestigator = new Investigator__c();
        testInvestigator.Investigators_Type__c = 'Principal Investigator';
        testInvestigator.Grants__c = testGrant.Id;
        testInvestigator.Title__c = 'Dr.';
        testInvestigator.First_Name__c = 'test';
        testInvestigator.Last_Name__c = 'test';
        testInvestigator.Discipline_expertise__c = 'test';
        testInvestigator.Institution__c = testAcc.Id;
        testInvestigator.Nationality__c = 'test';
        testInvestigator.Date_of_Birth__c = Date.today();
        testInvestigator.Gender__c = 'Male';
        testInvestigator.Contact_Number__c = 'test';
        testInvestigator.Email__c = 'test@gmail.com';
        testInvestigator.ORCID_ID__c = '1111-2222-3333-4444';
        testInvestigator.Role__c = 'test';
        insert testInvestigator;
        
        Checklist__c testChecklist = new Checklist__c();
        insert testChecklist;
        CNT_CheckListForm.getCurrentChecklist(String.valueOf(testGrant.id));
        CNT_CheckListForm.saveChecklistRecord(testChecklist, 'Submit');
        
        Peer_Review_Checklist__c testReviewChecklist = new Peer_Review_Checklist__c();
        insert testReviewChecklist;
        CNT_CheckListForm.getCurrentReviewChecklist(String.valueOf(testGrant.id));
        CNT_CheckListForm.saveReviewChecklistRecord(testReviewChecklist, 'Save');
        
        Screening_Committee__c testScreeningReview = new Screening_Committee__c();
        insert testScreeningReview;
        CNT_CheckListForm.getCurrentReviewScreening(String.valueOf(testGrant.id));
        CNT_CheckListForm.saveReviewScreeningRecord(testScreeningReview, 'Submit');
        
        testGrant.Status__c = 'Decline';
        update testGrant;
    }
}