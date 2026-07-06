import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getYearlySchemeDetails from '@salesforce/apex/YearlySchemeCloneController.getYearlySchemeDetails';
import getChildRecords from '@salesforce/apex/YearlySchemeCloneController.getChildRecords';
import cloneYearlyScheme from '@salesforce/apex/YearlySchemeCloneController.cloneYearlyScheme';
import getQuestionnairesByItem from '@salesforce/apex/YearlySchemeCloneController.getQuestionnairesByItem';
import getCloneScreenPicklistOptions from '@salesforce/apex/YearlySchemeCloneController.getCloneScreenPicklistOptions';
import yearlySchemeExists from '@salesforce/apex/YearlySchemeCloneController.yearlySchemeExists';
import { CurrentPageReference } from 'lightning/navigation';

export default class YearlySchemeCloneAction extends NavigationMixin(LightningElement) {

    @api recordId;
    @track schemeDetails;
    @track parentFormData = {};

    @track checkListRecords = [];
    @track rulesRecords = [];
    @track questionItemRecords = [];

    @track publishStatusOptions = [];
    @track checkListStageOptions = [];
    @track rulesStageOptions = [];
    @track rulesValidationTypeOptions = [];
    @track questionItemStageOptions = [];
    @track questionItemTypeOptions = [];
    @track questionItemAttachmentsOptions = [];
    @track applicationStagesOptions = [];   // NEW
    @track requiredDegreeOptions = [];      // NEW

    @track selectAllCheckList = false;
    @track selectAllRules = false;
    @track selectAllQuestionItems = false;

