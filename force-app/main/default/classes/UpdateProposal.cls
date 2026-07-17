public with sharing class UpdateProposal {

    public static void updateProposal(List<Proposal__c> newProposals) {
        for(Proposal__c proposal : newProposals) {
            proposal.Name = proposal.Name + ' - ' + proposal.Yearly_Scheme__r.Name;
        }
    }
}