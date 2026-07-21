public with sharing class EligibilityFormulaBuilderV2 {

    // TODO: Remove after testing — hardcoded contact for Check Eligibility
    private static final Id TEST_CONTACT_ID = '003C300000qZ0s2IAC';    

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

    // --------------------------------------- Formula syntax + datatype check --------------------------------------- //

    public class FormulaSyntaxResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String message;
    }

    private class FormulaToken {
        public String type;
        public String value;
        public String valueKind; // NUMBER, BOOLEAN, STRING, UNQUOTED, FIELD

        public FormulaToken(String type, String value) {
            this.type = type;
            this.value = value;
        }

        public FormulaToken(String type, String value, String valueKind) {
            this.type = type;
            this.value = value;
            this.valueKind = valueKind;
        }
    }

    @AuraEnabled
    public static FormulaSyntaxResult checkFormulaSyntax(String formula) {
        FormulaSyntaxResult result = new FormulaSyntaxResult();

        if (String.isBlank(formula)) {
            result.isValid = false;
            result.message = 'Enter a formula before checking syntax.';
            return result;
        }

        List<FormulaToken> tokens = tokenizeFormula(formula.trim());

        if (tokens.isEmpty()) {
            result.isValid = false;
            result.message = 'Formula must include at least one Object.Field reference.';
            return result;
        }

        String expect = 'TERM';
        Integer parenDepth = 0;

        for (FormulaToken token : tokens) {
            if (expect == 'TERM') {
                if (token.type == 'LPAREN') {
                    parenDepth++;
                    continue;
                }
                if (token.type == 'FIELD') {
                    expect = 'COMPARISON';
                    continue;
                }
                result.isValid = false;
                result.message = 'Unexpected "' + token.value + '". Expected a field or "(".';
                return result;
            }

            if (expect == 'COMPARISON') {
                if (token.type == 'COMPARISON') {
                    expect = 'OPERAND';
                    continue;
                }
                result.isValid = false;
                result.message = 'Operator is required after field. Unexpected "' + token.value + '".';
                return result;
            }

            if (expect == 'OPERAND') {
                if (token.type == 'UNQUOTED') {
                    result.isValid = false;
                    result.message =
                        'Text values must be in quotes, e.g. \'' + token.value + '\'.';
                    return result;
                }
                if (token.type == 'VALUE' || token.type == 'FIELD') {
                    expect = 'AFTER';
                    continue;
                }
                result.isValid = false;
                result.message = 'Value or field is required after the operator. Unexpected "' + token.value + '".';
                return result;
            }

            if (expect == 'AFTER') {
                if (token.type == 'RPAREN') {
                    parenDepth--;
                    if (parenDepth < 0) {
                        result.isValid = false;
                        result.message = 'Unexpected ")". Check parentheses.';
                        return result;
                    }
                    continue;
                }
                if (token.type == 'LOGICAL') {
                    expect = 'TERM';
                    continue;
                }
                if (token.type == 'UNQUOTED') {
                    result.isValid = false;
                    result.message =
                        'Text values must be in quotes, e.g. \'' + token.value + '\'.';
                    return result;
                }
                result.isValid = false;
                result.message = 'Unexpected "' + token.value + '". Use AND / OR to combine conditions, or ")".';
                return result;
            }
        }

        if (parenDepth != 0) {
            result.isValid = false;
            result.message = 'Parentheses are unbalanced. Add the missing ")" or "(".';
            return result;
        }

        if (expect != 'AFTER') {
            result.isValid = false;
            if (expect == 'COMPARISON') {
                result.message = 'Operator is required after the field.';
            } else if (expect == 'OPERAND') {
                result.message = 'Value or field is required after the operator.';
            } else if (expect == 'TERM') {
                result.message = 'Formula is incomplete. Insert a field after AND / OR or "(".';
            } else {
                result.message = 'Formula structure is incomplete.';
            }
            return result;
        }

        FormulaSyntaxResult typeResult = validateOperandDataTypes(tokens);
        if (!typeResult.isValid) {
            return typeResult;
        }

        result.isValid = true;
        result.message = 'No syntax errors in formula.';
        return result;
    }

    private static FormulaSyntaxResult validateOperandDataTypes(List<FormulaToken> tokens) {
        FormulaSyntaxResult result = new FormulaSyntaxResult();
        result.isValid = true;

        for (Integer index = 0; index < tokens.size() - 2; index++) {
            FormulaToken leftToken = tokens[index];
            FormulaToken operatorToken = tokens[index + 1];
            FormulaToken operandToken = tokens[index + 2];

            if (leftToken.type != 'FIELD' || operatorToken.type != 'COMPARISON') {
                continue;
            }
            if (operandToken.type != 'VALUE' && operandToken.type != 'FIELD') {
                continue;
            }

            Schema.DisplayType leftType = resolveFieldDisplayType(leftToken.value);
            if (leftType == null) {
                result.isValid = false;
                result.message =
                    'Unknown field "' + leftToken.value + '". Check the Object.Field API names.';
                return result;
            }

            if (operandToken.type == 'FIELD') {
                Schema.DisplayType rightType = resolveFieldDisplayType(operandToken.value);
                if (rightType == null) {
                    result.isValid = false;
                    result.message =
                        'Unknown field "' + operandToken.value + '". Check the Object.Field API names.';
                    return result;
                }
                if (!areDisplayTypesCompatible(leftType, rightType)) {
                    result.isValid = false;
                    result.message =
                        'Datatype mismatch: ' +
                        leftToken.value +
                        ' (' +
                        String.valueOf(leftType) +
                        ') cannot be compared with ' +
                        operandToken.value +
                        ' (' +
                        String.valueOf(rightType) +
                        ').';
                    return result;
                }
                continue;
            }

            String expectedKind = expectedValueKindForDisplayType(leftType);
            String actualKind = operandToken.valueKind;

            if (expectedKind != null && actualKind != null && expectedKind != actualKind) {
                result.isValid = false;
                result.message = buildDatatypeMismatchMessage(
                    leftToken.value,
                    leftType,
                    expectedKind,
                    actualKind,
                    operandToken.value
                );
                return result;
            }
        }

        return result;
    }

    private static String buildDatatypeMismatchMessage(
        String fieldReference,
        Schema.DisplayType fieldType,
        String expectedKind,
        String actualKind,
        String actualValue
    ) {
        if (expectedKind == 'NUMBER') {
            return
                'Datatype mismatch: ' +
                fieldReference +
                ' is a Number field and requires a numeric value (e.g. 25), not "' +
                actualValue +
                '".';
        }
        if (expectedKind == 'BOOLEAN') {
            return
                'Datatype mismatch: ' +
                fieldReference +
                ' is a Checkbox field and requires true or false.';
        }
        if (expectedKind == 'STRING') {
            return
                'Datatype mismatch: ' +
                fieldReference +
                ' is a Text field and requires a quoted value (e.g. \'India\'), not a ' +
                actualKind.toLowerCase() +
                '.';
        }
        return
            'Datatype mismatch for ' +
            fieldReference +
            ' (' +
            String.valueOf(fieldType) +
            '). Expected ' +
            expectedKind +
            ' but found ' +
            actualKind +
            '.';
    }

    private static String expectedValueKindForDisplayType(Schema.DisplayType displayType) {
        if (
            displayType == Schema.DisplayType.INTEGER ||
            displayType == Schema.DisplayType.DOUBLE ||
            displayType == Schema.DisplayType.LONG ||
            displayType == Schema.DisplayType.CURRENCY ||
            displayType == Schema.DisplayType.PERCENT
        ) {
            return 'NUMBER';
        }
        if (displayType == Schema.DisplayType.BOOLEAN) {
            return 'BOOLEAN';
        }
        if (
            displayType == Schema.DisplayType.STRING ||
            displayType == Schema.DisplayType.TEXTAREA ||
            displayType == Schema.DisplayType.EMAIL ||
            displayType == Schema.DisplayType.PHONE ||
            displayType == Schema.DisplayType.URL ||
            displayType == Schema.DisplayType.PICKLIST ||
            displayType == Schema.DisplayType.MULTIPICKLIST ||
            displayType == Schema.DisplayType.COMBOBOX ||
            displayType == Schema.DisplayType.ID ||
            displayType == Schema.DisplayType.REFERENCE ||
            displayType == Schema.DisplayType.ADDRESS ||
            displayType == Schema.DisplayType.BASE64 ||
            displayType == Schema.DisplayType.ENCRYPTEDSTRING
        ) {
            return 'STRING';
        }
        if (
            displayType == Schema.DisplayType.DATE ||
            displayType == Schema.DisplayType.DATETIME ||
            displayType == Schema.DisplayType.TIME
        ) {
            // Accept quoted text literals for date/time values for now.
            return 'STRING';
        }
        return 'STRING';
    }

    private static Boolean areDisplayTypesCompatible(
        Schema.DisplayType leftType,
        Schema.DisplayType rightType
    ) {
        String leftKind = expectedValueKindForDisplayType(leftType);
        String rightKind = expectedValueKindForDisplayType(rightType);
        return leftKind == rightKind;
    }

    private static Schema.DisplayType resolveFieldDisplayType(String fieldReference) {
        if (String.isBlank(fieldReference) || !fieldReference.contains('.')) {
            return null;
        }

        List<String> parts = fieldReference.split('\\.');
        if (parts.size() != 2) {
            return null;
        }

        String objectApiName = parts[0];
        String fieldApiName = parts[1];

        Schema.SObjectType objectType = findSObjectType(objectApiName);
        if (objectType == null) {
            return null;
        }

        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        Schema.SObjectField fieldToken = fieldMap.get(fieldApiName.toLowerCase());
        if (fieldToken == null) {
            return null;
        }

        return fieldToken.getDescribe().getType();
    }

    private static Schema.SObjectType findSObjectType(String objectApiName) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (globalDescribe.containsKey(objectApiName)) {
            return globalDescribe.get(objectApiName);
        }

        String lowerName = objectApiName.toLowerCase();
        for (String key : globalDescribe.keySet()) {
            if (key != null && key.toLowerCase() == lowerName) {
                return globalDescribe.get(key);
            }
        }
        return null;
    }

    private static List<FormulaToken> tokenizeFormula(String formula) {
        List<FormulaToken> tokens = new List<FormulaToken>();
        Pattern tokenPattern = Pattern.compile(
            '(?i)\\(|\\)|>=|<=|!=|=|>|<|\\+|-|\\bAND\\b|\\bOR\\b|\'[^\']*\'|"[^"]*"|\\d+(\\.\\d+)?|true|false|[A-Za-z_][A-Za-z0-9_]*\\.[A-Za-z_][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_]*'
        );
        Matcher matcher = tokenPattern.matcher(formula);

        while (matcher.find()) {
            String token = matcher.group();
            String upper = token.toUpperCase();

            if (token == '(') {
                tokens.add(new FormulaToken('LPAREN', token));
            } else if (token == ')') {
                tokens.add(new FormulaToken('RPAREN', token));
            } else if (upper == 'AND' || upper == 'OR') {
                tokens.add(new FormulaToken('LOGICAL', upper));
            } else if (
                token == '=' ||
                token == '!=' ||
                token == '>' ||
                token == '<' ||
                token == '>=' ||
                token == '<=' ||
                token == '+' ||
                token == '-'
            ) {
                tokens.add(new FormulaToken('COMPARISON', token));
            } else if (token.contains('.')) {
                tokens.add(new FormulaToken('FIELD', token, 'FIELD'));
            } else if (upper == 'TRUE' || upper == 'FALSE') {
                tokens.add(new FormulaToken('VALUE', upper.toLowerCase(), 'BOOLEAN'));
            } else if (token.startsWith('\'') || token.startsWith('"')) {
                String unquoted = token.substring(1, token.length() - 1);
                tokens.add(new FormulaToken('VALUE', unquoted, 'STRING'));
            } else if (isDecimalToken(token)) {
                tokens.add(new FormulaToken('VALUE', token, 'NUMBER'));
            } else {
                // Bare word like India — not valid without quotes
                tokens.add(new FormulaToken('UNQUOTED', token, 'UNQUOTED'));
            }
        }

        return tokens;
    }

    private static Boolean isDecimalToken(String token) {
        if (String.isBlank(token)) {
            return false;
        }
        Pattern decimalPattern = Pattern.compile('^\\d+(\\.\\d+)?$');
        return decimalPattern.matcher(token).matches();
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