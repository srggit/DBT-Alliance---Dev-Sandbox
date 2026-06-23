({
    /* Comman method*/
    doInit : function(component, event, helper) {
        //component.set('v.recordId','a032u000007Ilpk');
        var today = new Date();
        var dd = today.getDate();
        var mm = today.getMonth()+1; 
        var yyyy = today.getFullYear();
        
        if(dd<10) dd='0'+dd;
        if(mm<10) mm='0'+mm;
        var dt = yyyy+'-'+mm+'-'+dd; 
        component.set('v.startDateFrom',dt);
     
        component.set('v.initLayout',true);
        helper.setupInitData(component, event); 
    },
    initTSG : function(component, event, helper) {
        component.set('v.initLayout',true);
        helper.setupInitData(component, event);
    },
    validateTextArea : function(component, event, helper) { 
        var value = event.getSource().get("v.value");
        value = value.trim();
        var maxSize = event.getSource().get("v.class");
        var lenStringList = value.split(" ");
        if(lenStringList.length > maxSize){
            var index = 0;
            var res = [];
            while ((index = value.indexOf(' ', index + 1)) > 0) {
                res.push(index);
            }
            var newVal = value.substring(0,res[maxSize-1]);
            event.getSource().set("v.value",newVal+' ');
            helper.showToast('Error !', 'error', 'You have reach max word limit. [ '+maxSize+' ]');
        }
    },
    handleStepBlur : function (component, event, helper) {
        var stepIndex = event.getSource().get("v.value");
        if(component.get("v.defaultMode") !='read'){
            helper.saveApex(component, event)
            .then($A.getCallback(function(response) {
                if(response.isPassed){
                    if(response.isPassed === true){
                        helper.showToast('Application !', 'success', 'Application has been saved successfully');
                        helper.setupInitData(component, event); 
                        component.set("v.currentStep", stepIndex);
                    }
                }else{
                    helper.showToast('Error!', 'error', 'Review all error messages below to correct your data.');
                    component.set("v.isError", true);
                    component.set("v.errorMsgList", response.errorMsgList );
                }
            }, $A.getCallback(function(err) {
                //helper.showToast('Problem loading page', 'error', err.message);
            }))).catch(function(err) {
                //helper.showToast('System Error', 'error', err);
            }); 
        }else{
            component.set("v.currentStep", stepIndex);
        }
    },
    save : function (component, event, helper) {
        helper.saveApex(component, event)
        .then($A.getCallback(function(response) {
            if(response.isPassed){
                if(response.isPassed === true){
                    helper.showToast('Application !', 'success', 'Application has been saved successfully');
                    helper.setupInitData(component, event); 
                    if(event.getSource().get("v.value")){
                        var step= 'step'+event.getSource().get("v.value");
                        component.set("v.currentStep",step);
                    }
                }
            }else{
                helper.showToast('Error!', 'error', 'Review all error messages below to correct your data.');
                component.set("v.isError", true);
                component.set("v.errorMsgList", response.errorMsgList );
            }
        }, $A.getCallback(function(err) {
            //helper.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            //helper.showToast('System Error', 'error', err);
        }); 
    },
    saveAndRedirect : function (component, event, helper) {
        component.set('v.isSkipValidation', true);
        helper.saveApex(component, event)
        .then($A.getCallback(function(response) {
            if(response.isPassed){
                if(response.isPassed === true){
                    helper.showToast('Application !', 'success', 'Application has been saved successfully');
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": response.recordId,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
            }else{
                component.set("v.isError", true);
                component.set("v.errorMsgList", response.errorMsgList );
            }
        }, $A.getCallback(function(err) {
            helper.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            helper.showToast('System Error', 'error', err);
        }); 
    },
    next : function (component, event, helper) {
        if(event.getSource().get("v.value")){
            var step= 'step'+event.getSource().get("v.value");
            component.set("v.currentStep",step);
        } 
    },
    handleApplicationEvent : function(component, event) {
        var mode = event.getParam("mode");
        component.set("v.defaultMode", mode);
        helper.setupInitData(component, event);
    },
    handleYearClick : function (component, event, helper) {
        var form = component.get("v.form");
        var total = 0;
        for(var i=0 ; i < form.investigatorRecordList.length; i++){
            var inv = form.investigatorRecordList[i].investigatorRecord;
            if(inv.Year_1__c){
                total += parseFloat(inv.Year_1__c);
            }
            if(inv.Year_2__c){
                total += parseFloat(inv.Year_2__c);
            }
            if(inv.Year_3__c){
                total += parseFloat(inv.Year_3__c);
            }
            if(inv.Year_4__c){
                total += parseFloat(inv.Year_4__c);
            }
            if(inv.Year_5__c){
                total += parseFloat(inv.Year_5__c);
            } 
        }
        form.totalYearAmount = total;
        component.set("v.form", form); 
        helper.calculateTotal(component, event);
    },
    
    /* Tab1 Team method */ 
    handleTimeClick : function (component, event, helper) {
        var form = component.get("v.form");
        for(var i=0 ; i < form.investigatorRecordList.length; i++){
            var perweekTotal = 0;
            var inv = form.investigatorRecordList[i];
            var perweekOnResearchTotal = 0;
            if(inv.investigatorRecord.Hours_per_week_on_Non_Research_Activitiy__c){
                perweekTotal+= parseFloat(inv.investigatorRecord.Hours_per_week_on_Non_Research_Activitiy__c);
            }
            
            if(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c){
                perweekOnResearchTotal+= parseFloat(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c);
            }
            if(inv.investigatorRecord.Hours_per_week_on_Project_Proposed_to_IA__c){
                perweekOnResearchTotal+= parseFloat(inv.investigatorRecord.Hours_per_week_on_Project_Proposed_to_IA__c);
            }
            if(inv.investigatorRecord.If_you_are_a_Practicing_Clinician__c){
                perweekOnResearchTotal+= parseFloat(inv.investigatorRecord.If_you_are_a_Practicing_Clinician__c);
            }
            if(perweekOnResearchTotal){
                perweekTotal+= parseFloat(perweekOnResearchTotal);
            }
            inv.investigatorRecord.Hours_per_week_to_be_spent_on_Research__c = perweekOnResearchTotal;
            inv.investigatorRecord.Number_of_total_working_hours_per_week__c = perweekTotal;
        }
        for(var i=0 ; i < form.investigatorRecordListPH.length; i++){
            var perweekTotal = 0;
            var inv = form.investigatorRecordListPH[i];
            var perweekOnResearchTotal = 0;
            if(inv.investigatorRecord.Hours_per_week_on_Non_Research_Activitiy__c){
                perweekTotal+= parseFloat(inv.investigatorRecord.Hours_per_week_on_Non_Research_Activitiy__c);
            }
            
            if(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c){
                perweekOnResearchTotal+= parseFloat(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c);
            }
            if(inv.investigatorRecord.Hours_per_week_on_Project_Proposed_to_IA__c){
                perweekOnResearchTotal+= parseFloat(inv.investigatorRecord.Hours_per_week_on_Project_Proposed_to_IA__c);
            }
            if(inv.investigatorRecord.If_you_are_a_Practicing_Clinician__c){
                perweekOnResearchTotal+= parseFloat(inv.investigatorRecord.If_you_are_a_Practicing_Clinician__c);
            }
            if(perweekOnResearchTotal){
                perweekTotal+= parseFloat(perweekOnResearchTotal);
            }
            inv.investigatorRecord.Hours_per_week_to_be_spent_on_Research__c = perweekOnResearchTotal;
            inv.investigatorRecord.Number_of_total_working_hours_per_week__c = perweekTotal;
        }
        component.set("v.form", form)
    },
    editRecord : function (component, event, helper) {
        var name = event.getSource().get("v.name");
        if(name){
            name = name +'Id'
        }
        try {
            component.set(name, event.getSource().get("v.value"));
        }catch(err) {}
        component.set(event.getSource().get("v.name"), true);
    },
    openModal : function (component, event, helper) {
        var iId = event.getSource().get("v.value");
        var tId = event.getSource().get("v.class");
        var name = event.getSource().get("v.name");
        component.set('v.isSkipValidation', true);
        helper.saveApex(component, event)
        .then($A.getCallback(function(response) {
            if(response.isPassed){
                if(response.isPassed === true){
                    if(iId){
                        component.find(tId).set("v.value", iId);
                    }
                    component.set(name, true);
                    name = name + 'Id';
                    try {
                        component.set(name, "");
                    }catch(err) {}
                }
            }else{
                helper.showToast('Error!', 'error', 'Review all error messages below to correct your data.');
                component.set("v.isError", true);
                component.set("v.errorMsgList", response.errorMsgList );
            }
        }, $A.getCallback(function(err) {
            //helper.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            //helper.showToast('System Error', 'error', err);
        }); 
        
    },
    closeModal : function (component, event, helper) {
        component.set(event.getSource().get("v.name"), false);
        component.set("v.showAddInstitution", false);
    },
    addYear : function (component, event, helper) {
        helper.addYearRecords(component)
        .then($A.getCallback(function(response) {
            helper.setupInitData(component, event);
            component.set("v.showAddYear", false);
        }, $A.getCallback(function(err) {
            this.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            this.showToast('System Error', 'error', err);
        });  
    },
    createInstitution: function (component, event, helper) {
        component.set("v.showAddInstitution", true);
    },
    handleCreateInstitutionRecord: function (component, event, helper) {
        component.set("v.showAddInstitution", false);
    }, 
    removeRecord: function (component, event, helper) { 
        helper.deleteRecord(component, event)
        .then($A.getCallback(function(response) {
            if(response === true){
                helper.showToast('Deleted !', 'success', 'record has been Deleted successfully');
                component.set('v.isSkipValidation', true);
                helper.saveApex(component, event)
                .then($A.getCallback(function(response) {
                    console.log(response);
                    if(response.isPassed){
                        if(response.isPassed === true){
                            helper.setupInitData(component, event); 
                        }
                    }else{
                        helper.showToast('Error!', 'error', 'Review all error messages below to correct your data.');
                        component.set("v.isError", true);
                        component.set("v.errorMsgList", response.errorMsgList );
                        helper.setupInitData(component, event); 
                    }
                }, $A.getCallback(function(err) {
                    //helper.showToast('Problem loading page', 'error', err.message);
                }))).catch(function(err) {
                    //helper.showToast('System Error', 'error', err);
                }); 
            }
        }, $A.getCallback(function(err) {
            helper.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            helper.showToast('System Error', 'error', err);
        }); 
    },
    handleCreateRecord : function (component, event, helper) {
        setTimeout(function(){
            helper.setupInitData(component, event);
            component.set("v.showAddSupportStaff", false);
            component.set("v.showAddEducation", false);
            component.set("v.showAddPost", false);
            component.set("v.showAddInvestigator", false);
            component.set("v.showAddSupportStaff", false);
            component.set("v.showAddMC", false);
            component.set("v.showAddEQ", false);
            component.set("v.showAddAC", false);
            component.set("v.showAddANI", false);
            component.set("v.showAddANIC", false);
            component.set("v.showAddMIS", false);
            component.set("v.showAddTC", false);
            component.set("v.showAddINS", false);
            component.set("v.showAddRAR", false);
            component.set("v.showAddOD", false);
            component.set("v.showAddOFS", false);
            component.set("v.showAddFO", false);
            component.set("v.showAddInstitution", false);
            component.set("v.showAddInvestigatorPH", false);
        }, 1000);
    },
    onChangeCV: function (component, event, helper) {
        var invId = component.find('selectInvestigator').get('v.value');
        component.set("v.form.selectedPI",invId);
    },  
    showSpinner: function(component, event, helper) {
        //component.set("v.Spinner", true); 
    },
    hideSpinner : function(component,event,helper){ 
        //component.set("v.Spinner", false);
    },
    handleUploadFinished: function (component, event, helper) {
        component.set('v.isSkipValidation', true);
        helper.saveApex(component, event)
        .then($A.getCallback(function(response) {
            if(response.isPassed){
                if(response.isPassed === true){
                    helper.setupInitData(component, event); 
                }
            }else{
                helper.showToast('Error!', 'error', 'Review all error messages below to correct your data.');
                component.set("v.isError", true);
                component.set("v.errorMsgList", response.errorMsgList );
            }
        }, $A.getCallback(function(err) {
            //helper.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            //helper.showToast('System Error', 'error', err);
        }); 
    },
    calculateFundPercentage: function (component, event, helper) {
        var form = component.get("v.form");
        for(var i=0 ; i < form.investigatorRecordList.length; i++){
            var inv = form.investigatorRecordList[i];
            inv.investigatorRecord.Percentage_of_total_funds__c = 0.00;
            if(inv.investigatorRecord.Total_Funds_requested_INR__c){
                if(form.total){
                    if(inv.investigatorRecord.Total_Funds_requested_INR__c > 0){
                        if(form.total > 0){
                            var per = (inv.investigatorRecord.Total_Funds_requested_INR__c*100)/form.total;
                            inv.investigatorRecord.Percentage_of_total_funds__c = per.toFixed(2);
                        }
                    }
                }
            }
        }
        component.set("v.form", form);
    }
})