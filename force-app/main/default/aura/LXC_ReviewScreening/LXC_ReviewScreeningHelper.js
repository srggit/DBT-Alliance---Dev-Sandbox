({
	fetchReviewScreeningRecord : function(component, event, helper) {
        var action = component.get("c.getCurrentReviewScreening");
        action.setParams({"recId" : component.get("v.recordId")
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                component.set("v.currentReviewScreening",result.getReturnValue());
                if(component.get("v.currentReviewScreening").Type__c == 'Submit') {
                    component.set("v.isEditable", false);
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    saveRecord : function(component, event, helper) {
        var action = component.get("c.saveReviewScreeningRecord");
        action.setParams({"reviewScreeningRecord" : component.get("v.currentReviewScreening"),
                          "reviewScreeningType" : "Save"
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
        var action = component.get("c.saveReviewScreeningRecord");
        action.setParams({"reviewScreeningRecord" : component.get("v.currentReviewScreening"),
                          "reviewScreeningType" : "Submit"
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