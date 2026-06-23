public class AssignedReviewerTriggerHandler{
    
    
    public void checkDuplicateUser(){
        List<Assigned_Reviewer__c > newList = (List<Assigned_Reviewer__c > ) trigger.new;
        Set<Id> grantIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Set<String> keyIdSet = new Set<String>();
        for(Assigned_Reviewer__c  ar : newList){
            if(ar.Assigned_User__c != null){
                userIdSet.add(ar.Assigned_User__c );
            }
            if(ar.Grants__c != null){
                grantIdSet.add(ar.Grants__c );
            }
        }
        List<Assigned_Reviewer__c > existingARList = [SELECT Id, Assigned_User__c, Grants__c FROM Assigned_Reviewer__c WHERE Assigned_User__c IN: userIdSet AND Grants__c IN : grantIdSet AND Id NOT IN : newList];
        for(Assigned_Reviewer__c  ar : existingARList){
            keyIdSet.add(ar.Grants__c +''+ar.Assigned_User__c);
        }
        
        for(Assigned_Reviewer__c  ar : newList){
            string key = ar.Grants__c +''+ar.Assigned_User__c;
            if(keyIdSet.contains(key)){
                ar.Assigned_User__c.addError('The value you selected is already in the sharing.');
            }
        }
    }
    
    public void createManualSharing(){
        List<Assigned_Reviewer__c > newList = (List<Assigned_Reviewer__c >) trigger.new;
        List<Assigned_Reviewer__c > oldList = (List<Assigned_Reviewer__c >) trigger.old;
        Map<Id,Assigned_Reviewer__c > oldMap = (Map<Id,Assigned_Reviewer__c >) trigger.oldMap;
        Set<String> whreClause = new Set<String>();
        List<Grants__Share > shareList = new List<Grants__Share >();
        if((Boolean) trigger.isInsert){
            for(Assigned_Reviewer__c ar : newList ){
                if(ar.Assigned_User__c != null  && ar.Grants__c != null){
                    Grants__Share sRd = manualShareRead(ar.Grants__c , ar.Assigned_User__c);
                    shareList.add(sRd);
                }
            }
        }else if((Boolean) trigger.isUpdate){
            for(Assigned_Reviewer__c ar : newList ){
                if(ar.Assigned_User__c != oldMap.get(ar.Id).Assigned_User__c || ar.Grants__c != oldMap.get(ar.Id).Grants__c ){
                    if(ar.Assigned_User__c != null  && ar.Grants__c != null){
                        Grants__Share sRd = manualShareRead(ar.Grants__c , ar.Assigned_User__c);
                        shareList.add(sRd);
                    }
                    whreClause.add(' (UserOrGroupId = \''+ar.Assigned_User__c+'\' AND ParentId = \''+ar.Grants__c+'\') ');
                    whreClause.add(' (UserOrGroupId = \''+oldMap.get(ar.Id).Assigned_User__c+'\' AND ParentId = \''+oldMap.get(ar.Id).Grants__c+'\') ');
                }
            }
        }else if((Boolean) trigger.isDelete){
            for(Assigned_Reviewer__c ar : oldList ){
                whreClause.add(' (UserOrGroupId = \''+ar.Assigned_User__c+'\' AND ParentId = \''+ar.Grants__c+'\') ');
            }
        }else if((Boolean) trigger.isUndelete){
            for(Assigned_Reviewer__c ar : newList ){
                if(ar.Assigned_User__c != null  && ar.Grants__c != null){
                    Grants__Share sRd = manualShareRead(ar.Grants__c , ar.Assigned_User__c);
                    shareList.add(sRd);
                }
            }
        }
        if(!whreClause.isEmpty()){
            List<String> wList = new List<String> ();
            wList.addAll(whreClause );
            String query = 'SELECT Id FROM Grants__Share WHERE '+String.Join(wList, ' OR ');
            system.debug('query  '+query );
            List<Grants__Share > sharingRecordList = database.query(query );
            if(!sharingRecordList.isEmpty()) database.delete(sharingRecordList , false);
        }
        
        if(!shareList.isEmpty()){
            database.insert(shareList, false);
        }
    }
    
    public static Grants__Share manualShareRead(Id recordId, Id userOrGroupId){
      Grants__Share jobShr  = new Grants__Share ();
      jobShr.ParentId = recordId;
      jobShr.UserOrGroupId = userOrGroupId;
      jobShr.AccessLevel = 'Read';
      jobShr.RowCause = Schema.Grants__Share.RowCause.Manual;
      
      return jobShr;
   }
}