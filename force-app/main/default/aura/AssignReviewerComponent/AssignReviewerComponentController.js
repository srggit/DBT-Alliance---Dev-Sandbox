({
	doInit : function(component, event, helper) {
        helper.setupInitData(component, event)
        .then($A.getCallback(function(response) {
            component.set("v.grant",response);
        }, $A.getCallback(function(err) {
            //this.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            //this.showToast('System Error', 'error', err);
        });  
	},
    handleCreateRecord : function (component, event, helper) {
        setTimeout(function(){
            helper.setupInitData(component, event)
        .then($A.getCallback(function(response) {
            component.set("v.grant",response);
    		component.set("v.addReview", false);
        }, $A.getCallback(function(err) {
            //this.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            //this.showToast('System Error', 'error', err);
        });  
        }, 1000);
    },
    openModal : function (component, event, helper) {
        component.find("gId").set("v.value", component.get("v.recordId"));
        component.set("v.addReview", true);
    },
    closeModal : function (component, event, helper) {
        component.set("v.addReview", false);
    },
    close : function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    removeRecord: function (component, event, helper) { 
        helper.deleteRecord(component, event)
        .then($A.getCallback(function(response) {
            if(response === true){
                helper.showToast('Deleted !', 'success', 'record has been deleted successfully');
                helper.setupInitData(component, event)
                .then($A.getCallback(function(response) {
                    component.set("v.grant",response);
                }, $A.getCallback(function(err) {
                    //this.showToast('Problem loading page', 'error', err.message);
                }))).catch(function(err) {
                    //this.showToast('System Error', 'error', err);
                }); 
            }
        }, $A.getCallback(function(err) {
            helper.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            helper.showToast('System Error', 'error', err);
        }); 
    },
})