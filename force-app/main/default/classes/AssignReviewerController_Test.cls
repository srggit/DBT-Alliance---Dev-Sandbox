@isTest
public class AssignReviewerController_Test {
    public static testmethod void sampleTest(){
        Grants__c gnt= new Grants__c();
        gnt.Comments__c='Teting Sample';
        insert gnt;
        
        Grants__c gnt1= new Grants__c();
        gnt1.Comments__c='Teting Sample';
        gnt1.Date__c=system.today();
        insert gnt1;
      //  delete gnt1;
        
        Assigned_Reviewer__c ar = new Assigned_Reviewer__c();
        ar.Assigned_User__c=ar.Id;
        ar.Grants__c=gnt.Id;
        insert ar;
        AssignReviewerController.init(ar.Id);
        AssignReviewerController.apexDeleteRecord(gnt1.Id);
        
    }
    
}