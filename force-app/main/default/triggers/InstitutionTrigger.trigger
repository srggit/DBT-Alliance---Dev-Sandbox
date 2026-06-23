trigger InstitutionTrigger on Institution__c (before insert, before update) {
    if(trigger.isbefore){
        set<Id> grantIdset = new set<Id>();
        if(trigger.isInsert || trigger.isUpdate){
            for(Institution__c inv : trigger.new){
                if(trigger.isInsert && inv.Grants__c != null && inv.Type__c != null && inv.Type__c.equalsignorecase('Lead Institution')){
                    grantIdset.add(inv.Grants__c);
                }
                if(trigger.isUpdate && inv.Grants__c != null && inv.Type__c != null && inv.Type__c != trigger.oldMap.get(inv.Id).Type__c && inv.Type__c.equalsignorecase('Lead Institution')){
                    grantIdset.add(inv.Grants__c);
                }
            }
            List<Institution__c > invList = [SELECT Id, Grants__c FROM Institution__c WHERE Grants__c IN: grantIdset AND Type__c = 'Lead Institution'];
            grantIdset = new set<Id>();
            for(Institution__c inv : invList ){
                grantIdset.add(inv.Grants__c );
            }
            
            for(Institution__c inv : trigger.new){
                if(inv.Grants__c != null && inv.Type__c != null && inv.Type__c.equalsignorecase('Lead Institution') && grantIdset.contains(inv.Grants__c )){
                    inv.Type__c.addError('Duplicate Lead Institution.');
                }
            }
        }   
    }
}