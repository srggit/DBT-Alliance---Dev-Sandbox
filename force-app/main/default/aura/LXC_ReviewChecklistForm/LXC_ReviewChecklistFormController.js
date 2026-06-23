({
	doInit : function(component, event, helper) {
        helper.fetchReviewChecklistRecord(component, event, helper);
    },
    
    setTeamCheckboxValue : function(component, event, helper) {
        var currentFieldName = event.getSource().get("v.name");
        var currentReviewChecklistRecord = component.get("v.currentReviewChecklist");
        
        if(currentFieldName == 'Team_Not_Supportable__c' && currentReviewChecklistRecord.Team_Not_Supportable__c == true) {
            currentReviewChecklistRecord.Team_Satisfactory__c = false;
            currentReviewChecklistRecord.Team_Compititive__c = false;
            currentReviewChecklistRecord.Team_Excellent__c = false;
            currentReviewChecklistRecord.Team_Outstanding__c = false;
        }
        if(currentFieldName == 'Team_Satisfactory__c' && currentReviewChecklistRecord.Team_Satisfactory__c == true) {
            currentReviewChecklistRecord.Team_Not_Supportable__c = false;
            currentReviewChecklistRecord.Team_Compititive__c = false;
            currentReviewChecklistRecord.Team_Excellent__c = false;
            currentReviewChecklistRecord.Team_Outstanding__c = false;
        }
        if(currentFieldName == 'Team_Compititive__c' && currentReviewChecklistRecord.Team_Compititive__c == true) {
            currentReviewChecklistRecord.Team_Satisfactory__c = false;
            currentReviewChecklistRecord.Team_Not_Supportable__c = false;
            currentReviewChecklistRecord.Team_Excellent__c = false;
            currentReviewChecklistRecord.Team_Outstanding__c = false;
        }
        if(currentFieldName == 'Team_Excellent__c' && currentReviewChecklistRecord.Team_Excellent__c == true) {
            currentReviewChecklistRecord.Team_Satisfactory__c = false;
            currentReviewChecklistRecord.Team_Compititive__c = false;
            currentReviewChecklistRecord.Team_Not_Supportable__c = false;
            currentReviewChecklistRecord.Team_Outstanding__c = false;
        }
        if(currentFieldName == 'Team_Outstanding__c' && currentReviewChecklistRecord.Team_Outstanding__c == true) {
            currentReviewChecklistRecord.Team_Satisfactory__c = false;
            currentReviewChecklistRecord.Team_Compititive__c = false;
            currentReviewChecklistRecord.Team_Excellent__c = false;
            currentReviewChecklistRecord.Team_Not_Supportable__c = false;
        }
        component.set("v.currentReviewChecklist", currentReviewChecklistRecord);
	},
    
    setProjectCheckboxValue : function(component, event, helper) {
        var currentFieldName = event.getSource().get("v.name");
        var currentReviewChecklistRecord = component.get("v.currentReviewChecklist");
        
        if(currentFieldName == 'Project_Not_Supportable__c' && currentReviewChecklistRecord.Project_Not_Supportable__c == true) {
            currentReviewChecklistRecord.Project_Satisfactory__c = false;
            currentReviewChecklistRecord.Project_Compititive__c = false;
            currentReviewChecklistRecord.Project_Excellent__c = false;
            currentReviewChecklistRecord.Project_Outstanding__c = false;
        }
        if(currentFieldName == 'Project_Satisfactory__c' && currentReviewChecklistRecord.Project_Satisfactory__c == true) {
            currentReviewChecklistRecord.Project_Not_Supportable__c = false;
            currentReviewChecklistRecord.Project_Compititive__c = false;
            currentReviewChecklistRecord.Project_Excellent__c = false;
            currentReviewChecklistRecord.Project_Outstanding__c = false;
        }
        if(currentFieldName == 'Project_Compititive__c' && currentReviewChecklistRecord.Project_Compititive__c == true) {
            currentReviewChecklistRecord.Project_Satisfactory__c = false;
            currentReviewChecklistRecord.Project_Not_Supportable__c = false;
            currentReviewChecklistRecord.Project_Excellent__c = false;
            currentReviewChecklistRecord.Project_Outstanding__c = false;
        }
        if(currentFieldName == 'Project_Excellent__c' && currentReviewChecklistRecord.Project_Excellent__c == true) {
            currentReviewChecklistRecord.Project_Satisfactory__c = false;
            currentReviewChecklistRecord.Project_Compititive__c = false;
            currentReviewChecklistRecord.Project_Not_Supportable__c = false;
            currentReviewChecklistRecord.Project_Outstanding__c = false;
        }
        if(currentFieldName == 'Project_Outstanding__c' && currentReviewChecklistRecord.Project_Outstanding__c == true) {
            currentReviewChecklistRecord.Project_Satisfactory__c = false;
            currentReviewChecklistRecord.Project_Compititive__c = false;
            currentReviewChecklistRecord.Project_Excellent__c = false;
            currentReviewChecklistRecord.Project_Not_Supportable__c = false;
        }
        component.set("v.currentReviewChecklist", currentReviewChecklistRecord);
    },
    
    saveReviewChecklist : function(component, event, helper) {
        helper.saveRecord(component, event, helper);
    },
    
    submitReviewChecklist : function(component, event, helper) {
        helper.submitRecord(component, event, helper);
    }
})