import { LightningElement, wire, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

import getYearlySchemeInfo from '@salesforce/apex/AddSchemeQuestionItemsController.getYearlySchemeInfo';
import getQuestionnairesByItem from '@salesforce/apex/AddSchemeQuestionItemsController.getQuestionnairesByItem';
import getExistingQuestionItems from '@salesforce/apex/AddSchemeQuestionItemsController.getExistingQuestionItems';
import getScreenPicklistOptions from '@salesforce/apex/AddSchemeQuestionItemsController.getScreenPicklistOptions';
import saveQuestionItems from '@salesforce/apex/AddSchemeQuestionItemsController.saveQuestionItems';

export default class AddSchemeQuestionItemsAction extends LightningElement {

    @api recordId;
    schemeInfo;

    questionItemRecords = [];
    stageOptions = [];
    typeOptions = [];
    @track questionItemAttachmentsOptions = [];

    selectAllQuestionItems = false;

    isLoading = true;
    isSaving = false;
    hasResizedModal = false;
    hasLoaded = false;

    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         this.recordId =
    //             currentPageReference.attributes?.recordId ||
    //             currentPageReference.state?.recordId ||
    //             currentPageReference.state?.c__recordId;

    //         if (this.recordId) {
    //             this.loadData();
    //         }
    //     }
    // }

    // connectedCallback() {
    //     this.loadData();
    // }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('[wire] @api recordId at wire time:', this.recordId);

        if (!this.recordId && currentPageReference) {
            const fromAttributes = currentPageReference.attributes?.recordId;
            const fromState = currentPageReference.state?.recordId;
            const fromStateC = currentPageReference.state?.c__recordId;

            this.recordId = fromAttributes || fromState || fromStateC;

            console.log('[wire] currentPageReference:', JSON.stringify(currentPageReference));
            console.log('[wire] resolved recordId from CurrentPageReference:', this.recordId,
                '| source:', fromAttributes ? 'attributes.recordId' : fromState ? 'state.recordId' : fromStateC ? 'state.c__recordId' : 'none');
        }

        if (this.recordId && !this.hasLoaded) {
            console.log('[wire] triggering loadData() from wire, recordId =', this.recordId);
            this.hasLoaded = true;
            this.loadData();
        }
    }

    connectedCallback() {
        console.log('[connectedCallback] @api recordId at connect time:', this.recordId);

        if (this.recordId && !this.hasLoaded) {
            console.log('[connectedCallback] triggering loadData() from connectedCallback, recordId =', this.recordId);
            this.hasLoaded = true;
            this.loadData();
        }
    }

    async loadData() {
        if (!this.recordId) {
            return;
        }
        this.isLoading = true;
        try {
            const [info, existingItems, picklists] = await Promise.all([
                getYearlySchemeInfo({ recordId: this.recordId }),
                getExistingQuestionItems({ recordId: this.recordId }),
                getScreenPicklistOptions()
            ]);

            this.schemeInfo = info;
            this.stageOptions = picklists.stage || [];
            this.typeOptions = picklists.type || [];
            this.questionItemAttachmentsOptions = picklists.questionItemAttachments || [];

            // Map of Scheme_Questionnaire__c Id -> already-saved Scheme_Question_Items__c
            // record, so we can prepopulate the row with real data instead of blanks.
            const existingByQuestionnaire = new Map();
            existingItems.forEach((rec) => {
                existingByQuestionnaire.set(rec.Scheme_Questionnaire__c, rec);
            });

            const questionnaires = await getQuestionnairesByItem({ schemeItemId: info.Scheme_Items__c });

            this.questionItemRecords = questionnaires.map((q) => {
                const existing = existingByQuestionnaire.get(q.Id);

                if (existing) {
                    // Already added: show the record exactly as it was saved, locked for editing.
                    return {
                        Id: q.Id,
                        Name: q.Name,
                        DisplayName: q.Display_Name__c,
                        alreadyAdded: true,
                        addedMessage: `Already added by ${existing.CreatedBy?.Name || 'someone'} on ${new Date(existing.CreatedDate).toLocaleDateString()}. Edit it from the related list if changes are needed.`,
                        selected: false,
                        Question__c: existing.Question__c,
                        Mandatory__c: existing.Mandatory__c,
                        Type__c: existing.Type__c,
                        Max_Character__c: existing.Max_Character__c,
                        Min_Character__c: existing.Min_Character__c,
                        Is_Active__c: existing.Is_Active__c,
                        Stage__c: existing.Stage__c,
                        CurrencyIsoCode: existing.CurrencyIsoCode,
                        Attachments__c: existing.Attachments__c,
                        Section__c: existing.Section__c,
                        SL_No__c: existing.SL_No__c,
                        Picklist_Values__c: existing.Picklist_Values__c
                    };
                }

                // Not yet added: fresh, editable defaults.
                return {
                    Id: q.Id,
                    Name: q.Name,
                    DisplayName: q.Display_Name__c,
                    alreadyAdded: false,
                    addedMessage: '',
                    selected: false,
                    Question__c: q.Display_Name__c,
                    Mandatory__c: q.Mandatory__c || false,
                    Type__c: q.Type__c || '',
                    Max_Character__c: q.Max_Limit__c != null ? q.Max_Limit__c : null,
                    Min_Character__c: q.Min_Limit__c != null ? q.Min_Limit__c : null,
                    Is_Active__c: q.Is_Active__c || false,
                    Stage__c: q.Stage__c || '',
                    CurrencyIsoCode: '',
                    Attachments__c: '',
                    Section__c: q.Section__c || '',
                    SL_No__c: q.SL_No__c != null ? q.SL_No__c : null,
                    Picklist_Values__c: q.Picklist_Values__c || ''
                };
            });

            this.selectAllQuestionItems = false;
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get noSchemeItem() {
        return this.schemeInfo && !this.schemeInfo.Scheme_Items__c;
    }
    get noQuestionItemRecords() {
        return !this.questionItemRecords.length;
    }
    get questionItemTabLabel() {
        return `Available Scheme Questionnaires (${this.questionItemRecords.length})`;
    }

    handleSelectAllQuestionItems(event) {
        const checked = event.target.checked;
        this.selectAllQuestionItems = checked;
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.alreadyAdded ? row : { ...row, selected: checked }
        );
    }

    handleRowToggle(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.Id === id ? { ...row, selected: checked } : row
        );
        const selectableRows = this.questionItemRecords.filter((row) => !row.alreadyAdded);
        this.selectAllQuestionItems = selectableRows.length > 0 && selectableRows.every((row) => row.selected);
    }

    handleFieldChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value;
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else if (event.target.type === 'number') {
            value = event.target.value === '' ? null : Number(event.target.value);
        } else {
            value = event.target.value;
        }
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.Id === id ? { ...row, [field]: value } : row
        );
    }

    handleTypeChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.Id === id ? { ...row, Type__c: value } : row
        );
    }

    handleStageChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.Id === id ? { ...row, Stage__c: value } : row
        );
    }

    handleQuestionItemAttachmentsChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.Id === id ? { ...row, Attachments__c: value } : row
        );
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSave() {
        const payload = this.questionItemRecords
            .filter((r) => r.selected && !r.alreadyAdded)
            .map((r) => ({
                Scheme_Questionnaire__c: r.Id,
                Question__c: r.Question__c,
                Mandatory__c: r.Mandatory__c,
                Type__c: r.Type__c,
                Max_Character__c: r.Max_Character__c,
                Min_Character__c: r.Min_Character__c,
                Is_Active__c: r.Is_Active__c,
                Stage__c: r.Stage__c,
                CurrencyIsoCode: r.CurrencyIsoCode,
                Attachments__c: r.Attachments__c,
                Section__c: r.Section__c,
                SL_No__c: r.SL_No__c,
                Picklist_Values__c: r.Picklist_Values__c
            }));

        if (!payload.length) {
            this.showToast('Nothing selected', 'Select at least one questionnaire to add.', 'warning');
            return;
        }

        this.isSaving = true;
        try {
            const count = await saveQuestionItems({
                recordId: this.recordId,
                questionItemRecords: payload
            });

            this.showToast('Success', `${count} Scheme Question Item(s) created.`, 'success');
            this.dispatchEvent(new CloseActionScreenEvent());

            eval("$A.get('e.force:refreshView').fire();");
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    getErrorMessage(error) {
        return error && error.body && error.body.message ? error.body.message : 'Unknown error occurred';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    renderedCallback() {
        // Quick Action screens render inside a fixed-width .slds-modal__container
        // that lives outside this component's shadow DOM (in the parent page),
        // so we widen it directly via the global document the first time we render.
        if (this.hasResizedModal) {
            return;
        }
        const modal = document.querySelector('.slds-modal__container');
        if (modal) {
            modal.style.width = '95vw';
            modal.style.maxWidth = '95vw';
            this.hasResizedModal = true;
        }
    }
}