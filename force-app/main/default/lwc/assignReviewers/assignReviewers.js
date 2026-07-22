import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getReviewerContacts from '@salesforce/apex/ReviewerController.getReviewerContacts';
import createReviewerMappings from '@salesforce/apex/ReviewerController.createReviewerMappings';

export default class AssignReviewers extends LightningElement {
    @api recordId;

    reviewers = [];
    error;
    isLoading = true;
    isSaving = false;
    wiredReviewersResult;

    // Pass the proposal record Id so Apex can read Keywords__c and return
    // only reviewer contacts whose child keywords contain the proposal terms.
    @wire(getReviewerContacts, { proposalId: '$recordId' })
    wiredReviewers(result) {
        this.wiredReviewersResult = result;
        const { error, data } = result;
        this.isLoading = false;

        if (data) {
            this.reviewers = data.map((reviewer) => ({
                ...reviewer,
                selected: false,
                rowClass: reviewer.isAlreadyMapped
                    ? 'slds-hint-parent reviewer-row-disabled'
                    : 'slds-hint-parent'
            }));
            this.error = undefined;
        } else if (error) {
            this.reviewers = [];
            this.error = error;
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    get hasReviewers() {
        return this.reviewers.length > 0;
    }

    get selectedReviewerIds() {
        return this.reviewers
            .filter((reviewer) => reviewer.selected && !reviewer.isAlreadyMapped)
            .map((reviewer) => reviewer.Id);
    }

    get isSubmitDisabled() {
        return this.selectedReviewerIds.length === 0 || this.isSaving;
    }

    handleReviewerSelect(event) {
        const reviewerId = event.target.dataset.id;
        const isSelected = event.target.checked;
        const reviewer = this.reviewers.find((item) => item.Id === reviewerId);

        if (!reviewer || reviewer.isAlreadyMapped) {
            return;
        }

        this.reviewers = this.reviewers.map((item) =>
            item.Id === reviewerId ? { ...item, selected: isSelected } : item
        );
    }

    async handleCreateMappings() {
        if (this.selectedReviewerIds.length === 0) {
            return;
        }

        this.isSaving = true;
        try {
            await createReviewerMappings({
                proposalId: this.recordId,
                contactIds: this.selectedReviewerIds
            });
            this.showToast('Success', 'Reviewer mappings created successfully.', 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            await refreshApex(this.wiredReviewersResult);
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
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

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (Array.isArray(error?.body) && error.body.length > 0) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.message || 'Unable to load reviewers.';
    }
}