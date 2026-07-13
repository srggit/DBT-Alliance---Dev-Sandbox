public without sharing class EligibilityEvaluationService {

    private static final String OBJECT_CONTACT = 'Contact';

    @AuraEnabled
    public static EligibilityEvaluationResult evaluateYearlySchemeForCurrentUser(String yearlySchemeId) {
        Id contactId = resolveCurrentUserContactId();
        return evaluateYearlyScheme(contactId, yearlySchemeId);
    }

    @AuraEnabled
    public static EligibilityEvaluationResult evaluateYearlyScheme(Id contactId, Id yearlySchemeId) {
        if (contactId == null) {
            throw new AuraHandledException(
                'Contact is required for eligibility check. Provide a Contact Id or link one to the user.'
            );
        }

        if (yearlySchemeId == null) {
            throw new AuraHandledException('Yearly Scheme is required.');
        }

        try {
            return evaluateYearlySchemeInternal(contactId, yearlySchemeId);
        } catch (AuraHandledException handledException) {
            throw handledException;
        } catch (Exception ex) {
            throw new AuraHandledException('Eligibility check failed: ' + ex.getMessage());
        }
    }

    private static EligibilityEvaluationResult evaluateYearlySchemeInternal(
        Id contactId,
        Id yearlySchemeId
    ) {
        List<Eligibility_Criteria__c> criteriaRecords = [
            SELECT
                Id,
                Name,
                Sequence__c,
                Validation_Type__c,
                Eligibility_Type__c,
                Formula__c,
                (
                    SELECT
                        Id,
                        Sequence__c,
                        Object_API_Name__c,
                        Field_API_Name__c,
                        Operator__c,
                        Value__c,
                        Logical_Operator__c
                    FROM Eligibility_Conditions__r
                    ORDER BY Sequence__c ASC
                )
            FROM Eligibility_Criteria__c
            WHERE Yearly_Scheme__c = :yearlySchemeId
            ORDER BY Sequence__c ASC NULLS LAST, CreatedDate ASC
        ];

        EligibilityEvaluationResult evaluationResult = new EligibilityEvaluationResult();
        evaluationResult.criteriaResults = new List<CriteriaResult>();
        evaluationResult.isEligible = true;

        if (criteriaRecords.isEmpty()) {
            evaluationResult.hasConfiguredCriteria = false;
            evaluationResult.overallMessage = 'No eligibility criteria configured for this scheme.';
            evaluationResult.canApply = true;
            return evaluationResult;
        }

        evaluationResult.hasConfiguredCriteria = true;
        Contact contactRecord = queryContact(contactId, criteriaRecords);
        List<String> failureMessages = new List<String>();

        for (Eligibility_Criteria__c criteriaRecord : criteriaRecords) {
            CriteriaResult criteriaResult = evaluateCriteria(criteriaRecord, contactRecord);
            evaluationResult.criteriaResults.add(criteriaResult);

            if (!criteriaResult.passed && isHardStop(criteriaRecord.Validation_Type__c)) {
                evaluationResult.isEligible = false;
                failureMessages.add(criteriaResult.message);
            }
        }

        evaluationResult.canApply = evaluationResult.isEligible;
        evaluationResult.overallMessage = evaluationResult.isEligible
            ? 'You are eligible to apply for this scheme.'
            : String.join(failureMessages, ' ');

        return evaluationResult;
    }

    public static EligibilityEvaluationResult evaluateYearlyScheme(Contact contactRecord, Id yearlySchemeId) {
        return evaluateYearlyScheme(contactRecord.Id, yearlySchemeId);
    }

    private static CriteriaResult evaluateCriteria(
        Eligibility_Criteria__c criteriaRecord,
        Contact contactRecord
    ) {
        CriteriaResult criteriaResult = new CriteriaResult();
        criteriaResult.criteriaId = criteriaRecord.Id;
        criteriaResult.criteriaLabel = String.isNotBlank(criteriaRecord.Name)
            ? criteriaRecord.Name
            : 'Eligibility Criteria';
        criteriaResult.formula = criteriaRecord.Formula__c;
        criteriaResult.validationType = criteriaRecord.Validation_Type__c;
        criteriaResult.eligibilityType = criteriaRecord.Eligibility_Type__c;

        List<EligibilityFormulaParser.ParsedCondition> conditions = buildConditions(criteriaRecord);

        if (conditions.isEmpty()) {
            criteriaResult.passed = false;
            criteriaResult.message = 'No valid conditions found for ' + criteriaResult.criteriaLabel + '.';
            return criteriaResult;
        }

        Boolean combinedResult = null;

        for (EligibilityFormulaParser.ParsedCondition condition : conditions) {
            Boolean conditionPassed = evaluateCondition(condition, contactRecord);

            if (combinedResult == null) {
                combinedResult = conditionPassed;
                continue;
            }

            if (condition.logicalOperator == 'OR') {
                combinedResult = combinedResult || conditionPassed;
            } else {
                combinedResult = combinedResult && conditionPassed;
            }
        }

        criteriaResult.passed = combinedResult == true;
        criteriaResult.message = criteriaResult.passed
            ? criteriaResult.criteriaLabel + ' requirement met.'
            : buildFailureMessage(
                criteriaResult.criteriaLabel,
                contactRecord,
                conditions
            );

        return criteriaResult;
    }

    private static List<EligibilityFormulaParser.ParsedCondition> buildConditions(
        Eligibility_Criteria__c criteriaRecord
    ) {
        if (criteriaRecord.Eligibility_Conditions__r != null && !criteriaRecord.Eligibility_Conditions__r.isEmpty()) {
            List<EligibilityFormulaParser.ParsedCondition> parsedConditions =
                new List<EligibilityFormulaParser.ParsedCondition>();

            for (Eligibility_Condition__c conditionRecord : criteriaRecord.Eligibility_Conditions__r) {
                EligibilityFormulaParser.ParsedCondition parsedCondition =
                    new EligibilityFormulaParser.ParsedCondition();
                parsedCondition.sequence = conditionRecord.Sequence__c != null
                    ? Integer.valueOf(conditionRecord.Sequence__c)
                    : parsedConditions.size() + 1;
                parsedCondition.objectApiName = conditionRecord.Object_API_Name__c;
                parsedCondition.fieldApiName = conditionRecord.Field_API_Name__c;
                parsedCondition.operatorToken = conditionRecord.Operator__c;
                parsedCondition.expectedValue = conditionRecord.Value__c;
                parsedCondition.logicalOperator = conditionRecord.Logical_Operator__c;
                parsedConditions.add(parsedCondition);
            }

            return parsedConditions;
        }

        return EligibilityFormulaParser.parse(criteriaRecord.Formula__c);
    }

    private static Boolean evaluateCondition(
        EligibilityFormulaParser.ParsedCondition condition,
        Contact contactRecord
    ) {
        if (condition.objectApiName != OBJECT_CONTACT) {
            return false;
        }

        if (!isAllowedField(condition.fieldApiName)) {
            return false;
        }

        Object actualValue = contactRecord.get(condition.fieldApiName);
        return compareValues(actualValue, condition.operatorToken, condition.expectedValue, condition.fieldApiName);
    }

    private static Boolean compareValues(
        Object actualValue,
        String operatorToken,
        String expectedValue,
        String fieldApiName
    ) {
        if (operatorToken == '=' || operatorToken == '!=') {
            String actualAsString = formatValue(actualValue, fieldApiName);
            Boolean isEqual = actualAsString.equalsIgnoreCase(String.valueOf(expectedValue).trim());

            if (operatorToken == '=') {
                return isEqual;
            }

            return !isEqual;
        }

        Decimal actualNumber = toDecimal(actualValue);
        Decimal expectedNumber = toDecimal(expectedValue);

        if (actualNumber == null || expectedNumber == null) {
            return false;
        }

        if (operatorToken == '>') {
            return actualNumber > expectedNumber;
        }
        if (operatorToken == '<') {
            return actualNumber < expectedNumber;
        }
        if (operatorToken == '>=') {
            return actualNumber >= expectedNumber;
        }
        if (operatorToken == '<=') {
            return actualNumber <= expectedNumber;
        }
        if (operatorToken == '+') {
            return actualNumber + expectedNumber >= 0;
        }
        if (operatorToken == '-') {
            return actualNumber - expectedNumber >= 0;
        }

        return false;
    }

    private static String buildFailureMessage(
        String criteriaLabel,
        Contact contactRecord,
        List<EligibilityFormulaParser.ParsedCondition> conditions
    ) {
        List<String> detailMessages = new List<String>();

        for (EligibilityFormulaParser.ParsedCondition condition : conditions) {
            if (evaluateCondition(condition, contactRecord)) {
                continue;
            }

            String actualValue = formatValue(
                contactRecord.get(condition.fieldApiName),
                condition.fieldApiName
            );
            detailMessages.add(
                getFieldLabel(condition.fieldApiName) +
                ' required ' +
                condition.operatorToken +
                ' ' +
                condition.expectedValue +
                '. Your value: ' +
                actualValue +
                '.'
            );
        }

        if (detailMessages.isEmpty()) {
            return criteriaLabel + ' requirement not met.';
        }

        return criteriaLabel + ' requirement not met. ' + String.join(detailMessages, ' ');
    }

    private static Contact queryContact(Id contactId, List<Eligibility_Criteria__c> criteriaRecords) {
        Set<String> fieldApiNames = new Set<String>{ 'Id', 'Name' };

        for (Eligibility_Criteria__c criteriaRecord : criteriaRecords) {
            List<EligibilityFormulaParser.ParsedCondition> conditions = buildConditions(criteriaRecord);

            for (EligibilityFormulaParser.ParsedCondition condition : conditions) {
                if (condition.objectApiName == OBJECT_CONTACT && isAllowedField(condition.fieldApiName)) {
                    fieldApiNames.add(condition.fieldApiName);
                }
            }
        }

        String contactQuery =
            'SELECT ' +
            String.join(new List<String>(fieldApiNames), ', ') +
            ' FROM Contact WHERE Id = :contactId LIMIT 1';

        List<Contact> contacts = Database.query(contactQuery);

        if (contacts.isEmpty()) {
            throw new AuraHandledException(
                'Contact record not found or not accessible: ' + contactId
            );
        }

        return contacts[0];
    }

    private static Boolean isAllowedField(String fieldApiName) {
        if (String.isBlank(fieldApiName)) {
            return false;
        }

        Map<String, Schema.SObjectField> contactFieldMap = Schema.SObjectType.Contact.fields.getMap();
        return contactFieldMap.containsKey(fieldApiName.toLowerCase());
    }

    private static String getFieldLabel(String fieldApiName) {
        Map<String, Schema.SObjectField> contactFieldMap = Schema.SObjectType.Contact.fields.getMap();
        Schema.SObjectField fieldToken = contactFieldMap.get(fieldApiName.toLowerCase());

        if (fieldToken == null) {
            return fieldApiName;
        }

        return fieldToken.getDescribe().getLabel();
    }

    private static String formatValue(Object fieldValue, String fieldApiName) {
        if (fieldValue == null) {
            return 'not provided';
        }

        if (fieldValue instanceof Boolean) {
            return String.valueOf(fieldValue);
        }

        if (fieldValue instanceof Date) {
            return String.valueOf((Date) fieldValue);
        }

        if (fieldValue instanceof Datetime) {
            return String.valueOf((Datetime) fieldValue);
        }

        return String.valueOf(fieldValue);
    }

    private static Decimal toDecimal(Object fieldValue) {
        if (fieldValue == null) {
            return null;
        }

        if (fieldValue instanceof Decimal) {
            return (Decimal) fieldValue;
        }

        if (fieldValue instanceof Integer) {
            return Decimal.valueOf((Integer) fieldValue);
        }

        if (fieldValue instanceof Long) {
            return Decimal.valueOf((Long) fieldValue);
        }

        if (fieldValue instanceof Double) {
            return Decimal.valueOf((Double) fieldValue);
        }

        if (fieldValue instanceof Boolean) {
            return (Boolean) fieldValue ? 1 : 0;
        }

        String stringValue = String.valueOf(fieldValue).trim();
        if (String.isBlank(stringValue)) {
            return null;
        }

        try {
            return Decimal.valueOf(stringValue);
        } catch (Exception ex) {
            return null;
        }
    }

    private static Boolean isHardStop(String validationType) {
        if (String.isBlank(validationType)) {
            return true;
        }

        String normalizedValidationType = validationType.trim().toLowerCase();
        return normalizedValidationType.contains('hard') || normalizedValidationType.contains('stop');
    }

    private static Id resolveCurrentUserContactId() {
        List<User> users = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        return users.isEmpty() ? null : users[0].ContactId;
    }

    public class EligibilityEvaluationResult {
        @AuraEnabled
        public Boolean isEligible;
        @AuraEnabled
        public Boolean canApply;
        @AuraEnabled
        public Boolean hasConfiguredCriteria;
        @AuraEnabled
        public String overallMessage;
        @AuraEnabled
        public List<CriteriaResult> criteriaResults;
    }

    public class CriteriaResult {
        @AuraEnabled
        public String criteriaId;
        @AuraEnabled
        public String criteriaLabel;
        @AuraEnabled
        public Boolean passed;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String formula;
        @AuraEnabled
        public String validationType;
        @AuraEnabled
        public String eligibilityType;
    }
}
