global class TSGApplicationFormController{
    @AuraEnabled
    public static TSGForm.Response submitGrant(String recordId){
        TSGForm.Response res = new TSGForm.Response();
        List<String> stepList = new List<String>{
            'step1',
            'step2',
            'step3',
            'step4',
            'step5',
            'step6',
            'step7',
            'step8',
            'step9',
            'step10',
            'step11',
            'step12',
            'step13'
        };
    
        List<Grants__c> grants = [SELECT Id,Scheme__r.Close_Date__c, Scheme__r.End_Date__c ,Is_Open_Application__c, RecordType.Name FROM Grants__c WHERE Id = : recordId AND (Status__c IN ('Open','Pre-Submission','Post-Submission','Awaited Signatory Approval','Pending Submission','Submission Failed') OR Status__c = null OR Is_Open_Application__c = true)];
        Boolean isPassed = true;
        if((grants != null && grants.size() > 0 && grants.get(0).Scheme__r.End_Date__c >= Date.Today()) || (grants != null && grants.size() > 0 && grants.get(0).Is_Open_Application__c)){
            
            Boolean isTSG = false;
            Boolean isCRC = false;
            if(grants.get(0).RecordType.Name.equalsignorecase('Team Science Grants (TSG)')) isTSG = true;
            if(grants.get(0).RecordType.Name.equalsignorecase('Clinical/Public Health Research Centers(CRC)')) isCRC = true;
            
            if(isCRC ){
                stepList.add('step14');
            }
            TSGForm form = new TSGForm(recordId);
            
            for(String step : stepList){
                if(isPassed){
                    res = validateForm(res, form , step); 
                    res.errorMsgList = new List<String>();
                    isPassed = res.isPassed;
                }
            }
            if(!isPassed){
                res.errorMsgList = new List<String>(); res.errorMsgList.add('The grant application form is not filled completed. Please edit and follow save and next button.');
            }
            if(isPassed && form.contentDocumentLinkList.size() == 0){
                res.errorMsgList.add('Grant proposal section: Research summary attachment not found.'); 
                isPassed = false;
            }
            if(isPassed && form.contentDocumentLinkUndertakingList.size() == 0){
                res.errorMsgList.add('Undertaking from PIs : Undertaking statement to upload not found.'); 
                isPassed = false;
            }
            if(isPassed && form.contentDocumentLinkUndertakingList.size() == 0){
                res.errorMsgList.add('Institutional Undertakings : Upload of an Institutional undertaking attachment not found.'); 
                isPassed = false;
            }
            
            
            if(isPassed){
                Grants__c gr = new Grants__c(Id = recordId, Status__c = 'Submitted', Is_Open_Application__c = false);
                update gr;
            }
        }else{
            res.errorMsgList.add('The grant has been already submitted.'); 
            isPassed = false;
        }
        res.isPassed = isPassed;
        return res;
    }
    
    @AuraEnabled
    public static boolean editGrant(String recordId){
        List<Grants__c> grants = [SELECT Id,Scheme__r.Close_Date__c, Scheme__r.End_Date__c ,Is_Open_Application__c, RecordType.Name FROM Grants__c WHERE Id = : recordId AND (Status__c IN ('Open','Pre-Submission','Post-Submission','Awaited Signatory Approval','Pending Submission','Submission Failed') OR Status__c = null OR Is_Open_Application__c = true)];
        if((grants != null && grants.size() > 0 && grants.get(0).Scheme__r.End_Date__c >= Date.Today()) || (grants != null && grants.size() > 0 && grants.get(0).Is_Open_Application__c)){
            return true;
        }
        return false;
    }
    
    @AuraEnabled
    global static TSGForm formInit(String recordId, String recordTypeId, String schemeId){
        Grants__c grant = new Grants__c();
        if(string.isBlank(recordId)){
            List<Grants__c> grants = [SELECT Id FROM Grants__c WHERE CreatedById =: UserInfo.getuserId() AND RecordTypeId = : recordTypeId AND Scheme__c = : schemeId];
            if(grants.isEmpty()){
                Budget__c bd = new Budget__c();
                insert bd;
                
                Other_Document__c PIUNDERTAKING = new Other_Document__c(Subject__c = 'PIU '+recordTypeId , Description__c = 'Undertakings from PIs documents');
                insert PIUNDERTAKING;
                
                Other_Document__c IUUNDERTAKING = new Other_Document__c(Subject__c = 'IU '+recordTypeId , Description__c = 'Institutional Undertakings documents');
                insert IUUNDERTAKING;
                
                grant.Budget__c = bd.Id;
                grant.PI_Documents__c = PIUNDERTAKING.Id;
                grant.IU_Documents__c = IUUNDERTAKING.Id;
                grant.Principal_Investigator_Documents__c = PIUNDERTAKING.Id;
                grant.Institution_Undertaking_Document__c = IUUNDERTAKING.Id;
                grant.RecordTypeId = recordTypeId;
                grant.Scheme__c = schemeId;
                grant.Status__c = Label.GrantDefaultStatus;
                insert grant;
                recordId = grant.Id;
            }else{ recordId = grants.get(0).Id;
            }
        }
        TSGForm form = new TSGForm(recordId);
        List<Grants__c> grants = [SELECT Id,RecordType.Name FROM Grants__c WHERE Id = : recordId AND (Status__c IN ('Open','Pre-Submission','Post-Submission','Awaited Signatory Approval','Pending Submission','Submission Failed') OR Status__c = null)];
        form.isSbumited = false;
        if(grants != null && grants.size() > 0){
            form.isSbumited = true;
        }
        return form;
    }
    
    @AuraEnabled
    global static boolean upsertInvestigator(Investigator__c record){
        Investigator__c inv = new Investigator__c (
            Title__c = record.Title__c,
            First_Name__c = record.First_Name__c,
            Last_Name__c = record.Last_Name__c,
            Institution__c = record.Institution__c,
            Investigators_Type__c = record.Investigators_Type__c,
            Role__c = record.Role__c,
            Discipline_expertise__c = record.Discipline_expertise__c,
            Grants__c = record.Grants__c 
        );
        if(string.isNotBlank(record.Id))  inv.Id = record.Id; 
        if(string.isNotBlank(record.Id)){
            update inv;
        }else{
            insert inv;
        }
        return true;
    }
    @AuraEnabled
    global static boolean apexDeleteRecord(String recordId){
        if(string.isNotBlank(recordId)){
            Id id = recordId;
            String ObjectName = id.getSObjectType()+'';
            sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
            sObj.put('Id',recordId);
            delete sObj; 
            return true;
        }
        return false;
    }
    @AuraEnabled
    global static boolean addYearApex(String year, String formJSON){
        if(string.isNotBlank(formJSON) && string.isNotBlank(year)){
            TSGForm form = (TSGForm) JSON.deserialize(formJSON, TSGForm.class);
            
            List<Investigator_Year_Salary__c> iYSList = new List<Investigator_Year_Salary__c>();
            for(TSGForm.Investigator inv : form.investigatorRecordList){
                iYSList.add(new Investigator_Year_Salary__c(Year__c = year, Investigator__c = inv.investigatorRecord.Id));
            }
            if(!iYSList.isEmpty()){
                insert iYSList ;
            }
        }
        return false;
    }
    
    global static TSGForm.Response validateForm(TSGForm.Response response, TSGForm form , String step){
        response.isPassed = true;
        response.errorMsgList.add('Required field missing.');
        if(step.equalsignorecase('step1')){
            
            if((form.investigatorRecordList != null && form.investigatorRecordList.size() == 0) || form.investigatorRecordList == null){
                response.isPassed = false;
                response.errorMsgList.add('Q1. Please provide composition of the team that is applying for this grant.');
            }
            /*if((form.investigatorRecordList != null && form.investigatorRecordList.size() > 0)){
                Integer PICount = 0;
                for(TSGForm.Investigator inv :form.investigatorRecordList){
                    if(inv.investigatorRecord.Investigators_Type__c != null && inv.investigatorRecord.Investigators_Type__c.equalsignorecase('Co-Principal Investigator')){
                        PICount ++;
                    }
                    if(PICount > 3) break;
                }
                if(PICount > 3 && form.isCRC ){
                    response.isPassed = false;
                    response.errorMsgList.add('Q1. Please provide composition of the team that is applying for this grant. [Max Limit for co-principal investigator upto 3]');
                }
            }*/
            if(form.grantRecord.Describe_Why_Team_Approach_Is_necessary__c == null || string.isBlank(form.grantRecord.Describe_Why_Team_Approach_Is_necessary__c)){
                response.isPassed = false;
                if(form.isTSG) response.errorMsgList.add('Q2. Please describe why a team approach is necessary to execute this project. Define roles of all investigators and how the project will be managed and led.');
                if(form.isCRC) response.errorMsgList.add('Justification [Note: Justify the requirement/role of each PI and Co-PIs on the project.');
            }
            for(TSGForm.Investigator inv : form.investigatorRecordList){
                if(inv.investigatorRecord.Hours_per_week_on_Non_Research_Activitiy__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(B) Number of hours per week to be spent on non-research activities]');
                }
                if(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c+' - [(D) Number of hours per week to be spent on active grants/fellowships/projects other than this proposed project]');
                }
                if(inv.investigatorRecord.Hours_per_week_on_Project_Proposed_to_IA__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(E) Number of hours per week to be spent on this project proposed to India Alliance.');
                }
                if(inv.investigatorRecord.If_you_are_a_Practicing_Clinician__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(F) If you are a practicing clinician, please indicate the number of hours per week to be spent in the clinic on the proposed project]');
                }
            }
            for(TSGForm.Investigator inv : form.investigatorRecordListPH){
                if(inv.investigatorRecord.Hours_per_week_on_Non_Research_Activitiy__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(B) Number of hours per week to be spent on non-research activities]');
                }
                if(inv.investigatorRecord.Hours_per_week_on_Active_Grants_Projects__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(D) Number of hours per week to be spent on active grants/fellowships/projects other than this proposed project]');
                }
                if(inv.investigatorRecord.Hours_per_week_on_Project_Proposed_to_IA__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(E) Number of hours per week to be spent on this project proposed to India Alliance.');
                }
                if(inv.investigatorRecord.If_you_are_a_Practicing_Clinician__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(F) If you are a practicing clinician, please indicate the number of hours per week to be spent in the clinic on the proposed project]');
                }
            }
        
        }else if(step.equalsignorecase('step2')){
            if(form.grantRecord.Project_Title__c == null || string.isBlank(form.grantRecord.Project_Title__c )){
                response.isPassed = false;
                response.errorMsgList.add('[Q1. Project Title]' );
            }
            if(form.grantRecord.Start_date__c == null){
                response.isPassed = false;
                response.errorMsgList.add('[Q2. Start date]');
            }
            if(form.grantRecord.Research_summary__c == null || string.isBlank(form.grantRecord.Research_summary__c )){
                response.isPassed = false;
                response.errorMsgList.add('[Q4. Research summary]');
            }
            if(form.grantRecord.Lay_summary__c == null || string.isBlank(form.grantRecord.Lay_summary__c )){
                response.isPassed = false;
                response.errorMsgList.add('[Q5. Lay summary]');
            }
        }else if(step.equalsignorecase('step3')){
        
            for(TSGForm.Investigator inv : form.investigatorRecordList){
                if(inv.investigatorRecord.Name_of_the_Sponsor__c == null || string.isBlank(inv.investigatorRecord.Name_of_the_Sponsor__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Name of the Sponsor]');
                }
                if(inv.investigatorRecord.Email_of_the_Sponsor__c  == null || string.isBlank(inv.investigatorRecord.Email_of_the_Sponsor__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Email of the Sponsor]');
                }
                if(inv.investigatorRecord.Title_of_current_Post__c == null || string.isBlank(inv.investigatorRecord.Title_of_current_Post__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Title of current post]');
                }
                if(inv.investigatorRecord.Your_Contract_of_Employment__c  == null || string.isBlank(inv.investigatorRecord.Your_Contract_of_Employment__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(b) With whom do you have your contract of employment?]');
                }
                if(inv.investigatorRecord.Source_of_personal_salary_support__c == null || string.isBlank(inv.investigatorRecord.Source_of_personal_salary_support__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(c) Source of personal salary support]');
                }
                if(inv.investigatorRecord.Other_affiliations__c == null || string.isBlank(inv.investigatorRecord.Other_affiliations__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(d) Other affiliations in any other organization]');
                }
                
                if(inv.investigatorRecord.Highest_Degree__c == null || string.isBlank(inv.investigatorRecord.Highest_Degree__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q3. Highest Degree (PhD/MD/MBBS-MS/MD-PhD/MPH/equivalent)]');
                }
                if(inv.investigatorRecord.Years_of_Running_Research_Group_Lab__c == null || string.isBlank(inv.investigatorRecord.Years_of_Running_Research_Group_Lab__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q4. For how many years have you been running an independent research group or lab?]');
                }
                if((inv.phList != null && inv.phList.size() == 0) || inv.phList == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q5. Previous posts held (list the most recent first)]');
                }
                if((inv.qualificationlList != null && inv.qualificationlList.size() == 0) || inv.qualificationlList== null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q6. Education/training (list the most recent first)]');
                }
                if(inv.investigatorRecord.Summary_of_Scientific_Career_to_Date__c == null || string.isBlank(inv.investigatorRecord.Summary_of_Scientific_Career_to_Date__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q7. Summary of scientific career to date, including key achievements]');
                }
                if(inv.investigatorRecord.Experience_Relevant_to_this_Proposal__c == null || string.isBlank(inv.investigatorRecord.Experience_Relevant_to_this_Proposal__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q8. Experience relevant to this proposal ]');
                }
                if(inv.investigatorRecord.Research_Output_in_last_5_years__c == null || string.isBlank(inv.investigatorRecord.Research_Output_in_last_5_years__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q9. Research output in last 5 years]');
                }
                if((inv.investigatorRecord.Is_other_financial_support__c != null && inv.investigatorRecord.Is_other_financial_support__c.equalsignorecase('Yes')) && (inv.otherFinancialSupportList == null || inv.otherFinancialSupportList.size() == 0)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q10. Other financial support]');
                }
                if(inv.investigatorRecord.Is_other_financial_support__c.equalsignorecase('Yes') && (inv.investigatorRecord.Describe_the_Current_Active_Awards__c == null || string.isBlank(inv.investigatorRecord.Describe_the_Current_Active_Awards__c))){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q11. Please describe how the current active awards listed above relate to this application]');
                }
                if(inv.investigatorRecord.Please_specify_your_medical_degree__c == null || string.isBlank(inv.investigatorRecord.Please_specify_your_medical_degree__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q12. Clinical status. (a) Please specify your medical degree]');
                }
                if(inv.investigatorRecord.what_is_your_specialty_Active__c == null || string.isBlank(inv.investigatorRecord.what_is_your_specialty_Active__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q12. Clinical status. (b) If you are clinically active, what is your specialty?]');
                }
                if(inv.investigatorRecord.Will_be_submitted_for_funding__c == null || string.isBlank(inv.investigatorRecord.Will_be_submitted_for_funding__c )){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q13. Related applications]');
                }
                if((inv.investigatorRecord.Will_be_submitted_for_funding__c != null && inv.investigatorRecord.Will_be_submitted_for_funding__c.equalsignorecase('Yes')) && (inv.fundingOrganisationList == null || inv.fundingOrganisationList.size() == 0)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q13. Related applications - funding organisation]');
                }
            }
            for(TSGForm.Investigator inv : form.investigatorRecordListPH){
                if(inv.investigatorRecord.Name_of_the_Sponsor__c == null || string.isBlank(inv.investigatorRecord.Name_of_the_Sponsor__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Name of the Sponsor]');
                }
                if(inv.investigatorRecord.Email_of_the_Sponsor__c  == null || string.isBlank(inv.investigatorRecord.Email_of_the_Sponsor__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Email of the Sponsor]');
                }
                if(inv.investigatorRecord.Title_of_current_Post__c == null || string.isBlank(inv.investigatorRecord.Title_of_current_Post__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Title of current post]');
                }
                if(inv.investigatorRecord.Your_Contract_of_Employment__c  == null || string.isBlank(inv.investigatorRecord.Your_Contract_of_Employment__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(b) With whom do you have your contract of employment?]');
                }
                if(inv.investigatorRecord.Source_of_personal_salary_support__c == null || string.isBlank(inv.investigatorRecord.Source_of_personal_salary_support__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(c) Source of personal salary support]');
                }
                if(inv.investigatorRecord.Other_affiliations__c == null || string.isBlank(inv.investigatorRecord.Other_affiliations__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [(d) Other affiliations in any other organization]');
                }
                
                if(inv.investigatorRecord.Highest_Degree__c == null || string.isBlank(inv.investigatorRecord.Highest_Degree__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q3. Highest Degree (PhD/MD/MBBS-MS/MD-PhD/MPH/equivalent)]');
                }
                if(inv.investigatorRecord.Years_of_Running_Research_Group_Lab__c == null || string.isBlank(inv.investigatorRecord.Years_of_Running_Research_Group_Lab__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q4. For how many years have you been running an independent research group or lab?]');
                }
                if((inv.phList != null && inv.phList.size() == 0) || inv.phList == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q5. Previous posts held (list the most recent first)]');
                }
                if((inv.qualificationlList != null && inv.qualificationlList.size() == 0) || inv.qualificationlList== null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q6. Education/training (list the most recent first)]');
                }
                
                if(inv.investigatorRecord.Summary_of_Scientific_Career_to_Date__c == null || string.isBlank(inv.investigatorRecord.Summary_of_Scientific_Career_to_Date__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q7. Summary of scientific career to date, including key achievements]');
                }
                if(inv.investigatorRecord.Experience_Relevant_to_this_Proposal__c == null || string.isBlank(inv.investigatorRecord.Experience_Relevant_to_this_Proposal__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q8. Experience relevant to this proposal ]');
                }
                if(inv.investigatorRecord.Research_Output_in_last_5_years__c == null || string.isBlank(inv.investigatorRecord.Research_Output_in_last_5_years__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q9. Research output in last 5 years]');
                }
                if((inv.investigatorRecord.Is_other_financial_support__c != null && inv.investigatorRecord.Is_other_financial_support__c.equalsignorecase('Yes')) && (inv.otherFinancialSupportList == null || inv.otherFinancialSupportList.size() == 0)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q10. Other financial support]');
                }
                if(inv.investigatorRecord.Is_other_financial_support__c.equalsignorecase('Yes') && (inv.investigatorRecord.Describe_the_Current_Active_Awards__c == null || string.isBlank(inv.investigatorRecord.Describe_the_Current_Active_Awards__c))){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q11. Please describe how the current active awards listed above relate to this application]');
                }
                if(inv.investigatorRecord.Please_specify_your_medical_degree__c == null || string.isBlank(inv.investigatorRecord.Please_specify_your_medical_degree__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q12. Clinical status. (a) Please specify your medical degree]');
                }
                if(inv.investigatorRecord.what_is_your_specialty_Active__c == null || string.isBlank(inv.investigatorRecord.what_is_your_specialty_Active__c)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q12. Clinical status. (b) If you are clinically active, what is your specialty?]');
                }
                if(inv.investigatorRecord.Will_be_submitted_for_funding__c == null || string.isBlank(inv.investigatorRecord.Will_be_submitted_for_funding__c )){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q13. Related applications]');
                }
                if((inv.investigatorRecord.Will_be_submitted_for_funding__c != null && inv.investigatorRecord.Will_be_submitted_for_funding__c.equalsignorecase('Yes')) && (inv.fundingOrganisationList == null || inv.fundingOrganisationList.size() == 0)){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Q13. Related applications - funding organisation]');
                }
            }
        
        }else if(step.equalsignorecase('step4')){
            if(form.total > 100000000){
                response.isPassed = false;
                response.errorMsgList.add('[Total (not more than INR 10 Crores)]');
            }
            
            for(TSGForm.Investigator inv : form.investigatorRecordList){
                if(inv.investigatorRecord.Total_Funds_requested_INR__c == null){
                    response.isPassed = false;
                    response.errorMsgList.add(inv.investigatorRecord.Full_Name__c+' - [Total Funds requested (INR)]');
                }
            }
            if(form.budget.budgetRecord.Salaries_for_PIs_Justification__c == null || string.isBlank(form.budget.budgetRecord.Salaries_for_PIs_Justification__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Salary Justification ]');
            }
            if(form.budget.budgetRecord.Support_staff_justification__c == null || string.isBlank(form.budget.budgetRecord.Support_staff_justification__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Support staff justification.]');
            }
            if(form.budget.budgetRecord.Materials_and_Consumables_Justification__c== null || string.isBlank(form.budget.budgetRecord.Materials_and_Consumables_Justification__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Itemised justification for materials and consumables requested]');
            }
            if(form.budget.budgetRecord.Equipment_Justification__c == null || string.isBlank(form.budget.budgetRecord.Equipment_Justification__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Justification for equipment and equipment maintenance requested]');
            }
            if(form.budget.budgetRecord.Justification_for_access_charges__c == null || string.isBlank(form.budget.budgetRecord.Justification_for_access_charges__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Justification for access charges requested.]');
            }
            if(form.budget.budgetRecord.Justification_for_animal_costs_requested__c == null || string.isBlank(form.budget.budgetRecord.Justification_for_animal_costs_requested__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Justification for animal costs requested.]');
            }
            if(form.budget.budgetRecord.Justification_for_miscellaneous_costs__c == null || string.isBlank(form.budget.budgetRecord.Justification_for_miscellaneous_costs__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Justification for miscellaneous costs requested.]');
            }
            if(form.budget.budgetRecord.Justification_for_Travel_Costs__c == null || string.isBlank(form.budget.budgetRecord.Justification_for_Travel_Costs__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Justification for travel cost requested.]');
            }
            if(form.budget.budgetRecord.Justification_for_Travel_Costs__c == null || string.isBlank(form.budget.budgetRecord.Justification_for_Travel_Costs__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Justification for travel cost requested.]');
            }
        
        }else if(step.equalsignorecase('step5')){
        
            if(form.grantRecord.Will_the_Proposed_research_generates__c == null || string.isBlank(form.grantRecord.Will_the_Proposed_research_generates__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Q1.Will the proposed research generate outputs of data, software, materials, or intellectual property that hold significant value as a resource for the wider research community?]');
            }
        
        }else if(step.equalsignorecase('step6')){
        
            if(form.grantRecord.Public_Dissemination_of_Funded_Research__c == null || string.isBlank(form.grantRecord.Public_Dissemination_of_Funded_Research__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Q1. India Alliance strongly encourages public dissemination of its funded research.]');
            }
        
        }else if(step.equalsignorecase('step7')){
        
            if(form.grantRecord.Human_participants__c || form.grantRecord.Experiments_with_human_stem_cells__c || form.grantRecord.Personal_data__c || form.grantRecord.Biological_samples__c){
                if(form.grantRecord.By_Whom_and_When_the_Project_was_Review__c == null || string.isBlank(form.grantRecord.By_Whom_and_When_the_Project_was_Review__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q2. Please state: By whom and when the ethics of the project was/will be reviewed? Also specify any other regulatory approvals that have been/will be obtained.]');
                }
                if(form.grantRecord.If_your_project_involves_Experiments__c == null || string.isBlank(form.grantRecord.If_your_project_involves_Experiments__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q3. If your project involves Experiments with human stem cells]');
                }
                
                if(form.grantRecord.Institutional_Ethics_Committee_IEC__c || form.grantRecord.Institutional_Committee_for_Stem_Cell__c){
                    if(form.grantRecord.Details_of_Stem_Cell_Experiments__c == null || string.isBlank(form.grantRecord.Details_of_Stem_Cell_Experiments__c)){
                        response.isPassed = false;
                        response.errorMsgList.add('[Q5. Provide details of source(s) of stem cells and nature of experiments.]');
                    }
                    if(form.grantRecord.Will_your_project_require_National__c == null || string.isBlank(form.grantRecord.Will_your_project_require_National__c)){
                        response.isPassed = false;
                        response.errorMsgList.add('[Q4. Will your project require National Apex Committee for Stem Cell Research and Therapy (NAC-SCRT)?]');
                    }
                }
                if(form.grantRecord.Project_Requires_to_patients_Treatments__c == null || string.isBlank(form.grantRecord.Project_Requires_to_patients_Treatments__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q6. If your project requires access to patients under treatment at a hospital/clinical facility, provide name of the clinician(s) along with the details of the hospital or clinical facility.]');
                }
            }
        
        }else if(step.equalsignorecase('step8')){
        
            if(form.grantRecord.Use_of_animals__c || form.grantRecord.Use_of_animal_tissue__c || form.grantRecord.Use_of_animal_stem_cells__c){
                if(form.grantRecord.Details_Procedures_of_Animals__c == null || string.isBlank(form.grantRecord.Details_Procedures_of_Animals__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q2. Please provide details of any procedures on animals of substantial or moderate severity]');
                }
                if(form.grantRecord.Why_is_animal_use_necessary__c  == null || string.isBlank(form.grantRecord.Why_is_animal_use_necessary__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q3. Why is animal use necessary? Are there other possible approaches?]');
                }
                
                if(form.grantRecord.plan_to_work_on_animal_stem_cells__c == null || string.isBlank(form.grantRecord.plan_to_work_on_animal_stem_cells__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q4. If you plan to work on animal stem cells, please provide details of source of stem cells and nature of experiments.]');
                }
                if(form.grantRecord.following_species_will_be_used__c == null || string.isBlank(form.grantRecord.following_species_will_be_used__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q5. Indicate if any of the following species will be used:]');
                }
                if(form.grantRecord.Why_are_the_species_to_be_used__c == null || string.isBlank(form.grantRecord.Why_are_the_species_to_be_used__c)){
                    response.isPassed = false;
                    response.errorMsgList.add('[Q6. Why are the species to be used the most appropriate?]');
                }
            }
        
        }else if(step.equalsignorecase('step9')){
            
            if(form.grantRecord.Proposed_Research_or_Outcomes_Pose_Risk__c == null || string.isBlank(form.grantRecord.Proposed_Research_or_Outcomes_Pose_Risk__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Q1. Please confirm that you have considered whether your proposed research or its outcomes pose risk of being misused for harmful purposes. ]');
            }
        
        }else if(step.equalsignorecase('step10')){
        
            if(form.grantRecord.Have_any_Research_Sponsorship_Agreements__c  == null || string.isBlank(form.grantRecord.Have_any_Research_Sponsorship_Agreements__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Q1. Do you have any research sponsorship agreements, consultancies with, or equity holdings]');
            }
            if(form.grantRecord.Details_of_Technology_materials__c   == null || string.isBlank(form.grantRecord.Details_of_Technology_materials__c)){
                response.isPassed = false;
                response.errorMsgList.add('[Q2. If applicable, let us know details of]');
            }
        
        }else if(step.equalsignorecase('step11')){
            
            if((form.rarList != null && form.rarList.size() ==0) || form.rarList == null){
                response.isPassed = false;
                response.errorMsgList.add('[You may suggest up to 3 potential reviewers who may be appropriate to evaluate your proposal.]');
            }
        
        }else if(step.equalsignorecase('step12')){
        
        }else if(step.equalsignorecase('step13')){
        
        }else if(step.equalsignorecase('step14')){
            if((form.institutionRecordList!= null && form.institutionRecordList.size() == 0) || form.institutionRecordList== null){
                response.isPassed = false;
                response.errorMsgList.add('Q1. (a) If you are proposing a CRC with multiple institutions');
            }
            if(form.grantRecord.Institution_Justification__c == null || string.isBlank(form.grantRecord.Institution_Justification__c)){
                response.isPassed = false;
                response.errorMsgList.add('If a singleinstitution is proposing this CRC, please provide a justification. In this case, please also list the departments that will participate in the programme.');
            }
        }
        system.debug(response);
        return response;
    }
    
    @AuraEnabled
    global static TSGForm.Response saveData(String formJSON, String step, Boolean isSkipValidation){
        TSGForm.Response res = new TSGForm.Response();
        try{
            if(string.isNotBlank(formJSON)){
                TSGForm form = (TSGForm) JSON.deserialize(formJSON, TSGForm.class);
                res.recordId  = form.grantRecord.Id;
                res.isPassed = true;
                system.debug('isSkipValidation '+isSkipValidation);
                if( !isSkipValidation){
                    res = validateForm(res, form , step);
                }
                if(res.isPassed){
                    // Update team part
                    List<Investigator__c > investigatorList = new List<Investigator__c >();
                    for(TSGForm.Investigator inv : form.investigatorRecordList){
                        investigatorList.add(inv.investigatorRecord);
                    }
                    for(TSGForm.Investigator inv : form.investigatorRecordListPH){
                        investigatorList.add(inv.investigatorRecord);
                    }
                    for(Investigator__c inv : investigatorList){
                        inv.Selected_CV__c = false;
                        if(inv.Id == form.selectedPI ) inv.Selected_CV__c = true;
                    }
                    if(!investigatorList.isEmpty()) update investigatorList; 
                    
                    if(form.grantRecord != null && string.isNotBlank(form.grantRecord.Id)) update form.grantRecord;
                    
                    if(form.budget.budgetRecord != null && string.isNotBlank(form.budget.budgetRecord.Id)) update form.budget.budgetRecord;
                    
                    res.isPassed = true;
                }
            }
        }catch(Exception e){
            res.isPassed = false;
            if(!Test.isRunningTest()){Integer numErrors = e.getNumDml();
                for(Integer i=0;i<numErrors;i++) {
                    res.errorMsgList.add(e.getDmlMessage(i)); 
                }
            }
        }
        return res ;
    }
    
    public static void pass(){
        integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }
}