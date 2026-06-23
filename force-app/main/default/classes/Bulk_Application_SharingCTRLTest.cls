@isTest
public class Bulk_Application_SharingCTRLTest{
    @isTest
    public static void unitTest(){
        Grants__c g = new Grants__c();
        insert g;
        Bulk_Application_SharingCTRL obj = new Bulk_Application_SharingCTRL();
        integer i = 0;
        for(Bulk_Application_SharingCTRL.Option op : obj.profileList){
            if(i < 5) op.isSelected = true;
            
            i ++;
        }
        obj.setupUserMenu();
        obj.profileSelectAll = true;
        obj.selectAllProfile();
        
        obj.userSelectAll = true;
        obj.selectAllUser();
        
        i = 0;
        for(Bulk_Application_SharingCTRL.Option op : obj.profileList){
            op.isSelected = false;
            if(i < 1) op.isSelected = true;
            
            i ++;
        }
        obj.setupSelectAllUser();
        obj.profileUserNext();
        
        obj.userSelectNextAll = true;
        obj.nSelectAllUserAction();
        obj.grantSelectAll= true;
        obj.nSelectAllGrantAction();
        obj.profileUserPrevious();
        
        i = 0;
        for(Bulk_Application_SharingCTRL.Option op : obj.selectedUserOptionList){
            op.isSelected = false;
            if(i < 1) op.isSelected = true;
            
            i ++;
        }
        obj.nSelectUserAll();
        
        i = 0;
        for(Bulk_Application_SharingCTRL.Option op : obj.grantOptionList){
            op.isSelected = false;
            if(i < 1) op.isSelected = true;
            
            i ++;
        }
        obj.setupSelectAllGrant();
        
        obj.userSelectNextAll = true;
        obj.nSelectAllUserAction();
        obj.assignUserSetting();
        obj.recordId = g.Id;
        obj.apexDeleteRecord();
    }
}