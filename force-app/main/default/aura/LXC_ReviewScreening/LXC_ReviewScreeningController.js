({
	doInit : function(component, event, helper) {
        helper.fetchReviewScreeningRecord(component, event, helper);
    },
    
    saveReviewScreening : function(component, event, helper) {
        helper.saveRecord(component, event, helper);
    },
    
    submitReviewScreening : function(component, event, helper) {
        helper.submitRecord(component, event, helper);
    }
})