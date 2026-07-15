import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ELIGIBILITY_CRITERIA_OBJECT from '@salesforce/schema/Eligibility_Criteria__c';
import VALIDATION_TYPE_FIELD from '@salesforce/schema/Eligibility_Criteria__c.Validation_Type__c';
import ELIGIBILITY_TYPE_FIELD from '@salesforce/schema/Eligibility_Criteria__c.Eligibility_Type__c';

import saveEligibilityCriteriaApex from '@salesforce/apex/EligibilityFormulaBuilderV2.saveEligibilityCriteria';
import checkEligibilityApex from '@salesforce/apex/EligibilityFormulaBuilderV2.checkEligibility';
import getFieldMasterData from '@salesforce/apex/EligibilityFormulaBuilderV2.getFieldMasterData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// TODO: Remove after testing — hardcoded contact for Check Eligibility
const TEST_CONTACT_ID = '003C300000qEWm0IAG';

export default class EligibilityFormulaBuilderV2 extends LightningElement {

    formulaText = '';
    cursorPosition = 0;
    cursorEnd = 0;

    objectName = '';
    fieldName = '';

    objectOptions = [];
    fieldOptions = [];
    fieldMasterMap = {};

    selectedValidationType = '';
    selectedEligibilityType = '';
    criteriaLabel = '';
    passMessage = '';
    failMessage = '';

    validationTypeOptions = [];
    eligibilityTypeOptions = [];

    showResultsModal = false;
    isCheckingEligibility = false;
    eligibilitySummary = null;
    criteriaResults = [];

    @api recordId;

    editorState = 'ready';
    valueStartPosition = null;

    comparisonOperatorTokens = [' = ', ' != ', ' > ', ' < ', ' >= ', ' <= ', ' + ', ' - '];

    operatorTokens = [
        { label: '=', token: ' = ' },
        { label: '+', token: ' + ' },
        { label: '-', token: ' - ' },
        { label: '!=', token: ' != ' },
        { label: '>', token: ' > ' },
        { label: '<', token: ' < ' },
        { label: '>=', token: ' >= ' },
        { label: '<=', token: ' <= ' },
        { label: 'AND', token: ' AND ' },
        { label: 'OR', token: ' OR ' },
        { label: '(', token: '(' },
        { label: ')', token: ')' }
    ];

    @wire(CurrentPageReference)
    resolveRecordId(currentPageReference) {
        if (!this.recordId && currentPageReference) {
            this.recordId =
                currentPageReference.attributes?.recordId ||
                currentPageReference.state?.recordId ||
                currentPageReference.state?.c__recordId;
        }
    }

    @wire(getObjectInfo, { objectApiName: ELIGIBILITY_CRITERIA_OBJECT })
    eligibilityCriteriaObjectInfo;

    @wire(getFieldMasterData)
    wiredFieldMasterData({ data, error }) {
        if (data) {
            this.fieldMasterMap = {};
            this.objectOptions = data
                .map((entry) => {
                    this.fieldMasterMap[entry.objectApiName] = {
                        objectLabel: entry.objectLabel,
                        fieldOptions: entry.fieldOptions || {}
                    };

                    return {
                        label: entry.objectLabel,
                        value: entry.objectApiName
                    };
                })
                .sort((firstOption, secondOption) =>
                    firstOption.label.localeCompare(secondOption.label)
                );
        } else if (error) {
            console.error('Error loading field master data:', error);
            this.showToast(
                'Error',
                error.body?.message || 'Failed to load field master data.',
                'error'
            );
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: VALIDATION_TYPE_FIELD
    })
    wiredValidationTypePicklist({ data }) {
        if (data) {
            this.validationTypeOptions = data.values.map((entry) => ({
                label: entry.label,
                value: entry.value
            }));

            if (!this.selectedValidationType && this.validationTypeOptions.length) {
                this.selectedValidationType = this.validationTypeOptions[0].value;
            }
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: ELIGIBILITY_TYPE_FIELD
    })
    wiredEligibilityTypePicklist({ data }) {
        if (data) {
            this.eligibilityTypeOptions = data.values.map((entry) => ({
                label: entry.label,
                value: entry.value
            }));

            if (!this.selectedEligibilityType && this.eligibilityTypeOptions.length) {
                this.selectedEligibilityType = this.eligibilityTypeOptions[0].value;
            }
        }
    }

    get defaultRecordTypeId() {
        return this.eligibilityCriteriaObjectInfo?.data?.defaultRecordTypeId;
    }

    get isFieldPicklistDisabled() {
        return !this.objectName;
    }