    isLoading = true;
    isSaving = false;
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
        this.isLoading = true;
        try {
            const [details, checkList, rules, picklists] = await Promise.all([
                getYearlySchemeDetails({ recordId: this.recordId }),
                getChildRecords({ recordId: this.recordId, objectApiName: 'Eligibility_Check_List__c' }),
                getChildRecords({ recordId: this.recordId, objectApiName: 'Eligibility_Rules__c' }),
                getCloneScreenPicklistOptions()
            ]);

            this.schemeDetails = details;

            this.publishStatusOptions = picklists.publishStatus || [];
            this.checkListStageOptions = picklists.checkListStage || [];
            this.rulesStageOptions = picklists.rulesStage || [];
            this.rulesValidationTypeOptions = picklists.rulesValidationType || [];
            this.questionItemStageOptions = picklists.questionItemStage || [];
            this.questionItemTypeOptions = picklists.questionItemType || [];
            this.questionItemAttachmentsOptions = picklists.questionItemAttachments || []; // NEW
            this.applicationStagesOptions = picklists.applicationStages || []; // NEW
            this.requiredDegreeOptions = picklists.requiredDegree || [];       // NEW

            // Seed the editable parent form with the current record's values.
            // NOTE: the 4 date fields are intentionally left BLANK here — on a
            // clone, the user is expected to enter fresh dates rather than
            // inherit the source record's dates.
            this.parentFormData = {
                Scheme_Items__c: details.Scheme_Items__c,
                Year__c: details.Year__c,
                Scheme_Start_Date__c: '',
                Second_Stage_Start_Date__c: '',
                Scheme_End_Date__c: '',
                Second_Stage_End_Date__c: '',
                Scheme_Visibility__c: details.Scheme_Visibility__c,
                Is_Active__c: details.Is_Active__c,
                CurrencyIsoCode: details.CurrencyIsoCode,

                // NEW fields
                Team_Size_Limits__c: details.Team_Size_Limits__c,
                Experience_Required__c: details.Experience_Required__c,
                Budget_Cap__c: details.Budget_Cap__c,
                Application_Stages__c: details.Application_Stages__c,
                // Multi-select picklist is stored as a ';'-delimited string on the record;
                // lightning-dual-listbox needs an array.
                Required_Degree__c: details.Required_Degree__c ? details.Required_Degree__c.split(';') : []
            };

            this.checkListRecords = checkList.map((rec) => ({ ...rec, selected: false }));
            this.rulesRecords = rules.map((rec) => ({ ...rec, selected: false }));

            this.selectAllCheckList = false;
            this.selectAllRules = false;

            await this.loadQuestionnairesForItem(this.parentFormData.Scheme_Items__c);
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get noCheckListRecords() {
        return !this.checkListRecords.length;
    }
    get noRulesRecords() {
        return !this.rulesRecords.length;
    }
    get noQuestionItemRecords() {
        return !this.questionItemRecords.length;
    }
    get noSchemeItemSelected() {
        return !this.parentFormData.Scheme_Items__c;
    }

    get checkListTabLabel() {
        return `Eligibility Check List (${this.checkListRecords.length})`;
    }
    get rulesTabLabel() {
        return `Eligibility Rules (${this.rulesRecords.length})`;
    }
    get questionItemTabLabel() {
        return `Scheme Question Items (${this.questionItemRecords.length})`;
    }

    // ---------- Parent field editing ----------
    handleParentFieldChange(event) {
        const field = event.target.dataset.field;
        let value;
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else if (event.target.type === 'number') {
            value = event.target.value === '' ? null : Number(event.target.value);
        } else {
            value = event.target.value;
        }
        this.parentFormData = { ...this.parentFormData, [field]: value };
    }

    handlePublishStatusChange(event) {
        this.parentFormData = { ...this.parentFormData, Scheme_Visibility__c: event.detail.value };
    }

    handleYearChange(event) {
        this.parentFormData = { ...this.parentFormData, Year__c: event.detail.recordId };
    }

    // NEW: single-select picklist
    handleApplicationStagesChange(event) {
        this.parentFormData = { ...this.parentFormData, Application_Stages__c: event.detail.value };
    }

    // NEW: multi-select picklist — event.detail.value is already an array of selected values
    handleRequiredDegreeChange(event) {
        this.parentFormData = { ...this.parentFormData, Required_Degree__c: event.detail.value };
    }

    handleSelectAllCheckList(event) {
        const checked = event.target.checked;
        this.selectAllCheckList = checked;
        this.checkListRecords = this.checkListRecords.map(row => ({ ...row, selected: checked }));
    }

    handleSelectAllRules(event) {
        const checked = event.target.checked;
        this.selectAllRules = checked;
        this.rulesRecords = this.rulesRecords.map(row => ({ ...row, selected: checked }));
    }

    handleSelectAllQuestionItems(event) {
        const checked = event.target.checked;
        this.selectAllQuestionItems = checked;
        this.questionItemRecords = this.questionItemRecords.map(row => ({ ...row, selected: checked }));
    }

    async handleSchemeItemChange(event) {
        const newSchemeItemId = event.detail.recordId;
        this.parentFormData = { ...this.parentFormData, Scheme_Items__c: newSchemeItemId };
        await this.loadQuestionnairesForItem(newSchemeItemId);
    }


    /* async loadQuestionnairesForItem(schemeItemId) {
         if (!schemeItemId) {
             this.questionItemRecords = [];
             this.selectAllQuestionItems = false;
             return;
         }
         try {
             const questionnaires = await getQuestionnairesByItem({ schemeItemId });
             this.questionItemRecords = questionnaires.map((q) => ({
                 Id: q.Id,
                 Name: q.Name,
                 DisplayName: q.Display_Name__c,
                 selected: false,
                 Question__c: q.Display_Name__c,
                 Mandatory__c: false,
                 Type__c: '',
                 Max_Character__c: null,
                 Min_Character__c: null,
                 Is_Active__c:false,
                 Stage__c: '',
                 CurrencyIsoCode: ''
             }));
             this.selectAllQuestionItems = false;
         } catch (error) {
             this.showToast('Error', this.getErrorMessage(error), 'error');
         }
     }*/

    async loadQuestionnairesForItem(schemeItemId) {
        if (!schemeItemId) {
            this.questionItemRecords = [];
            this.selectAllQuestionItems = false;
            return;
        }
        try {
            const questionnaires = await getQuestionnairesByItem({ schemeItemId });
            this.questionItemRecords = questionnaires.map((q) => ({
                Id: q.Id,
                Name: q.Name,
                DisplayName: q.Display_Name__c,
                selected: false,
                // Question__c pre-populated from Display_Name__c but remains user-editable
                Question__c: q.Display_Name__c,
                // All other fields now pre-populated from the source Scheme_Questionnaire__c record
                Mandatory__c: q.Mandatory__c || false,
                Type__c: q.Type__c || '',
                Max_Character__c: q.Max_Limit__c != null ? q.Max_Limit__c : null,
                Min_Character__c: q.Min_Limit__c != null ? q.Min_Limit__c : null,
                Is_Active__c: q.Is_Active__c || false,
                Stage__c: q.Stage__c || '',
                CurrencyIsoCode: q.CurrencyIsoCode || '',
                Attachments__c: ''
            }));
            this.selectAllQuestionItems = false;
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    // ---------- Row selection + editing: Eligibility Check List ----------
    handleCheckListRowToggle(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        this.checkListRecords = this.checkListRecords.map(row => row.Id === id ? { ...row, selected: checked } : row);
        this.selectAllCheckList = this.checkListRecords.length > 0 && this.checkListRecords.every(row => row.selected);
    }
    handleCheckListStageChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.checkListRecords = this.checkListRecords.map((row) =>
            row.Id === id ? { ...row, Stage__c: value } : row
        );
    }

    // ---------- Row selection + editing: Eligibility Rules ----------
    handleRulesRowToggle(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        this.rulesRecords = this.rulesRecords.map(row => row.Id === id ? { ...row, selected: checked } : row);
        this.selectAllRules = this.rulesRecords.length > 0 && this.rulesRecords.every(row => row.selected);
    }
    handleRulesStageChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.rulesRecords = this.rulesRecords.map((row) =>
            row.Id === id ? { ...row, Stage__c: value } : row
        );
    }
    handleRulesValidationTypeChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.rulesRecords = this.rulesRecords.map((row) =>
            row.Id === id ? { ...row, Validation_Type__c: value } : row
        );
    }

