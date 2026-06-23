({
	doInit : function(component, event, helper) {
        helper.fetchChecklistRecord(component, event, helper);
    },
    
    calculateTotalFields : function(component, event, helper) {
        var checkListRecord = component.get("v.currentChecklist");
        var subtotalValue = parseInt(checkListRecord.Salaries_for_PIs__c) + parseInt(checkListRecord.Support_Staff_salaries__c) + parseInt(checkListRecord.Materials_and_consumables__c) + parseInt(checkListRecord.Animals__c) + parseInt(checkListRecord.Equipment__c) + parseInt(checkListRecord.Access_charges__c) + parseInt(checkListRecord.Miscellaneous__c) + parseInt(checkListRecord.Travel_costs__c) + parseInt(checkListRecord.Flexible_Funding_Allowance__c);
        var overheadsValue = (10 * subtotalValue) / 100;
        var totalValue = subtotalValue + overheadsValue;
        component.set("v.subTotals", subtotalValue);
        component.set("v.Overheads", overheadsValue);
        component.set("v.Total", totalValue);
    },
    
    saveChecklist : function(component, event, helper) {
        helper.saveRecord(component, event, helper);
    },
    
    submitChecklist : function(component, event, helper) {
        helper.submitRecord(component, event, helper);
    }
})