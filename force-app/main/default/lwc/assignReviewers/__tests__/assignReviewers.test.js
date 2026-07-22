import { createElement } from '@lwc/engine-dom';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import AssignReviewers from 'c/assignReviewers';
import getReviewerContacts from '@salesforce/apex/ReviewerController.getReviewerContacts';

// Mock data simulates the ReviewerResult wrapper returned from Apex,
// including the keyword match metadata.
const mockReviewers = [
    {
        Id: '003000000000001',
        Name: 'Alice Smith',
        Email: 'alice@example.com',
        Phone: '555-0101',
        reviewerType: 'Internal',
        qualifyingDegree: 'PhD',
        matchCount: 2,
        matchedKeywords: 'Biology, Biotechnology',
        isAlreadyMapped: false
    },
    {
        Id: '003000000000002',
        Name: 'Bob Jones',
        Email: 'bob@example.com',
        Phone: '555-0102',
        reviewerType: 'External',
        qualifyingDegree: 'MD',
        matchCount: 1,
        matchedKeywords: 'Biology',
        isAlreadyMapped: false
    }
];

const getReviewerContactsAdapter = registerApexTestWireAdapter(getReviewerContacts);

function flushPromises() {
    return Promise.resolve();
}

describe('c-assign-reviewers', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders reviewer results with matched keyword metadata', async () => {
        const element = createElement('c-assign-reviewers', { is: AssignReviewers });
        element.recordId = 'a01000000000001';
        document.body.appendChild(element);

        getReviewerContactsAdapter.emit(mockReviewers);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(mockReviewers.length);
    });

    it('enables Create Mappings after a reviewer is selected', async () => {
        const element = createElement('c-assign-reviewers', { is: AssignReviewers });
        element.recordId = 'a01000000000001';
        document.body.appendChild(element);

        getReviewerContactsAdapter.emit(mockReviewers);
        await flushPromises();

        const button = element.shadowRoot.querySelector('lightning-button');
        expect(button.disabled).toBeTruthy();

        // Simulate the rowselection event fired by lightning-datatable.
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowselection', {
                detail: { selectedRows: [{ Id: mockReviewers[0].Id }] }
            })
        );
        await flushPromises();

        expect(button.disabled).toBeFalsy();
    });
});