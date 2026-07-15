public with sharing class GenericApplicantAssociationHandler {

    private static final String STATUS_DRAFT = 'Draft';
    private static final String STAGE_PRELIMS = 'Prelims';

    public static void handleAfterInsert(String objectApiName, List<SObject> newRecords) {

        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        // Collect Contact Ids
        Set<Id> contactIds = new Set<Id>();

        for (SObject record : newRecords) {
            Id contactId = (Id)record.get('Contact__c');
            if (contactId != null) {
                contactIds.add(contactId);
            }
        }

        if (contactIds.isEmpty()) {
            return;
        }

        // Contact -> Applicant Proposal Associations
        Map<Id, List<Applicant_Proposal_Association__c>> contactToAssociations =
            new Map<Id, List<Applicant_Proposal_Association__c>>();

        Set<Id> associationIds = new Set<Id>();
        Set<Id> proposalIds = new Set<Id>();

        for (Applicant_Proposal_Association__c apa : [
            SELECT Id, Contact__c, Proposal__c
            FROM Applicant_Proposal_Association__c
            WHERE Contact__c IN :contactIds
        ]) {

            if (!contactToAssociations.containsKey(apa.Contact__c)) {
                contactToAssociations.put(
                    apa.Contact__c,
                    new List<Applicant_Proposal_Association__c>()
                );
            }

            contactToAssociations.get(apa.Contact__c).add(apa);
            associationIds.add(apa.Id);

            if (apa.Proposal__c != null) {
                proposalIds.add(apa.Proposal__c);
            }
        }

        if (contactToAssociations.isEmpty()) {
            return;
        }

        // Count records by Contact
        Map<Id, Integer> contactCountMap = new Map<Id, Integer>();

        String contactCountQuery =
            'SELECT Contact__c cId, COUNT(Id) cnt ' +
            'FROM ' + objectApiName +
            ' WHERE Contact__c IN :contactIds ' +
            'GROUP BY Contact__c';

        for (AggregateResult ar : Database.query(contactCountQuery)) {
            contactCountMap.put(
                (Id)ar.get('cId'),
                (Integer)ar.get('cnt')
            );
        }

        // Count records by Association
        Map<Id, Integer> associationCountMap = new Map<Id, Integer>();

        if (!associationIds.isEmpty()) {

            String associationCountQuery =
                'SELECT Applicant_Proposal_Association__c apaId, COUNT(Id) cnt ' +
                'FROM ' + objectApiName +
                ' WHERE Applicant_Proposal_Association__c IN :associationIds ' +
                'GROUP BY Applicant_Proposal_Association__c';

            for (AggregateResult ar : Database.query(associationCountQuery)) {
                associationCountMap.put(
                    (Id)ar.get('apaId'),
                    (Integer)ar.get('cnt')
                );
            }
        }

        // Qualified Proposals
        Set<Id> qualifiedProposalIds = new Set<Id>();

        if (!proposalIds.isEmpty()) {

            for (Proposal__c proposal : [
                SELECT Id
                FROM Proposal__c
                WHERE Id IN :proposalIds
                AND Proposal_Status__c = :STATUS_DRAFT
                AND Application_Stages__c = :STAGE_PRELIMS
            ]) {
                qualifiedProposalIds.add(proposal.Id);
            }
        }

        // Create clones
        List<SObject> recordsToInsert = new List<SObject>();

        for (SObject record : newRecords) {

            Id contactId = (Id)record.get('Contact__c');

            if (contactId == null) {
                continue;
            }

            List<Applicant_Proposal_Association__c> associations =
                contactToAssociations.get(contactId);

            if (associations == null) {
                continue;
            }

            Integer contactCount =
                contactCountMap.containsKey(contactId)
                ? contactCountMap.get(contactId)
                : 0;

            for (Applicant_Proposal_Association__c apa : associations) {

                Integer associationCount =
                    associationCountMap.containsKey(apa.Id)
                    ? associationCountMap.get(apa.Id)
                    : 0;

                if (associationCount == contactCount) {
                    continue;
                }

                if (apa.Proposal__c == null ||
                    !qualifiedProposalIds.contains(apa.Proposal__c)) {
                    continue;
                }

                SObject cloneRecord = record.clone(false, false, false, false);

                cloneRecord.put('Contact__c', null);
                cloneRecord.put(
                    'Applicant_Proposal_Association__c',
                    apa.Id
                );

                recordsToInsert.add(cloneRecord);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }
}