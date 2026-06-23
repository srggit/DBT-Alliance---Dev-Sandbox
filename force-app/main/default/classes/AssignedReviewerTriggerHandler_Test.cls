@isTest
public class AssignedReviewerTriggerHandler_Test {
    String profileName;
    public static testMethod void sampleTest(){
        Grants__c gnt= new Grants__c();
        gnt.Comments__c='Teting Sample';
        gnt.Date__c=system.today();
        insert gnt;
        
        Grants__c gnt1= new Grants__c();
        gnt1.Comments__c='Teting Sample';
        gnt1.Date__c=system.today();
        insert gnt1;
        
        ID adminProfileID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].ID;
        
        user u= new user();
        u.Title__c='Professor';
        u.FirstName='abhi';
        u.Date_of_Birth__c=Date.newInstance(2000, 1, 23);
        u.Nationality__c='India';
        u.Expertise__c='ans';
        u.Position__c='sales';
        u.Department__c='item';
        u.Gender__c='male';
        u.Organisation__c='hs';
        u.Address__c='hds';
        u.City__c='bundi';
        u.Countries__c='india';
        u.Postal_Code__c='560030';
        u.International_Dialing_Code__c=90.39;
        u.Phone='9933832822';
        u.Alias = 'firstusr';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Username='saket.sharma48d@gmail.com	';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com	';
        u.ProfileId =adminProfileID;
        insert u;
        Assigned_Reviewer__c ar = new Assigned_Reviewer__c();
        ar.Assigned_User__c=u.Id;
        ar.Grants__c=gnt.Id;
        insert ar; 
        ar.Grants__c=gnt1.Id;
        update ar;
        delete ar;
        undelete ar;
        
        //AssignedReviewerTriggerHandler at= new AssignedReviewerTriggerHandler();
        //at.checkDuplicateUser();
        AssignedReviewerTriggerHandler.manualShareRead(gnt.Id, u.Id);
    }
}