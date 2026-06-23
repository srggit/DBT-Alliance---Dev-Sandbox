({
    helperInit: function(component) {
        var action = component.get('c.formInit');
        return new Promise(function(resolve, reject) {
            action.setParams({ 
                'recordId': component.get('v.recordId'),
                'recordTypeId': component.get('v.recordTypeId'),
                'schemeId': component.get('v.schemeId')
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
    apexAddInvestigator: function(component) {
        var action = component.get('c.upsertInvestigator');
        var invRecord = component.get('v.investigatorRecord');
        invRecord.Grants__c = component.get('v.recordId');
        return new Promise(function(resolve, reject) {
            action.setParams({
                'record': component.get('v.investigatorRecord')
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
    addYearRecords: function(component, event) {
        var yname = component.find('invYear').get('v.value');   
        var action = component.get('c.addYearApex');
        return new Promise(function(resolve, reject) {
            action.setParams({
                'year': yname,
                'formJSON': JSON.stringify(component.get('v.form'))
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
    saveApex: function(component, event) {
        component.set("v.isError", false);
        var action = component.get('c.saveData');
        return new Promise(function(resolve, reject) {
            action.setParams({
                'formJSON': JSON.stringify(component.get('v.form')),
                'step': component.get('v.currentStep'),
                'isSkipValidation': component.get('v.isSkipValidation')
            });
            action.setCallback(this, function(response) {
                if(component.isValid() && response.getState().toLowerCase() === 'success') {
                    component.set('v.isSkipValidation', false);
                    resolve(response.getReturnValue());
                } else {
                    component.set('v.isSkipValidation', false);
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
    setupInitData: function (component, event) {
        this.helperInit(component)
        .then($A.getCallback(function(response) {
            if(!response.isSbumited && component.get('v.defaultMode') === 'edit'){
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": response.grantRecordId, 
                    "slideDevName": "detail"
                });
                navEvt.fire();
            }
            component.set('v.form', response); 
            component.set('v.investigatorRecord', response.investigator);
            if(component.get('v.initLayout')){
                var tsg = [
                    { label: 'Team', value: 'step1' },
                    { label: 'Grant Proposal', value: 'step2' },
                    { label: 'Principal Investigator(s) CV', value: 'step3' },
                    { label: 'Budget', value: 'step4' },
                    { label: 'Data Management and Sharing', value: 'step5' },
                    { label: 'Public Engagement Plan', value: 'step6' },
                    { label: 'Research Involving Human Participation', value: 'step7' },
                    { label: 'Research Involving Animals', value: 'step8' },
                    { label: 'Risks of Research Misuse', value: 'step9' },
                    { label: 'Conflicts of Interest', value: 'step10' },
                    { label: 'Reviewers and Restrictions', value: 'step11' },
                    { label: 'PIs Undertakings', value: 'step12' },
                    { label: 'Institutional Undertakings', value: 'step13' },
                    { label: 'Other Documents', value: 'step15' },
					{ label: 'SDGs', value: 'step16' }
                ];
                    var crc = [
                    { label: 'Institution', value: 'step14' },
                    { label: 'Investigator', value: 'step1' },
                    { label: 'Proposed Centre', value: 'step2' },
                    { label: 'Investigator(s) CV', value: 'step3' },
                    { label: 'Budget', value: 'step4' },
                    { label: 'Data Management and Sharing', value: 'step5' },
                    { label: 'Public Engagement Plan', value: 'step6' },
                    { label: 'Research Involving Human Participation', value: 'step7' },
                    { label: 'Research Involving Animals', value: 'step8' },
                    { label: 'Risks of Research Misuse', value: 'step9' },
                    { label: 'Conflicts of Interest', value: 'step10' },
                    { label: 'Reviewers and Restrictions', value: 'step11' },
                    { label: 'PIs Undertakings', value: 'step12' },
                    { label: 'Institutional Undertakings', value: 'step13' },
                    { label: 'Other Documents', value: 'step15' },
					{ label: 'SDGs', value: 'step16' }
                ];
                if(response.isCRC === true){
                    component.set('v.steps', crc); component.set('v.currentStep', 'step14');
                }
                if(response.isTSG === true){
                    component.set('v.steps', tsg);
                } 
                component.set('v.initLayout',false);
            }
        }, $A.getCallback(function(err) {
            //this.showToast('Problem loading page', 'error', err.message);
        }))).catch(function(err) {
            //this.showToast('System Error', 'error', err);
        });  
    },
    calculateTotal : function (component, event) {
        var subTotal = 0
        var total = 0;
        var form = component.get("v.form"); 
        if(form.totalYearAmount){
            subTotal += parseFloat(form.totalYearAmount); 
        }
        var sfTotal = form.budget.totalsfAmount ;
        if(sfTotal){
            subTotal += parseFloat(sfTotal);
        }
        if(form.budget.totalmcAmount){
            subTotal += parseFloat(form.budget.totalmcAmount);
        }
        if(form.budget.totaleqAmount ){
            subTotal += parseFloat(form.budget.totaleqAmount );
        }
        if(form.budget.totalaccessAmount ){
            subTotal += parseFloat(form.budget.totalaccessAmount );
        }
        if(form.budget.totalanimalAmount){
            subTotal += parseFloat(form.budget.totalanimalAmount);
        }
        if(form.budget.totalanimalacAmount){
          subTotal += parseFloat(form.budget.totalanimalacAmount);
        }
        if(form.budget.totalmisAmount){
            subTotal += parseFloat(form.budget.totalmisAmount);
        }
        if(form.budget.totaltcAmount ){
            subTotal += parseFloat(form.budget.totaltcAmount ); 
        }
        if(form.budget.IAContributionAmount){
            subTotal += parseFloat(form.budget.IAContributionAmount);
        }
        total = subTotal;
        form.subTotal = subTotal;
        form.x10subTotal = (subTotal * 10)/100;
        form.total = total + form.x10subTotal;
        component.set("v.form", form);
    },
})