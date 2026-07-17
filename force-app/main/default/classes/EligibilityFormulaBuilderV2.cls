public with sharing class EligibilityFormulaBuilderV2 {

    // TODO: Remove after testing — hardcoded contact for Check Eligibility
    private static final Id TEST_CONTACT_ID = '003C300000qEWm0IAG';    

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
    @AuraEnabled(cacheable=true)
    public static List<ObjectFieldMaster> getFieldMasterData() {

        Map<Id, ObjectFieldMaster> objectMasterMap = new Map<Id, ObjectFieldMaster>();

        // Get all active objects
        for (Object_Master__c obj : [
            SELECT Id,
                Name,
                Object_Api_Name__c
            FROM Object_Master__c
            WHERE Status__c = 'Active'
            ORDER BY Name
        ]) {

            ObjectFieldMaster wrapper = new ObjectFieldMaster();
            wrapper.objectApiName = obj.Object_Api_Name__c;
            wrapper.objectLabel = obj.Name;
            wrapper.fieldOptions = new Map<String, String>();

            objectMasterMap.put(obj.Id, wrapper);
        }

        // Get all active fields
        for (Fields_Master__c field : [
            SELECT Object_Master__c,
                Field_Label_Name__c,
                Field_Api_Name__c
            FROM Fields_Master__c
            WHERE Status__c = 'Active'
            ORDER BY Field_Label_Name__c
        ]) {

            if (objectMasterMap.containsKey(field.Object_Master__c)) {

                objectMasterMap.get(field.Object_Master__c)
                    .fieldOptions.put(
                        field.Field_Label_Name__c,
                        field.Field_Api_Name__c
                    );
            }
        }

        return new List<ObjectFieldMaster>(objectMasterMap.values());
    }

    @AuraEnabled
    public static EligibilityEvaluationService.EligibilityEvaluationResult checkEligibility(
        String yearlySchemeId,
        String contactId
    ) {
        if (String.isBlank(yearlySchemeId)) {
            throw new AuraHandledException('Yearly Scheme is required.');
        }

        Id resolvedContactId = TEST_CONTACT_ID;

        if (String.isNotBlank(contactId)) {
            try {
                resolvedContactId = Id.valueOf(contactId);
            } catch (Exception ex) {
                throw new AuraHandledException('Invalid Contact Id: ' + contactId);
            }
        }

        return EligibilityEvaluationService.evaluateYearlyScheme(
            resolvedContactId,
            Id.valueOf(yearlySchemeId)
        );
    }

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

            if (String.isBlank(yearlySchemeId)) {
                throw new AuraHandledException('Yearly Scheme is required.');
            }

            Integer nextSequence = getNextCriteriaSequence(yearlySchemeId);
            List<Eligibility_Criteria__c> criteriaList = new List<Eligibility_Criteria__c>();
            List<Eligibility_Condition__c> conditionList = new List<Eligibility_Condition__c>();

            for (ConditionWrapper condition : wrapperData) {
                if (String.isBlank(condition.formula)) {
                    throw new AuraHandledException('Formula is required for each eligibility criteria.');
                }

                List<EligibilityFormulaParser.ParsedCondition> parsedConditions = EligibilityFormulaParser.parse(
                    condition.formula
                );

                Eligibility_Criteria__c criteria = new Eligibility_Criteria__c();
                criteria.Name = String.isNotBlank(condition.ruleName)
                    ? condition.ruleName.trim()
                    : 'Eligibility Criteria ' + nextSequence;
                criteria.Sequence__c = condition.sequence != null ? condition.sequence : nextSequence;
                criteria.Validation_Type__c = condition.validationType;
                criteria.Eligibility_Type__c = condition.eligibilityType;
                criteria.Is_Active__c = true;
                criteria.Formula__c = condition.formula.trim();
                criteria.Pass_Message__c = condition.passMessage;
                criteria.Fail_Message__c = condition.failMessage;
                criteria.Yearly_Scheme__c = yearlySchemeId;
                criteria.Stage__c = condition.stage;
                criteriaList.add(criteria);
                nextSequence++;
            }

            insert criteriaList;

            for (Integer criteriaIndex = 0; criteriaIndex < criteriaList.size(); criteriaIndex++) {
                Eligibility_Criteria__c savedCriteria = criteriaList[criteriaIndex];
                ConditionWrapper sourceWrapper = wrapperData[criteriaIndex];
                List<EligibilityFormulaParser.ParsedCondition> parsedConditions = EligibilityFormulaParser.parse(
                    sourceWrapper.formula
                );

                for (EligibilityFormulaParser.ParsedCondition parsedCondition : parsedConditions) {
                    Eligibility_Condition__c conditionRecord = new Eligibility_Condition__c();
                    conditionRecord.Eligibility_Criteria__c = savedCriteria.Id;
                    conditionRecord.Sequence__c = parsedCondition.sequence;
                    conditionRecord.Object_API_Name__c = parsedCondition.objectApiName;
                    conditionRecord.Field_API_Name__c = parsedCondition.fieldApiName;
                    conditionRecord.Operator__c = parsedCondition.operatorToken;
                    conditionRecord.Value__c = parsedCondition.expectedValue;
                    conditionRecord.Logical_Operator__c = parsedCondition.logicalOperator;
                    conditionList.add(conditionRecord);
                }
            }

            if (!conditionList.isEmpty()) {
                insert conditionList;
            }

            return 'SUCCESS';
        } catch (EligibilityFormulaParser.EligibilityFormulaParserException parserException) {
            throw new AuraHandledException(parserException.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static Integer getNextCriteriaSequence(String yearlySchemeId) {
        List<AggregateResult> aggregateResults = [
            SELECT MAX(Sequence__c) maxSequence
            FROM Eligibility_Criteria__c
            WHERE Yearly_Scheme__c = :yearlySchemeId
        ];

        if (aggregateResults.isEmpty() || aggregateResults[0].get('maxSequence') == null) {
            return 1;
        }

        return Integer.valueOf(aggregateResults[0].get('maxSequence')) + 1;
    }

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
    //             if (fieldApiName != null && String.isBlank(String.valueOf(fieldApiName)) == false) {
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

    private static List<ConditionWrapper> parseConditionWrappers(String wrapperDataJson) {
        ConditionWrapper[] wrappers = (ConditionWrapper[]) JSON.deserialize(
            wrapperDataJson,
            ConditionWrapper[].class
        );
        return wrappers == null ? new List<ConditionWrapper>() : new List<ConditionWrapper>(wrappers);
    }

    public class ObjectFieldMaster {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public Map<String, String> fieldOptions;
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
        @AuraEnabled public String passMessage;
        @AuraEnabled public String failMessage;
        @AuraEnabled public String stage;
    }
}