import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import DOCUMENTS_OBJECT from '@salesforce/schema/Documents__c';
import STAGE_FIELD from '@salesforce/schema/Documents__c.Stage__c';
import ROLES_FIELD from '@salesforce/schema/Documents__c.Roles__c';
import getDocumentMasters from '@salesforce/apex/AssignDocumentsForYearlyScheme.getDocumentMasters';
import addDocuments from '@salesforce/apex/AssignDocumentsForYearlyScheme.addDocuments';

export default class AddDocumentsInYearlySchemes extends LightningElement {
    @api recordId;

    documents = [];
    drafts = [];
    searchKey = '';
    error;
    isLoading = true;
    isSaving = false;
    currentStep = 1;

    stageOptions = [];
    roleOptions = [];

    @wire(getObjectInfo, { objectApiName: DOCUMENTS_OBJECT })
    documentsObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: STAGE_FIELD
    })
    wiredStagePicklist({ data }) {
        if (data) {
            this.stageOptions = data.values.map((entry) => ({
                label: entry.label,
                value: entry.value
            }));
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$defaultRecordTypeId',
        fieldApiName: ROLES_FIELD
    })
    wiredRolePicklist({ data }) {
        if (data) {
            this.roleOptions = data.values.map((entry) => ({
                label: entry.label,
                value: entry.value
            }));
        }
    }

    @wire(getDocumentMasters, { yearlySchemeId: '$recordId' })
    wiredDocumentMasters({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.documents = data.map((document) => ({
                ...document,
                selected: false
            }));
            this.error = undefined;
        } else if (error) {
            this.documents = [];
            this.error = error;
        }
    }

    get defaultRecordTypeId() {
        return this.documentsObjectInfo?.data?.defaultRecordTypeId;
    }

    get isSelectionStep() {
        return this.currentStep === 1;
    }

    get isConfigureStep() {
        return this.currentStep === 2;
    }

    get cardTitle() {
        return this.isConfigureStep ? 'Configure Documents' : 'Select Documents';
    }

    get hasDocuments() {
        return this.documents.length > 0;
    }

    get filteredDocuments() {
        const key = this.searchKey.trim().toLowerCase();
        if (!key) {
            return this.documents;
        }

        return this.documents.filter((document) =>
            [document.name, document.documentMastersId, document.schemeItemName]
                .join(' ')
                .toLowerCase()
                .includes(key)
        );
    }

    get hasFilteredDocuments() {
        return this.filteredDocuments.length > 0;
    }

    get isAllSelected() {
        const filtered = this.filteredDocuments;
        return filtered.length > 0 && filtered.every((document) => document.selected);
    }

    get selectedDocuments() {
        return this.documents.filter((document) => document.selected);
    }

    get isNextDisabled() {
        return this.selectedDocuments.length === 0;
    }

    get isSaveDisabled() {
        return this.isSaving || this.drafts.length === 0;
    }

    get selectionSummary() {
        const selectedCount = this.selectedDocuments.length;
        const totalCount = this.documents.length;

        if (selectedCount === 0) {
            return `${totalCount} document(s) available`;
        }
        return `${selectedCount} of ${totalCount} selected`;
    }

    get configureSummary() {
        return `${this.drafts.length} document(s) ready to create`;
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value || '';
    }

    handleDocumentSelect(event) {
        const documentId = event.target.dataset.id;
        const isSelected = event.target.checked;

        this.documents = this.documents.map((document) =>
            document.id === documentId
                ? { ...document, selected: isSelected }
                : document
        );
    }

    handleSelectAll(event) {
        const isSelected = event.target.checked;
        const filteredIds = new Set(this.filteredDocuments.map((document) => document.id));

        this.documents = this.documents.map((document) =>
            filteredIds.has(document.id)
                ? { ...document, selected: isSelected }
                : document
        );
    }

    handleNext() {
        if (this.selectedDocuments.length === 0) {
            this.showToast('Error', 'Select at least one document.', 'error');
            return;
        }

        this.drafts = this.selectedDocuments.map((document) => ({
            key: document.id,
            documentMasterId: document.id,
            documentName: document.name,
            isRequired: false,
            isActive: document.isActive === true,
            mandatoryForRoles: '',
            stage: ''
        }));
        this.currentStep = 2;
    }

    handleBack() {
        this.currentStep = 1;
        this.drafts = [];
    }

    handleDraftFieldChange(event) {
        const draftId = event.target.dataset.id;
        const field = event.target.dataset.field;
        if (!draftId || !field) {
            return;
        }

        const value =
            event.target.type === 'checkbox'
                ? event.target.checked
                : event.detail?.value ?? event.target.value ?? '';

        this.drafts = this.drafts.map((draft) =>
            draft.key === draftId ? { ...draft, [field]: value } : draft
        );
    }

    async handleSaveDocuments() {
        if (!this.recordId) {
            this.showToast('Error', 'Yearly Scheme record Id is missing.', 'error');
            return;
        }
        if (this.drafts.length === 0) {
            this.showToast('Error', 'No documents to save.', 'error');
            return;
        }

        this.isSaving = true;

        try {
            const documentsToAdd = this.drafts.map((draft) => ({
                documentMasterId: draft.documentMasterId,
                isRequired: draft.isRequired === true,
                isActive: draft.isActive === true,
                mandatoryForRoles: draft.mandatoryForRoles || null,
                stage: draft.stage || null
            }));

            const createdCount = await addDocuments({
                yearlySchemeId: this.recordId,
                documentsToAdd
            });

            this.showToast(
                'Success',
                `${createdCount} document(s) added successfully.`,
                'success'
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
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

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (Array.isArray(error?.body) && error.body.length > 0) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.message || 'Unable to add documents.';
    }
}