    get canInsertField() {
        return this.editorState === 'ready';
    }

    get isInsertFieldDisabled() {
        return !this.canInsertField;
    }

    get editorStateClass() {
        if (this.isAwaitingOperator || this.isAwaitingValue) {
            return 'editor-state-hint editor-state-hint_warning slds-var-m-bottom_x-small';
        }

        return 'editor-state-hint slds-text-color_weak slds-var-m-bottom_x-small';
    }

    get isAwaitingOperator() {
        return this.editorState === 'awaiting_operator';
    }

    get isAwaitingValue() {
        return this.editorState === 'awaiting_value';
    }

    get operatorTokensWithState() {
        return this.operatorTokens.map((operator) => {
            const isComparison = this.comparisonOperatorTokens.includes(operator.token);

            return {
                ...operator,
                isComparison,
                disabled: isComparison
                    ? this.editorState !== 'awaiting_operator'
                    : this.editorState === 'awaiting_operator' || this.editorState === 'awaiting_value'
            };
        });
    }

    get editorStateMessage() {
        if (this.isAwaitingOperator) {
            return 'Field inserted. Select an operator to continue.';
        }

        if (this.isAwaitingValue) {
            return 'Operator inserted. Type a value in the formula editor to continue.';
        }

        return 'Each field must be followed by an operator and a value.';
    }

    get hasCriteriaResults() {
        return this.criteriaResults.length > 0;
    }

    get overallStatusClass() {
        if (!this.eligibilitySummary) {
            return 'eligibility-summary';
        }

        return this.eligibilitySummary.isEligible
            ? 'eligibility-summary eligibility-summary_pass'
            : 'eligibility-summary eligibility-summary_fail';
    }

    isComparisonToken(token) {
        return this.comparisonOperatorTokens.includes(token);
    }

    syncEditorStateFromFormula() {
        const validation = this.validateFormulaStructure(this.formulaText);
        if (validation.valid) {
            this.editorState = 'ready';
            this.valueStartPosition = null;
            return;
        }

        if (validation.pendingState) {
            this.editorState = validation.pendingState;
        }
    }

    loadFieldOptionsForObject(objectApiName) {
        const fieldOptionsByLabel = this.fieldMasterMap[objectApiName]?.fieldOptions || {};
        this.fieldOptions = Object.keys(fieldOptionsByLabel)
            .sort()
            .map((fieldLabel) => ({
                label: fieldLabel,
                value: fieldOptionsByLabel[fieldLabel]
            }));
    }

    getFormulaTextarea() {
        return this.template.querySelector('[data-id="formula-editor"]');
    }

    updateCursorPosition() {
        const textarea = this.getFormulaTextarea();
        if (textarea) {
            this.cursorPosition = textarea.selectionStart ?? this.formulaText.length;
            this.cursorEnd = textarea.selectionEnd ?? this.cursorPosition;
            this.formulaText = textarea.value;
        }
    }

    insertAtCursor(text) {
        const textarea = this.getFormulaTextarea();
        if (!textarea) {
            return;
        }

        const start = textarea.selectionStart ?? textarea.value.length;
        const end = textarea.selectionEnd ?? start;
        const before = textarea.value.substring(0, start);
        const after = textarea.value.substring(end);

        textarea.value = `${before}${text}${after}`;
        this.formulaText = textarea.value;

        const newPosition = start + text.length;
        textarea.focus();
        textarea.setSelectionRange(newPosition, newPosition);
        this.cursorPosition = newPosition;
        this.cursorEnd = newPosition;
    }

    handleFormulaInput(event) {
        this.formulaText = event.target.value;
        this.cursorPosition = event.target.selectionStart;
        this.cursorEnd = event.target.selectionEnd;

        if (this.editorState === 'awaiting_value' && this.valueStartPosition !== null) {
            const valuePart = this.formulaText.substring(this.valueStartPosition).trim();

            if (valuePart) {
                this.editorState = 'ready';
                this.valueStartPosition = null;
            }
        } else if (!this.formulaText.trim()) {
            this.editorState = 'ready';
            this.valueStartPosition = null;
        } else {
            this.syncEditorStateFromFormula();
        }
    }

    handleFormulaSelectionChange() {
        this.updateCursorPosition();
    }

    handleObjectChange(event) {
        this.objectName = event.detail.value;
        this.fieldName = '';
        this.fieldOptions = [];

        if (this.objectName) {
            this.loadFieldOptionsForObject(this.objectName);
        }
    }

    handleFieldChange(event) {
        this.fieldName = event.detail.value;
    }

