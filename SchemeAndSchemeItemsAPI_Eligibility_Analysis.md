# SchemeAndSchemeItemsAPI & Eligibility Evaluation — Analysis

## Files reviewed

- `force-app/main/default/classes/SchemeAndSchemeItemsAPI.cls`
- `force-app/main/default/classes/EligibilityEvaluationService.cls`
- `force-app/main/default/classes/EligibilityFormulaParser.cls`
- `force-app/main/default/classes/EligibilityFormulaBuilderV2.cls`

---

## 1. What `SchemeAndSchemeItemsAPI.cls` does

`SchemeAndSchemeItemsAPI` is a `@RestResource(urlMapping='/schemeAndSchemeItems')` GET API. It is the public endpoint used by the portal/app to show schemes available to an applicant.

### Request

- Query parameter: `contactId`

### Main flow (`getSchemeAndSchemeItems`)

1. **Validate `contactId`**: returns an error if missing or no `Contact` record exists.
2. **Find the current active year**: queries `Year__c` where `Is_Active__c = true` and `Is_Current_Year__c = true`.
3. **Load active `Scheme__c` records**.
4. **Load active `Scheme_Items__c`** belonging to those schemes.
5. **Load active/public/approved `Yearly_Schemes__c`** for the current year and scheme items.
6. **Load existing applicant proposals**: queries `Applicant_Proposal_Association__c` for the contact and builds maps of proposal status/proposal id/apa id per yearly scheme.
7. **Call `EligibilityEvaluationService.evaluateYearlySchemes`** with the applicant contact and yearly scheme ids to get per-criteria eligibility results.
8. **Build the response** using wrapper classes (`SchemeDataWrapper`, `SchemeLineItemWrapper`, `YearlySchemeWrapper`, `EligibilityWrapper`, `ActionsWrapper`).

### Wrapper meaning

- `YearWrapper`: current year metadata.
- `SchemeDataWrapper`: scheme header with its child line items.
- `SchemeLineItemWrapper`: scheme item, duration label, linked yearly scheme, eligibility result, and action flags.
- `YearlySchemeWrapper`: yearly scheme details, dates, application status, external participants.
- `EligibilityWrapper`: `isEligible`, `canApply`, `hasConfiguredCriteria`, message, and per-criteria results.
- `ActionsWrapper`: `showEligibilityCheck`, `canApply`, URLs.
- `CriteriaResultWrapper`: one eligibility criteria, whether it passed, formula, validation type, etc.

---

## 2. How eligibility is calculated

The actual eligibility logic lives in `EligibilityEvaluationService.evaluateYearlySchemes`.

### 2.1 Load criteria

It queries `Eligibility_Criteria__c` plus child `Eligibility_Conditions__r` (sorted by `Sequence__c`) for the supplied yearly scheme ids, where `Is_Active__c = true`.

### 2.2 Build conditions

`buildConditions(Eligibility_Criteria__c record)` does one of two things:

- If the criteria already has child `Eligibility_Condition__c` records (saved conditions), it turns each child record into a `ParsedCondition`.
- If not, it parses `criteriaRecord.Formula__c` using `EligibilityFormulaParser.parse(...)`.

### 2.3 Formula parser

`EligibilityFormulaParser.parse(String formula)`

- Searches for `ObjectName.FieldName` patterns using `([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)`.
- Extracts the operator: `=`, `!=`, `>`, `<`, `>=`, `<=`, `+`, `-`.
- Extracts the expected value. Quoted strings like `'India'` are unquoted; unquoted numbers/booleans are kept as-is.
- Extracts the logical operator after the value: `AND` or `OR`.
- Throws `EligibilityFormulaParserException` if the formula is empty or has no valid `Object.Field` references.

### 2.4 Query contact

`queryContact(Id contactId, List<Eligibility_Criteria__c> criteriaRecords)`

- Collects every field whose `objectApiName == 'Contact'` and field name exists on the `Contact` schema.
- Builds a dynamic SOQL query: `SELECT <collected fields> FROM Contact WHERE Id = :contactId`.
- Only Contact fields are queried.

### 2.5 Evaluate criteria

`evaluateCriteriaRecords(...)` iterates over each `Eligibility_Criteria__c`:

1. Calls `evaluateCriteria(criteria, contactRecord)`.
2. `evaluateCriteria` builds conditions and evaluates each one with `evaluateCondition(condition, contactRecord)`.
3. Combines results using `AND` or `OR` depending on `Logical_Operator__c`.
4. If a criteria fails and `Validation_Type__c` contains `hard` or `stop`, the overall result becomes `isEligible = false`.
5. `canApply` is set to `isEligible`.
6. The overall message is either the success message or joined failure messages.

### 2.6 Value comparison (`compareValues`)

