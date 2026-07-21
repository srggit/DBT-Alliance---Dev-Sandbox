import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ELIGIBILITY_CRITERIA_OBJECT from '@salesforce/schema/Eligibility_Criteria__c';
import VALIDATION_TYPE_FIELD from '@salesforce/schema/Eligibility_Criteria__c.Validation_Type__c';
import ELIGIBILITY_TYPE_FIELD from '@salesforce/schema/Eligibility_Criteria__c.Eligibility_Type__c';

import saveEligibilityCriteriaApex from '@salesforce/apex/EligibilityController.saveEligibilityCriteria';
import getFieldMasterData from '@salesforce/apex/EligibilityController.getFieldMasterData';
import checkFormulaSyntaxApex from '@salesforce/apex/EligibilityController.checkFormulaSyntax';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const TOKEN_TYPES = {
    FIELD: 'FIELD',
    VALUE: 'VALUE',
    COMPARISON: 'COMPARISON',
    LOGICAL: 'LOGICAL',
    LPAREN: 'LPAREN',
    RPAREN: 'RPAREN'
};

const DEFAULT_GUIDANCE =
    'Build each condition as Field → Operator → Value (or another Field). Use AND / OR to combine conditions.';

export default class EligibilityFormulaBuilder extends LightningElement {
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

    validationTypeOptions = [];
    eligibilityTypeOptions = [];

    guidanceKind = 'info';
    guidanceMessage = DEFAULT_GUIDANCE;

    @api recordId;

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

    get isInsertFieldDisabled() {
        return !this.objectName || !this.fieldName;
    }

    get editorStateClass() {
        if (this.guidanceKind === 'warning') {
            return 'editor-state-hint editor-state-hint_warning slds-var-m-bottom_x-small';
        }

        return 'editor-state-hint slds-text-color_weak slds-var-m-bottom_x-small';
    }

    get editorStateMessage() {
        return this.guidanceMessage || DEFAULT_GUIDANCE;
    }

    get operatorTokensWithState() {
        return this.operatorTokens.map((operator) => ({
            ...operator,
            disabled: false
        }));
    }

    connectedCallback() {
        this.refreshGuidance();
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
        this.refreshGuidance();
    }