    handleValidationTypeChange(event) {
        this.selectedValidationType = event.detail.value;
    }

    handleEligibilityTypeChange(event) {
        this.selectedEligibilityType = event.detail.value;
    }

    handleCriteriaLabelChange(event) {
        this.criteriaLabel = event.detail.value;
    }

    handlePassMessageChange(event) {
        this.passMessage = event.detail.value;
    }

    handleFailMessageChange(event) {
        this.failMessage = event.detail.value;
    }

    handleInsertObject() {
        if (!this.objectName) {
            this.showToast('Error', 'Select an Object to insert.', 'error');
            return;
        }

        this.insertAtCursor(this.objectName);
    }

    handleInsertField() {
        if (!this.canInsertField) {
            this.showToast(
                'Error',
                this.isAwaitingOperator
                    ? 'Select an operator after the field before inserting another field.'
                    : 'Enter a value after the operator before inserting another field.',
                'error'
            );
            return;
        }

        if (!this.fieldName) {
            this.showToast('Error', 'Select a Field to insert.', 'error');
            return;
        }

        const fieldReference = this.objectName
            ? `${this.objectName}.${this.fieldName}`
            : this.fieldName;

        this.insertAtCursor(fieldReference);
        this.editorState = 'awaiting_operator';
        this.valueStartPosition = null;
    }

    handleInsertOperator(event) {
        const token = event.currentTarget.dataset.token;
        if (!token) {
            return;
        }

        const isComparison = this.isComparisonToken(token);

        if (isComparison) {
            if (this.editorState !== 'awaiting_operator') {
                this.showToast('Error', 'Insert a field before adding an operator.', 'error');
                return;
            }

            this.insertAtCursor(token);
            this.editorState = 'awaiting_value';
            this.valueStartPosition = this.cursorPosition;
            return;
        }

        if (this.editorState === 'awaiting_operator') {
            this.showToast('Error', 'Select an operator after the field.', 'error');
            return;
        }

        if (this.editorState === 'awaiting_value') {
            this.showToast('Error', 'Complete the value before adding AND, OR, or parentheses.', 'error');
            return;
        }

        this.insertAtCursor(token);
    }