- `=` and `!=` compare trimmed string values ignoring case.
- `>`, `<`, `>=`, `<=` convert both sides to `Decimal` and compare.
- `+` and `-` treat the operation as `actualNumber +/- expectedNumber >= 0`.
- Non-numeric values for numeric operators return `false`.

### 2.7 Message building

- Pass message: uses `Pass_Message__c` with token replacement (`{label}`).
- Fail message: uses `Fail_Message__c` with tokens `{label}`, `{field}`, `{operator}`, `{expected}`, `{actual}`. If no fail message, it builds a default message using the contact field value.

---

## 3. Root cause: why only `Contact` objects work

There are three hard-coded Contact-only assumptions in `EligibilityEvaluationService.cls`.

### 3.1 `evaluateCondition` rejects every non-Contact object

```apex
private static final String OBJECT_CONTACT = 'Contact';

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
```

**Issue**: If `Object_API_Name__c` is anything other than `Contact` (for example `Account`, `Application__c`, `Proposal__c`, etc.), the method immediately returns `false`. The whole criteria fails because that condition is counted as not passed.

### 3.2 `isAllowedField` only checks `Contact` fields

```apex
private static Boolean isAllowedField(String fieldApiName) {
    Map<String, Schema.SObjectField> contactFieldMap = Schema.SObjectType.Contact.fields.getMap();
    return contactFieldMap.containsKey(fieldApiName.toLowerCase());
}
```

**Issue**: It never validates the field against the actual object written in the formula. A field from another object is always seen as invalid.

### 3.3 `queryContact` only fetches the `Contact` record

The dynamic SOQL is always `FROM Contact WHERE Id = :contactId`. Related records for other objects are never queried, so even if the code were changed to allow non-Contact fields, there would be no actual value to compare.

---

## 4. Why it works for `Contact`

When the formula creator selects `Contact` as the object:

- `condition.objectApiName` equals `Contact`.
- `isAllowedField` finds the field on the `Contact` schema.
- `queryContact` dynamically adds that field to the SOQL and retrieves its value.
- `compareValues` evaluates the field against the expected value.

So the entire path is designed around one single record: the `Contact` of the applicant.

---

## 5. What needs to change to support any object

A generic eligibility evaluator needs to:

1. **Group conditions by object** and determine the target record for each object.
   - `Contact` → the applicant's `Contact` record.
   - Other objects → usually related records reachable from the contact (`Account`, custom objects related by lookup, related list, etc.). You must define how the evaluator knows which record to use (e.g. the contact's `AccountId`, a child relationship, or a record passed in the API).

2. **Dynamically query or describe any object**.
   - Replace `isAllowedField` with a method that uses `Schema.getGlobalDescribe()` to validate the field on the object written in the condition.
   - Build dynamic SOQL per object, selecting only the fields referenced in the formula.

3. **Evaluate conditions with the correct record**.
   - Change `evaluateCondition` to fetch the actual record for `condition.objectApiName` and call `record.get(condition.fieldApiName)` on that object instead of always `contactRecord`.

4. **Update failure message helpers**.
   - `getFieldLabel` and `formatValue` currently assume a `Contact` field. They should accept the real object and record.

### Suggested high-level design

```text
EvaluateYearlySchemes(contactId, yearlySchemeIds)
  Load criteria + conditions for yearly schemes
  Parse/build conditions
  Group conditions by objectApiName
  Resolve target record per object (Contact = query Contact; others = query by related Id or configured relationship)
  For each criteria:
     For each condition:
        Get actual value from the record of condition.objectApiName
        Compare with expected value using the operator
        Combine with AND/OR
     Determine pass/fail and message
  Return results
```

---

## 6. Quick reference: formula creation flow

1. UI calls `EligibilityFormulaBuilderV2.getFieldMasterData()` to show active `Object_Master__c` and `Fields_Master__c` picklists.
2. User selects object, field, operator, value, and logical operator.
3. UI builds a formula string like `Contact.Research_Experience_After_Viva_Date_Yrs__c > 6 AND Contact.Qualifying_Degree__c = 'PhD'`.
4. `EligibilityFormulaBuilderV2.saveEligibilityCriteria(...)` parses the formula with `EligibilityFormulaParser`, inserts an `Eligibility_Criteria__c` parent, and inserts one `Eligibility_Condition__c` child per parsed condition.
5. `EligibilityEvaluationService` later reads those saved `Eligibility_Condition__c` records (or re-parses the formula) to evaluate the applicant.

---

## 7. Summary of the reported issue

**Symptom**: Eligibility criteria work when `Object Name = Contact` but fail for any other object.

**Root cause**: `EligibilityEvaluationService` is hard-coded to evaluate only `Contact` fields. It rejects non-Contact objects in `evaluateCondition`, validates fields only against the `Contact` schema, and never fetches records for other objects.

**Next step**: Redesign `EligibilityEvaluationService` to resolve and query the correct record for each `Object_API_Name__c` in the eligibility conditions instead of assuming every condition belongs to `Contact`.
