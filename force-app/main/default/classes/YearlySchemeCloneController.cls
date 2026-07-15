public with sharing class YearlySchemeCloneController {

    // Simple label/value wrapper — shape matches what lightning-combobox expects.
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static Yearly_Schemes__c getYearlySchemeDetails(Id recordId) {
        List<Yearly_Schemes__c> results = [ SELECT Id, Name, Is_Active__c, Year__c, Year__r.Name, Scheme_Start_Date__c, Second_Stage_Start_Date__c,
                                            Scheme_Items__c, Scheme_Items__r.Name, Scheme_End_Date__c, Second_Stage_End_Date__c,
                                            Application_Stages__c, Budget_Cap__c, Experience_Required__c, Required_Degree__c, Team_Size_Limits__c,
                                            CurrencyIsoCode, Scheme_Visibility__c, OwnerId, Owner.Name FROM Yearly_Schemes__c WHERE Id = :recordId];
        if (results.isEmpty()) {
            throw new AuraHandledException('Yearly Scheme not found for Id: ' + recordId);
        }
        return results[0];
    }

    @AuraEnabled
    public static List<Scheme_Questionnaire__c> getQuestionnairesByItem(Id schemeItemId) {
        if (schemeItemId == null) {
            return new List<Scheme_Questionnaire__c>();
        }
        return [SELECT Id, Name, Display_Name__c, Is_Active__c,Max_Limit__c,Min_Limit__c,Stage__c,Type__c,Mandatory__c,SL_No__c,Section__c,Picklist_Values__c FROM Scheme_Questionnaire__c WHERE Scheme_Items__c = :schemeItemId ORDER BY Name];
    }

    @AuraEnabled
    public static List<sObject> getChildRecords(Id recordId, String objectApiName) {
        String query;
        if (objectApiName == 'Eligibility_Check_List__c') {
            query = 'SELECT Id, Name, Stage__c, CurrencyIsoCode,Display_Question__c,Type__c ' +
                     'FROM Eligibility_Check_List__c ' +
                     'WHERE Yearly_Scheme__c = :recordId ORDER BY CreatedDate DESC';
        } else if (objectApiName == 'Eligibility_Rules__c') {
            query = 'SELECT Id, Name, Stage__c, CurrencyIsoCode,Validation_Type__c  ' +
                     'FROM Eligibility_Rules__c ' +
                     'WHERE Yearly_Scheme__c = :recordId ORDER BY CreatedDate DESC';
        } else if (objectApiName == 'Scheme_Question_Items__c') {
            query = 'SELECT Id, Name, Stage__c, CurrencyIsoCode, Is_Active__c, Mandatory__c, Max_Character__c, Min_Character__c, Question__c, Type__c,Attachments__c,SL_No__c,Section__c,Picklist_Values__c,' +
                     'Scheme_Questionnaire__c, Scheme_Questionnaire__r.Name, Scheme_Questionnaire__r.Display_Name__c, ' +
                     'FROM Scheme_Question_Items__c ' +
                     'WHERE Yearly_Scheme__c = :recordId ORDER BY CreatedDate DESC';
        } else {
            throw new AuraHandledException('Invalid object API name: ' + objectApiName);
        }
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPicklistValues(String objectApiName, String fieldApiName) {
        List<PicklistOption> options = new List<PicklistOption>();

        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
        if (targetType == null) {
            throw new AuraHandledException('Unknown object: ' + objectApiName);
        }

        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        Schema.SObjectField targetField = fieldMap.get(fieldApiName);
        if (targetField == null) {
            throw new AuraHandledException('Unknown field: ' + fieldApiName + ' on ' + objectApiName);
        }

        for (Schema.PicklistEntry entry : targetField.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<PicklistOption>> getCloneScreenPicklistOptions() {
        Map<String, List<PicklistOption>> result = new Map<String, List<PicklistOption>>();
        result.put('publishStatus', getPicklistValues('Yearly_Schemes__c', 'Scheme_Visibility__c'));
        result.put('checkListStage', getPicklistValues('Eligibility_Check_List__c', 'Stage__c'));
        result.put('rulesStage', getPicklistValues('Eligibility_Rules__c', 'Stage__c'));
        result.put('rulesValidationType', getPicklistValues('Eligibility_Rules__c', 'Validation_Type__c'));
        result.put('questionItemStage', getPicklistValues('Scheme_Question_Items__c', 'Stage__c'));
        result.put('questionItemType', getPicklistValues('Scheme_Question_Items__c', 'Type__c'));
        result.put('questionItemAttachments', getPicklistValues('Scheme_Question_Items__c', 'Attachments__c'));  // NEW
        result.put('applicationStages', getPicklistValues('Yearly_Schemes__c', 'Application_Stages__c'));   // NEW
        result.put('requiredDegree', getPicklistValues('Yearly_Schemes__c', 'Required_Degree__c'));         // NEW (multi-select)
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean yearlySchemeExists(Id yearId, Id schemeItemId) {
        return [SELECT COUNT()FROM Yearly_Schemes__c WHERE Year__c = :yearId AND Scheme_Items__c = :schemeItemId] > 0;
    }

    @AuraEnabled
    public static Id cloneYearlyScheme(Id recordId,Yearly_Schemes__c parentOverrides,List<Eligibility_Check_List__c> checkListRecords,
                                        List<Eligibility_Rules__c> rulesRecords,List<Scheme_Question_Items__c> questionItemRecords) {
        try {
            List<Yearly_Schemes__c> originalList = [SELECT Id, OwnerId FROM Yearly_Schemes__c WHERE Id = :recordId LIMIT 1];

            if (originalList.isEmpty()) {
                throw new AuraHandledException('Yearly Scheme not found for Id: ' + recordId);
            }
            Yearly_Schemes__c original = originalList[0];

            //==========================
            // Create Parent Clone
            //==========================
            Yearly_Schemes__c cloned = new Yearly_Schemes__c();
            cloned.OwnerId = UserInfo.getUserId();
            if (parentOverrides != null) {
                cloned.Scheme_Items__c = parentOverrides.Scheme_Items__c;
                cloned.Year__c = parentOverrides.Year__c;
                cloned.Is_Active__c = parentOverrides.Is_Active__c;
                cloned.Scheme_Start_Date__c = parentOverrides.Scheme_Start_Date__c;
                cloned.Second_Stage_Start_Date__c = parentOverrides.Second_Stage_Start_Date__c;
                cloned.Scheme_End_Date__c = parentOverrides.Scheme_End_Date__c;
                cloned.Second_Stage_End_Date__c = parentOverrides.Second_Stage_End_Date__c;
                cloned.Scheme_Visibility__c = parentOverrides.Scheme_Visibility__c;
                cloned.CurrencyIsoCode = parentOverrides.CurrencyIsoCode;

                // NEW fields
                cloned.Team_Size_Limits__c = parentOverrides.Team_Size_Limits__c;
                cloned.Required_Degree__c = parentOverrides.Required_Degree__c;
                cloned.Experience_Required__c = parentOverrides.Experience_Required__c;
                cloned.Budget_Cap__c = parentOverrides.Budget_Cap__c;
                cloned.Application_Stages__c = parentOverrides.Application_Stages__c;
            }
            insert cloned;

            //====================================================
            // Clone Eligibility Check List (values as edited on screen)
            //====================================================
            if (checkListRecords != null && !checkListRecords.isEmpty()) {
                List<Eligibility_Check_List__c> newRecords = new List<Eligibility_Check_List__c>();
                for (Eligibility_Check_List__c src : checkListRecords) {
                    Eligibility_Check_List__c rec = new Eligibility_Check_List__c();
                    rec.Stage__c = src.Stage__c;
                    rec.Display_Question__c = src.Display_Question__c;
                    rec.Type__c = src.Type__c;
                    rec.CurrencyIsoCode = src.CurrencyIsoCode;
                    rec.Yearly_Scheme__c = cloned.Id;
                    newRecords.add(rec);
                }
                insert newRecords;
            }
            //====================================================
            // Clone Eligibility Rules (values as edited on screen)
            //====================================================
            if (rulesRecords != null && !rulesRecords.isEmpty()) {
                List<Eligibility_Rules__c> newRecords = new List<Eligibility_Rules__c>();
                for (Eligibility_Rules__c src : rulesRecords) {
                    Eligibility_Rules__c rec = new Eligibility_Rules__c();
                    rec.Stage__c = src.Stage__c;
                    rec.Validation_Type__c = src.Validation_Type__c;
                    rec.CurrencyIsoCode = src.CurrencyIsoCode;
                    rec.Yearly_Scheme__c = cloned.Id;
                    newRecords.add(rec);
                }
                insert newRecords;
            }
            //====================================================
            // Create Scheme Question Items (fresh records from picked Questionnaires)
            //====================================================
            if (questionItemRecords != null && !questionItemRecords.isEmpty()) {
                List<Scheme_Question_Items__c> newRecords = new List<Scheme_Question_Items__c>();
                for (Scheme_Question_Items__c src : questionItemRecords) {
                    Scheme_Question_Items__c rec = new Scheme_Question_Items__c();
                    rec.Stage__c = src.Stage__c;
                    rec.CurrencyIsoCode = src.CurrencyIsoCode;
                    rec.Scheme_Questionnaire__c = src.Scheme_Questionnaire__c;
                    rec.Question__c = src.Question__c;
                    rec.Mandatory__c = src.Mandatory__c;
                    rec.Type__c = src.Type__c;
                    rec.Max_Character__c = src.Max_Character__c;
                    rec.Min_Character__c = src.Min_Character__c;
                    rec.Is_Active__c = src.Is_Active__c;
                    rec.Attachments__c = src.Attachments__c;
                    rec.Section__c = src.Section__c;                 
                    rec.SL_No__c = src.SL_No__c;                      
                    rec.Picklist_Values__c = src.Picklist_Values__c; 
                    rec.Yearly_Scheme__c = cloned.Id;
                    newRecords.add(rec);
                }
                insert newRecords;
            }
            return cloned.Id;
        }
        catch (DmlException e) {
            if (e.getDmlMessage(0).contains('A Yearly Scheme already exists')) {
                throw new AuraHandledException(
                    'A Yearly Scheme already exists for the selected Year and Scheme. Please choose a different Year or Scheme before cloning.'
                );
            }
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Unable to clone the Yearly Scheme. Please contact your administrator if the problem persists.');
        }
    }
}