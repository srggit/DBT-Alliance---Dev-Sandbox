public with sharing class TriggerHandlerforEducation {

    // Adjust these if your org's actual picklist API values differ
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STAGE_PRELIMS = 'Prelims';

    public static void handleAfterInsert(List<Education_Details__c> newEducationRecords) {

        // Step 1: Collect Contact Ids from newly inserted records that are tagged to a Contact.
        // Clones we create later have Contact__c = null, so they never land in this set -
        // this is what prevents infinite recursion without needing a static flag.
        System.debug('New Education Records: ' + newEducationRecords);
        Set<Id> contactIds = new Set<Id>();
        for (Education_Details__c ed : newEducationRecords) {
            if (ed.Contact__c != null) {
                contactIds.add(ed.Contact__c);
            }
        }
        System.debug('New Education Records contact Ids: ' + contactIds);

        if (contactIds.isEmpty()) {
            return;
        }

        // Step 2: Query Applicant_Proposal_Association__c records tagged to these contacts
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
                contactToAssociations.put(apa.Contact__c, new List<Applicant_Proposal_Association__c>());
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

        // Step 3: Count of Education_Details__c records tagged directly to each contact
        Map<Id, Integer> contactEducationCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Contact__c cId, COUNT(Id) cnt
            FROM Education_Details__c
            WHERE Contact__c IN :contactIds
            GROUP BY Contact__c
        ]) {
            contactEducationCount.put((Id) ar.get('cId'), (Integer) ar.get('cnt'));
        }

        // Step 4: Count of Education_Details__c records tagged to each Applicant_Proposal_Association__c
        Map<Id, Integer> associationEducationCount = new Map<Id, Integer>();
        if (!associationIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT Applicant_Proposal_Association__c apaId, COUNT(Id) cnt
                FROM Education_Details__c
                WHERE Applicant_Proposal_Association__c IN :associationIds
                GROUP BY Applicant_Proposal_Association__c
            ]) {
                associationEducationCount.put((Id) ar.get('apaId'), (Integer) ar.get('cnt'));
            }
        }

        // Step 5: Qualifying Proposal__c records - Draft status and Prelims stage only
        Set<Id> qualifyingProposalIds = new Set<Id>();
        if (!proposalIds.isEmpty()) {
            for (Proposal__c p : [
                SELECT Id
                FROM Proposal__c
                WHERE Id IN :proposalIds
                AND Proposal_Status__c = :STATUS_DRAFT
                AND Application_Stages__c = :STAGE_PRELIMS
            ]) {
                qualifyingProposalIds.add(p.Id);
            }
        }

        // Step 6: For each new record, for each association tied to its contact,
        // clone into the association only if counts differ AND the proposal qualifies.
        List<Education_Details__c> clonesToInsert = new List<Education_Details__c>();

        for (Education_Details__c ed : newEducationRecords) {
            if (ed.Contact__c == null) {
                continue;
            }

            List<Applicant_Proposal_Association__c> associations = contactToAssociations.get(ed.Contact__c);
            if (associations == null || associations.isEmpty()) {
                continue;
            }

            Integer contactCount = contactEducationCount.containsKey(ed.Contact__c)
                ? contactEducationCount.get(ed.Contact__c)
                : 0;

            for (Applicant_Proposal_Association__c apa : associations) {
                Integer apaCount = associationEducationCount.containsKey(apa.Id)
                    ? associationEducationCount.get(apa.Id)
                    : 0;

                // Counts match -> this association is already in sync, skip it
                if (apaCount == contactCount) {
                    continue;
                }

                // Counts differ -> only clone if the related Proposal is Draft + Prelims
                if (apa.Proposal__c != null && qualifyingProposalIds.contains(apa.Proposal__c)) {
                    Education_Details__c clonedRecord = ed.clone(false, false, false, false);
                    clonedRecord.Contact__c = null; // do NOT tag the contact on the clone
                    clonedRecord.Applicant_Proposal_Association__c = apa.Id;
                    clonesToInsert.add(clonedRecord);
                }
            }
        }

        // Step 7: Bulk insert the clones
        if (!clonesToInsert.isEmpty()) {
            insert clonesToInsert;
        }
    }
}