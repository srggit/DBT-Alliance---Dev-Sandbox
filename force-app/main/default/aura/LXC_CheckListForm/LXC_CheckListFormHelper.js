({
    fetchChecklistRecord : function(component, event, helper) {
        var action = component.get("c.getGrantAccessForUser");
        action.setParams({"recId" : component.get("v.recordId")
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                component.set("v.isReviewAccess", result.getReturnValue());
                console.log(result.getReturnValue());
                if(result.getReturnValue() === true) {
                    this.fetchCheckRecord(component, event, helper);
                }else{
                    this.showToast('Error!', 'error', 'You are not allow to review this application. please contact to admin.');
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
        });
        $A.enqueueAction(action);
	},
	fetchCheckRecord : function(component, event, helper) {
        var action = component.get("c.getCurrentChecklist");
        action.setParams({"recId" : component.get("v.recordId")
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var resultRes = result.getReturnValue();
                console.log(resultRes);
                component.set("v.currentChecklist",resultRes.checklistRecord);
                component.set("v.coInvList",resultRes.coInvList);
                component.set("v.coInvListSize",resultRes.coInvList.length);
                component.set("v.isTSG",resultRes.isTSG );
                component.set("v.isCRC",resultRes.isCRC );
                component.set("v.subTotals", component.get("v.currentChecklist").Sub_Total__c);
                component.set("v.Overheads", component.get("v.currentChecklist").Overheads__c);
                component.set("v.Total", component.get("v.currentChecklist").Total__c);
                if(component.get("v.currentChecklist").Type__c == 'Submit') {
                    component.set("v.isEditable", false);
                }
            }
        });
        $A.enqueueAction(action);
	},
    showToast: function (title, type, message) {
        var toastEvent = $A.get('e.force:showToast');
        if (toastEvent) {
            toastEvent.setParams({
                'title': title,
                'type': type,
                'message': message
            }); 
            toastEvent.fire();
        }
    },
    saveRecord : function(component, event, helper) {
        var action = component.get("c.saveChecklistRecord");
        action.setParams({"checklistRecord" : component.get("v.currentChecklist"),
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
        var action = component.get("c.saveChecklistRecord");
        action.setParams({"checklistRecord" : component.get("v.currentChecklist"),
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