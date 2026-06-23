({
	fetchReviewChecklistRecord : function(component, event, helper) {
        var action = component.get("c.getCurrentReviewChecklist");
        action.setParams({"recId" : component.get("v.recordId")
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                component.set("v.currentReviewChecklist",result.getReturnValue());
                if(component.get("v.currentReviewChecklist").Type__c == 'Submit') {
                    component.set("v.isEditable", false);
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    saveRecord : function(component, event, helper) {
        var action = component.get("c.saveReviewChecklistRecord");
        action.setParams({"reviewChecklistRecord" : component.get("v.currentReviewChecklist"),
                          "checklistType" : "Save"
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get("v.recordId")
                });
                navEvt.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    submitRecord : function(component, event, helper) {
        var action = component.get("c.saveReviewChecklistRecord");
        action.setParams({"reviewChecklistRecord" : component.get("v.currentReviewChecklist"),
                          "checklistType" : "Submit"
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get("v.recordId")
                });
                navEvt.fire();
            }
        });
        $A.enqueueAction(action);
    }
})