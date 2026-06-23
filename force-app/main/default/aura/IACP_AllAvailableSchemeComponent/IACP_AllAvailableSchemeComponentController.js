({
    doInit : function(component, event, helper) {
        helper.getLoad(component, event);
        helper.getApplicationRecordTypes(component, event);
        
    },
    toggleSection : function(component, event, helper) {
        var sectionAuraId = event.target.getAttribute("data-auraId");
        var element = document.getElementById(sectionAuraId);
  		element.classList.contains('slds-is-open');
        if(element.classList.contains('slds-is-open')){
            element.classList.remove("slds-is-open");
        }else{
            element.classList.add("slds-is-open");
        }
    },
    createRecord : function (component, event, helper) {
        helper.createRecordHelper(component, event);
    },
    viewRecord : function (component, event, helper) {
        var rtApply = event.target.getAttribute("data-auraId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": rtApply
        });
        navEvt.fire();
    },
    openRegistration: function(component, event, helper) {
        var rtApply = event.target.getAttribute("data-auraId");
        var schId = event.target.getAttribute("data-scheme");
        var recordType = rtApply;
        component.set("v.recordTypeName", recordType);
        var rtList = component.get("v.applicationRecordTypeList");
        for(var i=0 ; i < rtList.length; i++){
            if(rtList[i].name === rtApply){
                recordType = rtList[i].rId;
                component.set("v.sObjectName",rtList[i].sObjectName);
            }
        }
        
        component.set("v.recordTypeId",recordType);
        component.set("v.schemeId",schId);
        if(component.get("v.sObjectName") === 'Grants__c'){
            helper.createRecordHelper(component, event); 
        }
        
      else{
            helper.getLoadApplicationLayoutData(component, event, recordType);
            component.set("v.isOpen",true);
        }
        
       
    },
    closeRegistration: function(component, event, helper) {
        component.set("v.isOpen",false);
    },
})