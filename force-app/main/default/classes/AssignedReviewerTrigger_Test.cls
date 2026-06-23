@isTest
public class AssignedReviewerTrigger_Test {
    public static testMethod void testOne(){
        Grants__c gnt= new Grants__c();
        gnt.Comments__c='Teting Sample';
        insert gnt;
        
        Assigned_Reviewer__c ar = new Assigned_Reviewer__c();
        ar.Assigned_User__c=userinfo.getuserId();
        ar.Grants__c=gnt.Id;
        insert ar;
        
        Assigned_Reviewer__c ar2 = new Assigned_Reviewer__c(id=ar.ID);
        ar2.Assigned_User__c=userinfo.getuserId();
        ar2.Grants__c=gnt.Id;
        delete ar2;
        
        undelete ar2;
    }
}