    handleFormulaInput(event) {
        this.formulaText = event.target.value;
        this.cursorPosition = event.target.selectionStart;
        this.cursorEnd = event.target.selectionEnd;
        this.refreshGuidance();
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

    handleInsertField() {
        if (!this.objectName || !this.fieldName) {
            this.showToast('Error', 'Select an Object and Field to insert.', 'error');
            return;
        }

        const fieldReference = `${this.objectName}.${this.fieldName}`;
        this.insertAtCursor(fieldReference);
    }

    handleInsertOperator(event) {
        const token = event.currentTarget.dataset.token;
        if (!token) {
            return;
        }

        this.insertAtCursor(token);
    }

    /**
     * Soft guidance from the current formula text. Never locks the UI.
     */
    refreshGuidance() {
        const text = (this.formulaText || '').trim();

        if (!text) {
            this.guidanceMessage = DEFAULT_GUIDANCE;
            this.guidanceKind = 'info';
            return;
        }

        const analysis = this.analyzeFormula(text);

        if (analysis.expect === 'COMPARISON') {
            this.guidanceMessage =
                'Field inserted. Select an operator (=, !=, >, <, >=, <=) to continue.';
            this.guidanceKind = 'warning';
            return;
        }

        if (analysis.expect === 'OPERAND') {
            this.guidanceMessage =
                'Operator inserted. Type a value, or insert another field to compare.';
            this.guidanceKind = 'warning';
            return;
        }

        if (analysis.expect === 'TERM') {
            this.guidanceMessage =
                'Insert a field (or open parenthesis) to start the next condition.';
            this.guidanceKind = 'warning';
            return;
        }

        if (!analysis.valid && analysis.message) {
            this.guidanceMessage = analysis.message;
            this.guidanceKind = 'warning';
            return;
        }

        this.guidanceMessage =
            'Condition looks complete. Add AND / OR to combine more conditions, or click Check Syntax.';
        this.guidanceKind = 'info';
    }

    /**
     * Structure analysis used for guidance and local pre-checks.
     * Grammar: TERM (FIELD | '(' TERM ')') COMPARISON OPERAND (VALUE|FIELD)
     *          then optional LOGICAL TERM... with balanced parentheses.
     */
    analyzeFormula(formula) {
        const text = (formula || '').trim();

        if (!text) {
            return {
                valid: false,
                message: 'Enter a formula before checking syntax.',
                expect: 'TERM'
            };
        }

        const tokens = this.tokenize(text);

        if (!tokens.length) {
            return {
                valid: false,
                message: 'Formula must include at least one Object.Field reference.',
                expect: 'TERM'
            };
        }

        let expect = 'TERM';
        let parenDepth = 0;

        for (let index = 0; index < tokens.length; index++) {
            const token = tokens[index];

            if (expect === 'TERM') {
                if (token.type === TOKEN_TYPES.LPAREN) {
                    parenDepth += 1;
                    continue;
                }

                if (token.type === TOKEN_TYPES.FIELD) {
                    expect = 'COMPARISON';
                    continue;
                }

                return {
                    valid: false,
                    message: `Unexpected "${token.value}". Expected a field or "(".`,
                    expect: 'TERM'
                };
            }

            if (expect === 'COMPARISON') {
                if (token.type === TOKEN_TYPES.COMPARISON) {
                    expect = 'OPERAND';
                    continue;
                }

                return {
                    valid: false,
                    message: `Operator is required after field. Unexpected "${token.value}".`,
                    expect: 'COMPARISON'
                };
            }

            if (expect === 'OPERAND') {
                if (token.type === TOKEN_TYPES.VALUE || token.type === TOKEN_TYPES.FIELD) {
                    expect = 'AFTER';
                    continue;
                }

                return {
                    valid: false,
                    message: `Value or field is required after the operator. Unexpected "${token.value}".`,
                    expect: 'OPERAND'
                };
            }

            if (expect === 'AFTER') {
                if (token.type === TOKEN_TYPES.RPAREN) {
                    parenDepth -= 1;
                    if (parenDepth < 0) {
                        return {
                            valid: false,
                            message: 'Unexpected ")". Check parentheses.',
                            expect: 'AFTER'
                        };
                    }
                    continue;
                }

                if (token.type === TOKEN_TYPES.LOGICAL) {
                    expect = 'TERM';
                    continue;
                }

                return {
                    valid: false,
                    message: `Unexpected "${token.value}". Use AND / OR to combine conditions, or ")".`,
                    expect: 'AFTER'
                };
            }
        }

        if (parenDepth !== 0) {
            return {
                valid: false,
                message: 'Parentheses are unbalanced. Add the missing ")" or "(".',
                expect: expect === 'AFTER' ? 'AFTER' : expect
            };
        }

        if (expect !== 'AFTER') {
            return {
                valid: false,
                message: this.messageForExpect(expect),
                expect
            };
        }

        return { valid: true, expect: 'AFTER' };
    }

    messageForExpect(expect) {
        if (expect === 'COMPARISON') {
            return 'Operator is required after the field.';
        }
        if (expect === 'OPERAND') {
            return 'Value or field is required after the operator.';
        }
        if (expect === 'TERM') {
            return 'Formula is incomplete. Insert a field after AND / OR or "(".';
        }
        return 'Formula structure is incomplete.';
    }

    async handleCheckSyntax() {
        try {
            const result = await checkFormulaSyntaxApex({ formula: this.formulaText });

            if (result?.isValid) {
                this.showToast('Success', result.message || 'No syntax errors in formula.', 'success');
                this.guidanceMessage =
                    'Syntax is valid. You can save, or continue adding AND / OR conditions.';
                this.guidanceKind = 'info';
            } else {
                this.showToast(
                    'Syntax Error',
                    result?.message || 'Formula has syntax errors.',
                    'error'
                );
                this.guidanceMessage = result?.message || 'Formula has syntax errors.';
                this.guidanceKind = 'warning';
            }
        } catch (error) {
            console.error('Check syntax error:', error);
            this.showToast(
                'Error',
                error.body?.message || error.message || 'Failed to check formula syntax.',
                'error'
            );
        }
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

    async validateSaveFields() {
        if (!this.selectedValidationType || !this.selectedEligibilityType) {
            this.showToast('Error', 'Select Validation Type and Eligibility Type.', 'error');
            return false;
        }

        try {
            const result = await checkFormulaSyntaxApex({ formula: this.formulaText });
            if (!result?.isValid) {
                this.showToast(
                    'Syntax Error',
                    result?.message || 'Fix formula syntax before saving.',
                    'error'
                );
                this.guidanceMessage = result?.message || 'Fix formula syntax before saving.';
                this.guidanceKind = 'warning';
                return false;
            }
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || error.message || 'Failed to validate formula syntax.',
                'error'
            );
            return false;
        }

        return true;
    }

    resetForm() {
        this.formulaText = '';
        this.objectName = '';
        this.fieldName = '';
        this.fieldOptions = [];
        this.cursorPosition = 0;
        this.cursorEnd = 0;

        const textarea = this.getFormulaTextarea();
        if (textarea) {
            textarea.value = '';
        }

        this.refreshGuidance();
    }

    async saveEligibilityCriteria() {
        try {
            if (!(await this.validateSaveFields())) {
                return;
            }

            if (!this.recordId) {
                this.showToast('Error', 'Yearly Scheme record could not be identified.', 'error');
                return;
            }

            const parsedFormula = this.parseFormulaMetadata(this.formulaText);

            const wrapperData = [
                {
                    sequence: 1,
                    objectName: parsedFormula.objectName,
                    fieldName: parsedFormula.fieldName,
                    operator: parsedFormula.operator,
                    value: parsedFormula.value,
                    logicalOperator: '',
                    validationType: this.selectedValidationType,
                    eligibilityType: this.selectedEligibilityType,
                    formula: this.formulaText.trim()
                }
            ];

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
                this.showToast('Error', 'Failed to save eligibility criteria.', 'error');
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

    tokenize(formula) {
        const tokens = [];
        const regex =
            /\(|\)|>=|<=|!=|=|>|<|\+|-|\bAND\b|\bOR\b|'[^']*'|\d+(\.\d+)?|true|false|[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*/gi;

        let match;
        while ((match = regex.exec(formula)) !== null) {
            const token = match[0];
            const upper = token.toUpperCase();

            if (token === '(') {
                tokens.push({ type: TOKEN_TYPES.LPAREN, value: token });
                continue;
            }

            if (token === ')') {
                tokens.push({ type: TOKEN_TYPES.RPAREN, value: token });
                continue;
            }

            if (upper === 'AND' || upper === 'OR') {
                tokens.push({ type: TOKEN_TYPES.LOGICAL, value: upper });
                continue;
            }

            if (['=', '!=', '>', '<', '>=', '<=', '+', '-'].includes(token)) {
                tokens.push({ type: TOKEN_TYPES.COMPARISON, value: token });
                continue;
            }

            if (token.includes('.')) {
                tokens.push({ type: TOKEN_TYPES.FIELD, value: token });
                continue;
            }

            tokens.push({
                type: TOKEN_TYPES.VALUE,
                value: token.replace(/'/g, '')
            });
        }

        return tokens;
    }
}