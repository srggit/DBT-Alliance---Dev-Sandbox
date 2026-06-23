({
	validate : function(component, event, helper) {
		var action = component.get('c.editGrant');
        return new Promise(function(resolve, reject) {
            action.setParams({
                'recordId': component.get('v.recordId')
            });
            action.setCallback(this, function(response) {
                if(component.isValid() && response.getState().toLowerCase() === 'success') {
                    if(response.getReturnValue() === true){
                        var appEvent = $A.get("e.c:aeEvent");
                        appEvent.setParams({
                            "mode" : "edit"
                        });
                        appEvent.fire();
                    }else{
                        var toastEvent = $A.get('e.force:showToast');
                        if (toastEvent) {
                            toastEvent.setParams({
                                'title': 'Error!',
                                'type': 'error',
                                'message': 'You are not allow to edit application, please contact to admin.'
                            });
                            toastEvent.fire();
                        }
                    }
                } else {
                    reject(response.getError()[0].message);
                }
            });
            $A.enqueueAction(action);
        });
	}
})