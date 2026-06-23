@isTest
public class PeerReviewerApprovalVFController_Test {
    String profileName;
    public static testMethod void testingMethod(){
        
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
        u.Username='saket.sharma48d@gmail.com   ';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com    ';
        u.ProfileId =adminProfileID;
        insert u;
        
        Peer_Reviewer__c pr = new Peer_Reviewer__c();
        pr.First_Name__c='Masthan';
        pr.Last_Name__c='Vali';
        pr.Email__c='masthanvali@gmail.com';
        pr.Designation__c='Peer Reviewers';
        pr.Verified_by_User__c=false;
        //pr.Grant_Id_Selected__c='Testing masthan';
        pr.Declined__c=true;
        pr.Created_User__c=u.Id;
        insert pr;
        
        PeerReviewerApprovalVFController pa= new PeerReviewerApprovalVFController();
        pa.reviewRecordId=pr.Id;
        pa.acceptTerms();
        pa.declined();
        
    }
}