    validateFormulaStructure(formula) {
        const text = (formula || '').trim();

        if (!text) {
            return { valid: false, message: 'Enter a formula before saving.' };
        }

        const fieldPattern = /[A-Za-z0-9_]+\.[A-Za-z0-9_]+/g;
        const fieldMatches = [...text.matchAll(fieldPattern)];

        if (!fieldMatches.length) {
            return {
                valid: false,
                message: 'Formula must include at least one Object.Field reference.'
            };
        }

        let pendingState = 'ready';

        for (const fieldMatch of fieldMatches) {
            const fieldReference = fieldMatch[0];
            const afterField = text.substring(fieldMatch.index + fieldReference.length);
            const operatorMatch = afterField.match(/^\s*(>=|<=|!=|\+|-|=|>|<)\s+/);

            if (!operatorMatch) {
                return {
                    valid: false,
                    message: `Operator is required after ${fieldReference}.`,
                    pendingState: 'awaiting_operator'
                };
            }

            const afterOperator = afterField.substring(operatorMatch[0].length);
            const valueMatch = afterOperator.match(/^('[^']*'|[^\s)]+)/);

            if (!valueMatch || !valueMatch[1].trim()) {
                return {
                    valid: false,
                    message: `Value is required after the operator for ${fieldReference}.`,
                    pendingState: 'awaiting_value'
                };
            }
        }

        return { valid: true };
    }

    parseFormulaMetadata(formula) {
        const trimmedFormula = (formula || '').trim();
        const fieldReferenceMatch = trimmedFormula.match(/([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)/);

        return {
            objectName: fieldReferenceMatch ? fieldReferenceMatch[1] : '',
            fieldName: fieldReferenceMatch ? fieldReferenceMatch[2] : '',
            operator: this.extractOperator(trimmedFormula),
            value: this.extractValue(trimmedFormula)
        };
    }

    extractOperator(formula) {
        const operators = ['>=', '<=', '!=', '=', '>', '<', '+', '-'];
        return operators.find((operator) => formula.includes(` ${operator} `)) || '';
    }

    extractValue(formula) {
        const quotedValueMatch = formula.match(/'([^']*)'/);
        if (quotedValueMatch) {
            return quotedValueMatch[1];
        }

        const comparisonMatch = formula.match(/(?:>=|<=|!=|=|>|<|\+|-)\s+([^\s)]+)/);
        return comparisonMatch ? comparisonMatch[1].replace(/'/g, '') : '';
    }

    validateSaveFields() {
        if (!this.criteriaLabel.trim()) {
            this.showToast('Error', 'Enter a Criteria Label (e.g. Age Verification, Required Degree).', 'error');
            return false;
        }

        if (!this.selectedValidationType || !this.selectedEligibilityType) {
            this.showToast('Error', 'Select Validation Type and Eligibility Type.', 'error');
            return false;
        }

        if (this.editorState === 'awaiting_operator') {
            this.showToast('Error', 'Select an operator after the inserted field.', 'error');
            return false;
        }

        if (this.editorState === 'awaiting_value') {
            this.showToast('Error', 'Enter a value after the operator.', 'error');
            return false;
        }

        const structureValidation = this.validateFormulaStructure(this.formulaText);
        if (!structureValidation.valid) {
            this.showToast('Error', structureValidation.message, 'error');
            if (structureValidation.pendingState) {
                this.editorState = structureValidation.pendingState;
            }
            return false;
        }

        return true;
    }

    resetForm() {
        this.formulaText = '';
        this.criteriaLabel = '';
        this.passMessage = '';
        this.failMessage = '';
        this.objectName = '';
        this.fieldName = '';
        this.fieldOptions = [];
        this.cursorPosition = 0;
        this.cursorEnd = 0;
        this.editorState = 'ready';
        this.valueStartPosition = null;

        const textarea = this.getFormulaTextarea();
        if (textarea) {
            textarea.value = '';
        }
    }

    decorateCriteriaResults(criteriaResults) {
        return (criteriaResults || []).map((result) => ({
            ...result,
            statusLabel: result.passed ? 'Passed' : 'Failed',
            iconName: result.passed ? 'utility:success' : 'utility:close',
            iconClass: result.passed ? 'criteria-icon criteria-icon_pass' : 'criteria-icon criteria-icon_fail',
            rowClass: result.passed ? 'criteria-row criteria-row_pass' : 'criteria-row criteria-row_fail'
        }));
    }

    async handleCheckEligibility() {
        if (!this.recordId) {
            this.showToast('Error', 'Yearly Scheme record could not be identified.', 'error');
            return;
        }

        this.isCheckingEligibility = true;

        try {
            const evaluationResult = await checkEligibilityApex({
                yearlySchemeId: this.recordId,
                contactId: TEST_CONTACT_ID
            });

            this.eligibilitySummary = {
                isEligible: evaluationResult.isEligible,
                canApply: evaluationResult.canApply,
                overallMessage: evaluationResult.overallMessage
            };
            this.criteriaResults = this.decorateCriteriaResults(evaluationResult.criteriaResults);
            this.showResultsModal = true;
        } catch (error) {
            console.error('Error checking eligibility:', error);
            this.showToast(
                'Error',
                error.body?.message || error.message || 'Failed to check eligibility.',
                'error'
            );
        } finally {
            this.isCheckingEligibility = false;
        }
    }

    handleCloseResultsModal() {
        this.showResultsModal = false;
    }

    async saveEligibilityCriteria() {
        try {
            if (!this.validateSaveFields()) {
                return;
            }

            if (!this.recordId) {
                this.showToast('Error', 'Yearly Scheme record could not be identified.', 'error');
                return;
            }

            const parsedFormula = this.parseFormulaMetadata(this.formulaText);

            const wrapperData = [{
                sequence: 1,
                ruleName: this.criteriaLabel.trim(),
                objectName: parsedFormula.objectName,
                fieldName: parsedFormula.fieldName,
                operator: parsedFormula.operator,
                value: parsedFormula.value,
                logicalOperator: '',
                validationType: this.selectedValidationType,
                eligibilityType: this.selectedEligibilityType,
                formula: this.formulaText.trim(),
                passMessage: this.passMessage?.trim() || '',
                failMessage: this.failMessage?.trim() || ''
            }];

            const response = await saveEligibilityCriteriaApex({
                wrapperDataJson: JSON.stringify(wrapperData),
                yearlySchemeId: this.recordId
            });

            if (response === 'SUCCESS') {
                this.resetForm();
                this.showToast(
                    'Success',
                    'Eligibility criteria saved successfully.',
                    'success'
                );
            } else {
                this.showToast(
                    'Error',
                    'Failed to save eligibility criteria.',
                    'error'
                );
            }

        } catch (error) {
            console.error('Error:', error);
            this.showToast(
                'Error',
                error.body?.message || error.message || 'Unknown error occurred.',
                'error'
            );
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

}
