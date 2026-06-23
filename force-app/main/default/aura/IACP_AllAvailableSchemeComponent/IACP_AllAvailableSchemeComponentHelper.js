({
    getLoad : function(component, event) {
        var action = component.get("c.getAllScheme");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue(); 
                component.set('v.allSchemes', oRes);
            }
            else{}
        });
        $A.enqueueAction(action);
    },
    getApplicationRecordTypes : function(component, event) {
        var action = component.get("c.getAllApplicationRecordTypes");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue();
                component.set('v.applicationRecordTypeList', oRes);
                console.log(oRes);
            }
            else{}
        });
        $A.enqueueAction(action);
    },
    createRecordHelper : function (component, event) {
        if(component.get("v.sObjectName") === 'Grants__c'){
            component.set("v.isOpenGrantTSG", true);
            var tsg = component.find('TSGFORM');
            tsg.initializeTSGForm();
        }
       else if(component.get("v.sObjectName") === 'Application__c'){
  
        if(component.get("v.recordTypeName") ==='IRMI RM Fellowship Application Form'){
             component.set("v.FellowshipForm", true);
        }else if(component.get("v.recordTypeName") ==='IRMI INORMS Travel Grant Application Form'){
            component.set("v.isOpenTravelGrant", true);
            
       }else if(component.get("v.recordTypeName") ==='IRMI RM Grant Application Form'){
            component.set("v.IrmiGrant", true);
            
       }
    }
    },
       
	getLoadApplicationLayoutData : function(component, event, recordType) {
        var action = component.get("c.getLoadLayout");
        action.setParams({ recordTypeId : recordType });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue(); 
                component.set('v.fields', oRes.fields);
                component.set('v.user', oRes.user);
            }
            else{}
        });
        $A.enqueueAction(action);
    },
})