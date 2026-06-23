public class AssignReviewerController{
    
    @AuraEnabled
    public static SharingSettiing init(String recordId){
        List<Assigned_Reviewer__c> Assigned_ReviewerList = [SELECT Id, Name, Assigned_User__r.Name, Grants__c FROM Assigned_Reviewer__c WHERE Grants__c = : recordId];
        SharingSettiing ss = new SharingSettiing(Assigned_ReviewerList);
        return ss;
    }
    
    public class SharingSettiing{
        @AuraEnabled
        public List<Assigned_Reviewer__c> Assigned_ReviewerList;
        
        public SharingSettiing(List<Assigned_Reviewer__c> Assigned_ReviewerList){
            this.Assigned_ReviewerList = Assigned_ReviewerList;
        }
    }
    
    @AuraEnabled
    public static boolean apexDeleteRecord(String recordId){
        if(string.isNotBlank(recordId)){
            Id id = recordId;
            String ObjectName = id.getSObjectType()+'';
            sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
            sObj.put('Id',recordId);
            delete sObj; 
            return true;
        }
        return false;
    }
}