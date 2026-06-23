trigger InvestigatorTrigger on Investigator__c (before insert, before update) {
    if(trigger.isbefore){
        set<String> grantIdset = new set<String>();
        if(trigger.isInsert || trigger.isUpdate){
            for(Investigator__c inv : trigger.new){
                if(trigger.isInsert && inv.Grants__c != null && inv.Investigators_Type__c != null && inv.Investigators_Type__c.equalsignorecase('Principal Investigator')){
                    grantIdset.add(inv.Grants__c);
                }
                if(trigger.isUpdate && inv.Grants__c != null && inv.Investigators_Type__c != null && inv.Investigators_Type__c != trigger.oldMap.get(inv.Id).Investigators_Type__c && inv.Investigators_Type__c.equalsignorecase('Principal Investigator')){
                    grantIdset.add(inv.Grants__c);
                }
                
                if(trigger.isInsert && inv.Grants__c != null && inv.Type__c != null && inv.Type__c.equalsignorecase('Programme Head')){
                    grantIdset.add(inv.Grants__c);
                }
                if(trigger.isUpdate && inv.Grants__c != null && inv.Type__c != null && inv.Type__c != trigger.oldMap.get(inv.Id).Type__c && inv.Type__c.equalsignorecase('Programme Head')){
                    grantIdset.add(inv.Grants__c);
                }
            }
            List<Investigator__c > invList = [SELECT Id,Type__c, Is_Programme_Head__c , Investigators_Type__c, Grants__c FROM Investigator__c WHERE Grants__c IN: grantIdset AND (Investigators_Type__c = 'Principal Investigator' OR Type__c = 'Programme Head')];
            grantIdset = new set<String>();
            for(Investigator__c inv : invList ){
                if(inv.Is_Programme_Head__c) grantIdset.add(inv.Type__c+''+inv.Grants__c);
                if(!inv.Is_Programme_Head__c) grantIdset.add(inv.Investigators_Type__c+''+inv.Grants__c);
            }
            system.debug('grantIdset '+grantIdset);
            for(Investigator__c inv : trigger.new){
                if(inv.Grants__c != null && inv.Investigators_Type__c != null && inv.Investigators_Type__c.equalsignorecase('Principal Investigator') && grantIdset.contains(inv.Investigators_Type__c+''+inv.Grants__c )){
                    inv.Investigators_Type__c .addError('Duplicate principal investigator.');
                }
                if(inv.Grants__c != null && inv.Type__c != null && inv.Type__c.equalsignorecase('Programme Head') && grantIdset.contains(inv.Type__c+''+inv.Grants__c)){
                    inv.Type__c.addError('Duplicate programme head.');
                }
            }
        }   
    }
}