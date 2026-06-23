@isTest
public class Peer_Review_SelectionCTRLTest{
    @testSetup static void methodName() {
        EmailTemplate et = new EmailTemplate(); 
        et.isActive = true; 
        et.Name = 'testTemplate'; 
        et.DeveloperName = 'testTemplate' + System.now().getTime(); 
        et.TemplateType = 'text'; 
        et.FolderId = UserInfo.getUserId(); 
        et.Body = 'test'; 
        
        insert et; 
    }
    @isTest
    public static void unitTest(){
        
        Grants__c gnt= new Grants__c();
        gnt.Comments__c='Teting Sample';
        insert gnt;
        
        Peer_Reviewer__c pr = new Peer_Reviewer__c(First_Name__c = 't' , Last_Name__c = 'l', Email__c = 'test@gmail.com');
        insert pr;
        Peer_Review_SelectionCTRL obj = new Peer_Review_SelectionCTRL();
        
        obj.selectedTemplate = [SELECT Id FROM EmailTemplate LIMIT 1].Id;
        obj.selectedPeerReviewerId = pr.Id;
        
        obj.getTemplates() ;
        
        obj.fatchGrantRecords();
        
        obj.selectGrantRecord();
        obj.previous();
        obj.changeEvent();
        for(Peer_Review_SelectionCTRL.Option op : obj.peerReviewerOption ){
            op.isSelected = true;
        }
        obj.next();
        for(Peer_Review_SelectionCTRL.Option  o : obj.grantRecordList){
            o.isSelected = true;
        }
        obj.nextToTemplateView();
        obj.changeEventNext();
        obj.submit();
        obj.previousToTemplateView();
    }
}