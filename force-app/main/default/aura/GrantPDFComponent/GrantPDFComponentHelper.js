({
	getStart : function(component, event) {
        var action = component.get("c.createApplicationPDFBySiteApplicant");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue();
                if(oRes === true){
                     var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":"success",
                        "title": "Success!",
                        "message": "The request has been submitted successfully, will send you a confirmation mail."
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":"error",
                        "title": "Error!",
                        "message": "Something went wrong."
                    });
                    toastEvent.fire();
                }
            }
            else{}
        });
        $A.enqueueAction(action);
    }
})