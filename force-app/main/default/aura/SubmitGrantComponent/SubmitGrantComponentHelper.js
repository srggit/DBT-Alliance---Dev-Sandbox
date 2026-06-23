({
	getSubmitApplication : function(component, event) {
        var action = component.get("c.submitGrant");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue();
                if(oRes.isPassed){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":"success",
                        "title": "Success!",
                        "message": "The grant has been submitted successfully."
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":"error",
                        "title": "Error!",
                        "message": oRes.errorMsgList[0]
                    });
                    toastEvent.fire();
                }
            }
            else{}
        });
        $A.enqueueAction(action);
    },
})