    // ---------- Row selection + editing: Scheme Question Items ----------
    handleQuestionItemRowToggle(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        this.questionItemRecords = this.questionItemRecords.map(row => row.Id === id ? { ...row, selected: checked } : row);
        this.selectAllQuestionItems = this.questionItemRecords.length > 0 && this.questionItemRecords.every(row => row.selected);
    }

    handleQuestionItemFieldChange(event) {
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

    handleQuestionItemTypeChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.questionItemRecords = this.questionItemRecords.map((row) =>
            row.Id === id ? { ...row, Type__c: value } : row
        );
    }
    handleQuestionItemStageChange(event) {
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
        this.isSaving = true;
        try {
            const checkListPayload = this.checkListRecords
                .filter((r) => r.selected)
                .map((r) => ({
                    Id: r.Id,
                    Stage__c: r.Stage__c,
                    CurrencyIsoCode: r.CurrencyIsoCode,
                    Display_Question__c: r.Display_Question__c,
                    Type__c: r.Type__c
                }));

            const rulesPayload = this.rulesRecords
                .filter((r) => r.selected)
                .map((r) => ({
                    Id: r.Id,
                    Stage__c: r.Stage__c,
                    CurrencyIsoCode: r.CurrencyIsoCode,
                    Validation_Type__c: r.Validation_Type__c
                }));

            const questionItemPayload = this.questionItemRecords
                .filter((r) => r.selected)
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
                    Attachments__c: r.Attachments__c
                }));

            // Convert Required_Degree__c array back to the ';'-delimited string
            // Salesforce expects for a multi-select picklist field.
            const parentOverrides = {
                ...this.parentFormData,
                Required_Degree__c: Array.isArray(this.parentFormData.Required_Degree__c)
                    ? this.parentFormData.Required_Degree__c.join(';')
                    : this.parentFormData.Required_Degree__c
            };

            const exists = await yearlySchemeExists({
                yearId: this.parentFormData.Year__c,
                schemeItemId: this.parentFormData.Scheme_Items__c
            });

            if (exists) {
                this.showToast(
                    'Duplicate Record',
                    'A Yearly Scheme already exists for the selected Year and Scheme.Please Change the Scheme Or Year',
                    'warning'
                );
                this.isSaving = false;
                return;
            }

            const newRecordId = await cloneYearlyScheme({
                recordId: this.recordId,
                parentOverrides,
                checkListRecords: checkListPayload,
                rulesRecords: rulesPayload,
                questionItemRecords: questionItemPayload
            });

            this.showToast('Success', 'Yearly Scheme cloned successfully.', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: newRecordId,
                    objectApiName: 'Yearly_Scheme__c',
                    actionName: 'view'
                }
            });
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
}