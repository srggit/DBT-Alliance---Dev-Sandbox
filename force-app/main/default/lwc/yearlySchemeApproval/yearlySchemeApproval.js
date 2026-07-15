import { LightningElement, api } from 'lwc';

import submitForApproval
from '@salesforce/apex/YearlySchemeApprovalController.submitForApproval';

import { ShowToastEvent }
from 'lightning/platformShowToastEvent';

export default class YearlySchemeApproval extends LightningElement {

    @api recordId;

    submitApproval(){

        submitForApproval({
            recordId : this.recordId
        })

        .then(()=>{

            this.dispatchEvent(
                new ShowToastEvent({
                    title:'Success',
                    message:'Record submitted for approval.',
                    variant:'success'
                })
            );

            window.location.reload();

        })

        // .catch(error=>{

        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title:'Error',
        //             message:error.body.message,
        //             variant:'error'
        //         })
        //     );

        // });
        .catch(error => {
            console.log(JSON.stringify(error));

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || error.message || 'Unknown error',
                    variant: 'error'
                })
            );
        });

    }

}