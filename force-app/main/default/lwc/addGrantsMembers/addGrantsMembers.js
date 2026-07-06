import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getGrantsManagerUsers from '@salesforce/apex/AssignGrantsMembersForYearlyScheme.getGrantsManagerUsers';
import addGrantsTeamMembers from '@salesforce/apex/AssignGrantsMembersForYearlyScheme.addGrantsTeamMembers';

export default class AddGrantsMembers extends LightningElement {
    @api recordId;

    users = [];
    searchKey = '';
    error;
    isLoading = true;
    isSaving = false;
    wiredGrantsManagersResult;

    @wire(getGrantsManagerUsers, { yearlySchemeId: '$recordId' })
    wiredGrantsManagers(result) {
        this.wiredGrantsManagersResult = result;
        const { data, error } = result;
        this.isLoading = false;

        if (data) {
            this.users = data.map((user) => ({
                ...user,
                selected: false,
                activeLabel: user.isActive ? 'Yes' : 'No',
                rowClass: user.isAlreadyAdded
                    ? 'slds-hint-parent member-row-disabled'
                    : 'slds-hint-parent'
            }));
            this.error = undefined;
        } else if (error) {
            this.users = [];
            this.error = error;
        }
    }

    get hasUsers() {
        return this.users.length > 0;
    }

    get filteredUsers() {
        const key = this.searchKey.trim().toLowerCase();
        if (!key) {
            return this.users;
        }

        return this.users.filter((user) =>
            [user.name, user.email, user.username, user.role]
                .join(' ')
                .toLowerCase()
                .includes(key)
        );
    }

    get hasFilteredUsers() {
        return this.filteredUsers.length > 0;
    }

    get selectedUserIds() {
        return this.users
            .filter((user) => user.selected && !user.isAlreadyAdded)
            .map((user) => user.id);
    }

    get isAddDisabled() {
        return this.isSaving || this.selectedUserIds.length === 0;
    }

    get selectionSummary() {
        const selectedCount = this.selectedUserIds.length;
        const availableCount = this.users.filter((user) => !user.isAlreadyAdded).length;

        if (selectedCount === 0) {
            return `${availableCount} user(s) available`;
        }
        return `${selectedCount} of ${availableCount} selected`;
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value || '';
    }

    handleUserSelect(event) {
        const userId = event.target.dataset.id;
        const isSelected = event.target.checked;
        const user = this.users.find((item) => item.id === userId);

        if (!user || user.isAlreadyAdded) {
            return;
        }

        this.users = this.users.map((item) =>
            item.id === userId ? { ...item, selected: isSelected } : item
        );
    }

    async handleAddMembers() {
        if (!this.recordId) {
            this.showToast('Error', 'Yearly Scheme record Id is missing.', 'error');
            return;
        }
        if (this.selectedUserIds.length === 0) {
            this.showToast('Error', 'Select at least one Grants Manager.', 'error');
            return;
        }

        this.isSaving = true;

        try {
            const createdCount = await addGrantsTeamMembers({
                yearlySchemeId: this.recordId,
                userIds: this.selectedUserIds
            });

            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.dispatchEvent(new RefreshEvent());

            this.showToast(
                'Success',
                `${createdCount} Grants Manager(s) added successfully.`,
                'success'
            );
            this.isSaving = false;
            this.dispatchEvent(new CloseActionScreenEvent());

            // Invalidate cached user list for the next time this action is opened.
            refreshApex(this.wiredGrantsManagersResult);
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
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
        return error?.message || 'Unable to add Grants Managers.';
    }
}