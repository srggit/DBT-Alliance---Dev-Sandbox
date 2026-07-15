public without sharing class ProposalTriggerHandler {

    public static void generateProposalId(Set<Id> proposalIds) {

        List<Proposal__c> proposals = [SELECT Id,Name,Proposal_Id__c,Yearly_Scheme__r.Application_Stages__c,
										Yearly_Scheme__r.Year__r.Name,Yearly_Scheme__r.Scheme_Items__r.Name 
										FROM Proposal__c WHERE Id IN :proposalIds];

        List<Proposal__c> updates = new List<Proposal__c>();

        for (Proposal__c proposal : proposals) {
            if(proposal.Yearly_Scheme__r == null)
                continue;

            String schemeName = proposal.Yearly_Scheme__r.Scheme_Items__r.Name;
            String schemeCode = '';

            // Extract value inside []
            Integer startIndex = schemeName.indexOf('[');
			Integer endIndex = schemeName.indexOf(']');

			if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
				schemeCode = schemeName.substring(startIndex + 1, endIndex);
			}
            // P or F
            String stageCode = proposal.Yearly_Scheme__r.Application_Stages__c == 'Prelims' ? 'P' : 'F';
            // Last two digits of Year
            String yearCode = '';
            if(proposal.Yearly_Scheme__r.Year__r.Name != null &&
               proposal.Yearly_Scheme__r.Year__r.Name.length() >= 2){
                yearCode = proposal.Yearly_Scheme__r.Year__r.Name.right(2);
            }
            // PROP-00001 -> 00001
            String autoNumber = '';
            if(proposal.Name != null && proposal.Name.contains('-')){
                autoNumber = proposal.Name.substringAfter('-');
            }

            proposal.Proposal_Id__c = 'IA/BRCP/' + schemeCode + '/' + stageCode + '/' + yearCode + '/' + autoNumber;
            updates.add(proposal);
        }

        if(!updates.isEmpty()){
            update updates;
        }
    }
}