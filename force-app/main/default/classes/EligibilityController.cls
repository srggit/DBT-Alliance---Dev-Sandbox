public with sharing class EligibilityController {

    // --------------------------------------- Fetching data from Object_Master__c Object --------------------------------------- //
    @AuraEnabled(cacheable=true)
    public static List<ObjectFieldMaster> getFieldMasterData() {

        Map<Id, ObjectFieldMaster> objectMasterMap = new Map<Id, ObjectFieldMaster>();

        // Fetch all active objects
        for (Object_Master__c obj : [
            SELECT Id,
                   Name,
                   Object_Api_Name__c,
                   Status__c
            FROM Object_Master__c
            WHERE Status__c = 'Active'
            ORDER BY Name
        ]) {
            System.debug('Object : ' + obj.Name + ' Id=' + obj.Id);
            ObjectFieldMaster wrapper = new ObjectFieldMaster();
            wrapper.objectApiName = obj.Object_Api_Name__c;
            wrapper.objectLabel = obj.Name;
            wrapper.fieldOptions = new Map<String, String>();

            objectMasterMap.put(obj.Id, wrapper);
        }

        // Fetch all active fields
        for (Fields_Master__c field : [
            SELECT Object_Master__c,
                   Field_Label_Name__c,
                   Field_Api_Name__c,
                   Status__c
            FROM Fields_Master__c
            WHERE Status__c = 'Active'
            ORDER BY Field_Label_Name__c
        ]) {
            System.debug('field===>'+field);
            if (objectMasterMap.containsKey(field.Object_Master__c)) {

                objectMasterMap.get(field.Object_Master__c)
                    .fieldOptions.put(
                        field.Field_Label_Name__c,
                        field.Field_Api_Name__c
                    );
            }
        }
        System.debug(JSON.serializePretty(objectMasterMap));
        return new List<ObjectFieldMaster>(objectMasterMap.values());
    }

    public class ObjectFieldMaster {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public Map<String, String> fieldOptions;
    }

    // --------------------------------------- Saving Eligibility Criteria --------------------------------------- //
    @AuraEnabled
    public static String saveEligibilityCriteria(String wrapperDataJson, String yearlySchemeId) {

        try {

            if (String.isBlank(wrapperDataJson)) {
                throw new AuraHandledException('No conditions found to save.');
            }

            List<ConditionWrapper> wrapperData = parseConditionWrappers(wrapperDataJson);

            if (wrapperData == null || wrapperData.isEmpty()) {
                throw new AuraHandledException('No conditions found to save.');
            }

            List<Eligibility_Criteria__c> criteriaList = new List<Eligibility_Criteria__c>();

            for (ConditionWrapper condition : wrapperData) {

                Eligibility_Criteria__c criteria = new Eligibility_Criteria__c();

                criteria.Sequence__c = condition.sequence;
                criteria.Validation_Type__c = condition.validationType;
                criteria.Eligibility_Type__c = condition.eligibilityType;
                criteria.Formula__c = condition.formula;
                criteria.Yearly_Scheme__c = yearlySchemeId;

                // Uncomment these if the fields exist on Eligibility_Criteria__c
                // criteria.Object_Name__c = condition.objectName;
                // criteria.Field_Name__c = condition.fieldName;
                // criteria.Operator__c = condition.operator;
                // criteria.Value__c = condition.value;
                // criteria.Logical_Operator__c = condition.logicalOperator;

                criteriaList.add(criteria);
            }

            insert criteriaList;

            return 'SUCCESS';

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static List<ConditionWrapper> parseConditionWrappers(String wrapperDataJson) {

        ConditionWrapper[] wrappers =
            (ConditionWrapper[])JSON.deserialize(
                wrapperDataJson,
                ConditionWrapper[].class
            );

        return wrappers == null
            ? new List<ConditionWrapper>()
            : new List<ConditionWrapper>(wrappers);
    }

    public class ConditionWrapper {

        @AuraEnabled public Integer sequence;
        @AuraEnabled public String ruleName;
        @AuraEnabled public String objectName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;
        @AuraEnabled public String logicalOperator;
        @AuraEnabled public String validationType;
        @AuraEnabled public String eligibilityType;
        @AuraEnabled public String formula;
    }



    
    // --------------------------------------- Fetching data from Field_Master_MDT__mdt --------------------------------------- //
    // @AuraEnabled(cacheable=true)
    // public static List<ObjectFieldMaster> getFieldMasterData() {
    //     Map<String, ObjectFieldMaster> objectFieldMasterByApiName = new Map<String, ObjectFieldMaster>();

    //     for (Field_Master_MDT__mdt record : [
    //         SELECT Object__c, Object_Label__c, Values__c
    //         FROM Field_Master_MDT__mdt
    //         WHERE Object__c != null
    //         ORDER BY Object_Label__c, Object__c
    //     ]) {
    //         if (!objectFieldMasterByApiName.containsKey(record.Object__c)) {
    //             ObjectFieldMaster master = new ObjectFieldMaster();
    //             master.objectApiName = record.Object__c;
    //             master.objectLabel = String.isNotBlank(record.Object_Label__c)
    //                 ? record.Object_Label__c
    //                 : record.Object__c;
    //             master.fieldOptions = new Map<String, String>();
    //             objectFieldMasterByApiName.put(record.Object__c, master);
    //         }

    //         objectFieldMasterByApiName
    //             .get(record.Object__c)
    //             .fieldOptions
    //             .putAll(parseFieldValues(record.Values__c));
    //     }

    //     return new List<ObjectFieldMaster>(objectFieldMasterByApiName.values());
    // }

    // private static Map<String, String> parseFieldValues(String rawValues) {
    //     Map<String, String> parsedValues = new Map<String, String>();

    //     if (String.isBlank(rawValues)) {
    //         return parsedValues;
    //     }

    //     try {
    //         Map<String, Object> valuesByLabel = (Map<String, Object>) JSON.deserializeUntyped(
    //             rawValues.trim()
    //         );

    //         for (String label : valuesByLabel.keySet()) {
    //             Object fieldApiName = valuesByLabel.get(label);
    //             if (fieldApiName != null && String.isNotBlank(String.valueOf(fieldApiName))) {
    //                 parsedValues.put(label, String.valueOf(fieldApiName));
    //             }
    //         }
    //     } catch (Exception ex) {
    //         for (String valuePart : rawValues.split('[,;]+')) {
    //             String trimmedValue = valuePart.trim();
    //             if (String.isNotBlank(trimmedValue)) {
    //                 parsedValues.put(trimmedValue, trimmedValue);
    //             }
    //         }
    //     }

    //     return parsedValues;
    // }

    // public class ObjectFieldMaster {
    //     @AuraEnabled public String objectApiName;
    //     @AuraEnabled public String objectLabel;
    //     @AuraEnabled public Map<String, String> fieldOptions;
    // }

    // @AuraEnabled
    // public static String saveEligibilityCriteria(String wrapperDataJson, String yearlySchemeId) {

    //     try {

    //         System.debug('wrapperDataJson: ' + wrapperDataJson);
    //         System.debug('yearlySchemeId: ' + yearlySchemeId);

    //         if (String.isBlank(wrapperDataJson)) {
    //             throw new AuraHandledException('No conditions found to save.');
    //         }

    //         List<ConditionWrapper> wrapperData = parseConditionWrappers(wrapperDataJson);

    //         System.debug('wrapperData: ' + wrapperData);

    //         if (wrapperData == null || wrapperData.isEmpty()) {
    //             throw new AuraHandledException('No conditions found to save.');
    //         }

    //         List<Eligibility_Criteria__c> criteriaList = new List<Eligibility_Criteria__c>();

    //         for (ConditionWrapper condition : wrapperData) {

    //             Eligibility_Criteria__c criteria = new Eligibility_Criteria__c();

    //             //criteria.Name = condition.ruleName;
                
    //             criteria.Sequence__c = condition.sequence;
    //             // criteria.Object_Name__c = condition.objectName;
    //             // criteria.Field_Name__c = condition.fieldName;
    //             // criteria.Operator__c = condition.operator;
    //             // criteria.Value__c = condition.value;
    //             criteria.Validation_Type__c = condition.validationType;
    //             criteria.Eligibility_Type__c = condition.eligibilityType;
    //             criteria.Formula__c = condition.formula;
    //             criteria.Yearly_Scheme__c = yearlySchemeId;
    //             //criteria.Logical_Operator__c = condition.logicalOperator;

    //             criteriaList.add(criteria);
    //         }

    //         insert criteriaList;

    //         return 'SUCCESS';

    //     } catch (Exception ex) {
    //         throw new AuraHandledException(ex.getMessage());
    //     }
    // }

    // private static List<ConditionWrapper> parseConditionWrappers(String wrapperDataJson) {
    //     ConditionWrapper[] wrappers = (ConditionWrapper[]) JSON.deserialize(
    //         wrapperDataJson,
    //         ConditionWrapper[].class
    //     );
    //     return wrappers == null ? new List<ConditionWrapper>() : new List<ConditionWrapper>(wrappers);
    // }

    // public class ConditionWrapper {

    //     @AuraEnabled public Integer sequence;
    //     @AuraEnabled public String ruleName;
    //     @AuraEnabled public String objectName;
    //     @AuraEnabled public String fieldName;
    //     @AuraEnabled public String operator;
    //     @AuraEnabled public String value;
    //     @AuraEnabled public String logicalOperator;
    //     @AuraEnabled public String validationType;
    //     @AuraEnabled public String eligibilityType;
    //     @AuraEnabled public String formula;
    // }
    
}