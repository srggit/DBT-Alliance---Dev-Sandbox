public with sharing class AddSchemeQuestionItemsController {

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static Yearly_Schemes__c getYearlySchemeInfo(Id recordId) {
        List<Yearly_Schemes__c> results = [
            SELECT Id, Name, Scheme_Items__c, Scheme_Items__r.Name
            FROM Yearly_Schemes__c
            WHERE Id = :recordId
        ];
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
        return [
            SELECT Id, Name, Display_Name__c, Is_Active__c,Max_Limit__c,Min_Limit__c,Stage__c,Type__c,Mandatory__c
            FROM Scheme_Questionnaire__c
            WHERE Scheme_Items__c = :schemeItemId
            ORDER BY Name
        ];
    }

    // Existing Scheme Question Items already created for this Yearly Scheme,
    // keyed by their Scheme_Questionnaire__c lookup. Used to prepopulate rows
    // with real saved values (read-only) instead of blank defaults.
    @AuraEnabled
    public static List<Scheme_Question_Items__c> getExistingQuestionItems(Id recordId) {
        return [
            SELECT Id, Name, Stage__c, CurrencyIsoCode, Is_Active__c, Mandatory__c,Attachments__c,
                   Max_Character__c, Min_Character__c, Question__c, Type__c,
                   Scheme_Questionnaire__c, CreatedDate, CreatedBy.Name
            FROM Scheme_Question_Items__c
            WHERE Yearly_Scheme__c = :recordId AND Scheme_Questionnaire__c != null
        ];
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
    public static Map<String, List<PicklistOption>> getScreenPicklistOptions() {
        Map<String, List<PicklistOption>> result = new Map<String, List<PicklistOption>>();
        result.put('stage', getPicklistValues('Scheme_Question_Items__c', 'Stage__c'));
        result.put('type', getPicklistValues('Scheme_Question_Items__c', 'Type__c'));
        result.put('questionItemAttachments', getPicklistValues('Scheme_Question_Items__c', 'Attachments__c'));
        return result;
    }

    @AuraEnabled
    public static Integer saveQuestionItems(Id recordId, List<Scheme_Question_Items__c> questionItemRecords) {
        try {
            if (questionItemRecords == null || questionItemRecords.isEmpty()) {
                throw new AuraHandledException('No question items were selected.');
            }

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
                rec.Yearly_Scheme__c = recordId;
                newRecords.add(rec);
            }
            insert newRecords;
            return newRecords.size();
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Unable to save Scheme Question Items. Please contact your administrator if the problem persists.');
        }
    }
}