({
	setupInitData : function(component, event) {
		var action = component.get('c.init');
        return new Promise(function(resolve, reject) {
            action.setParams({ 
                'recordId': component.get('v.recordId')
            });
            action.setCallback(this, function(response) {
                if(component.isValid() && response.getState().toLowerCase() === 'success') {
                    resolve(response.getReturnValue());
                } else {
                    reject(response.getError()[0].message);
                }
            });
            $A.enqueueAction(action);
        });
	},
    deleteRecord: function(component, event) {
        var action = component.get('c.apexDeleteRecord');
        return new Promise(function(resolve, reject) {
            action.setParams({
                'recordId': event.getSource().get("v.value")
            });
            action.setCallback(this, function(response) {
                if(component.isValid() && response.getState().toLowerCase() === 'success') {
                    resolve(response.getReturnValue());
                } else {
                    reject(response.getError()[0].message);
                }
            });
            $A.enqueueAction(action);
        });
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
})