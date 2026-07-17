public with sharing class GenericApplicantAssociationHandler {

    private static final String STATUS_DRAFT = 'Draft';
    //private static final String STAGE_PRELIMS = 'Prelims';

    // When true, skip Contact -> APA cloning (used when caller inserts both copies)
    public static Boolean bypassAssociationSync = false;

    public static void syncAssociationRecords(String objectApiName, List<SObject> newRecords) {

        System.debug('========== GenericApplicantAssociationHandler START ==========');
        System.debug('Object API Name: ' + objectApiName);
        System.debug('New Records Size: ' + (newRecords == null ? 0 : newRecords.size()));

        if (bypassAssociationSync) {
            System.debug('Bypassing Association Sync.');
            return;
        }
        
        // NULL CHECK: objectApiName must be provided
        if (String.isBlank(objectApiName)) {
            System.debug('Object API Name is blank. Exiting.');
            return;
        }

        // NULL CHECK: newRecords must not be null/empty
        if (newRecords == null || newRecords.isEmpty()) {
            System.debug('No records found. Exiting.');
            return;
        }

        // Collect Contact Ids
        Set<Id> contactIds = new Set<Id>();

        for (SObject record : newRecords) {

            // NULL CHECK: skip null entries in the list
            if (record == null) {
                System.debug('Skipping null record in newRecords list.');
                continue;
            }

            Id contactId = (Id) record.get('Contact__c');
            System.debug('Processing Record Id: ' + record.Id + ' Contact Id: ' + contactId);

            if (contactId != null) {
                contactIds.add(contactId);
            }
        }

        System.debug('Collected Contact Ids: ' + contactIds);

        if (contactIds.isEmpty()) {
            System.debug('No Contact Ids found. Exiting.');
            return;
        }

        // Contact -> Applicant Proposal Associations
        Map<Id, List<Applicant_Proposal_Association__c>> contactToAssociations =
            new Map<Id, List<Applicant_Proposal_Association__c>>();

        Set<Id> associationIds = new Set<Id>();
        Set<Id> proposalIds = new Set<Id>();

        List<Applicant_Proposal_Association__c> associationList = [
            SELECT Id,
                   Contact__c,
                   Proposal__c,
                   Proposal__r.Yearly_Scheme__r.Year__r.Is_Active__c,
                   Proposal__r.Yearly_Scheme__r.Year__r.Is_Current_Year__c
            FROM Applicant_Proposal_Association__c
            WHERE Contact__c IN :contactIds
            AND Proposal__r.Yearly_Scheme__r.Is_Active__c = true
            AND Proposal__r.Yearly_Scheme__r.Year__r.Is_Active__c = true
            AND Proposal__r.Yearly_Scheme__r.Year__r.Is_Current_Year__c = true
        ];

        System.debug('Applicant Proposal Associations Found: ' + associationList.size());

        for (Applicant_Proposal_Association__c apa : associationList) {

            // NULL CHECK: skip malformed rows (defensive - Contact__c is filtered non-null,
            // but guards against future query changes)
            if (apa == null || apa.Id == null || apa.Contact__c == null) {
                System.debug('Skipping invalid Applicant_Proposal_Association__c row: ' + apa);
                continue;
            }

            System.debug('APA -> ' + apa);

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

        System.debug('Contact To Associations Map: ' + contactToAssociations);
        System.debug('Association Ids: ' + associationIds);
        System.debug('Proposal Ids: ' + proposalIds);

        if (contactToAssociations.isEmpty()) {
            System.debug('No Applicant Proposal Associations found. Exiting.');
            return;
        }

        // Count records by Contact
        Map<Id, Integer> contactCountMap = new Map<Id, Integer>();

        String contactCountQuery =
            'SELECT Contact__c cId, COUNT(Id) cnt ' +
            'FROM ' + objectApiName +
            ' WHERE Contact__c IN :contactIds ' +
            'GROUP BY Contact__c';

        System.debug('Contact Count Query: ' + contactCountQuery);

        for (AggregateResult ar : Database.query(contactCountQuery)) {

            // NULL CHECK: aggregate row / grouped key / count value
            if (ar == null) {
                continue;
            }

            Id cId = (Id) ar.get('cId');
            Object cntRaw = ar.get('cnt');

            if (cId == null || cntRaw == null) {
                System.debug('Skipping contact count row with null key/count: ' + ar);
                continue;
            }

            contactCountMap.put(cId, (Integer) cntRaw);
        }

        System.debug('Contact Count Map: ' + contactCountMap);

        // Count records by Association
        Map<Id, Integer> associationCountMap = new Map<Id, Integer>();

        if (!associationIds.isEmpty()) {

            String associationCountQuery =
                'SELECT Applicant_Proposal_Association__c apaId, COUNT(Id) cnt ' +
                'FROM ' + objectApiName +
                ' WHERE Applicant_Proposal_Association__c IN :associationIds ' +
                'GROUP BY Applicant_Proposal_Association__c';

            System.debug('Association Count Query: ' + associationCountQuery);

            for (AggregateResult ar : Database.query(associationCountQuery)) {

                // NULL CHECK: aggregate row / grouped key / count value
                if (ar == null) {
                    continue;
                }

                Id apaId = (Id) ar.get('apaId');
                Object cntRaw = ar.get('cnt');

                if (apaId == null || cntRaw == null) {
                    System.debug('Skipping association count row with null key/count: ' + ar);
                    continue;
                }

                associationCountMap.put(apaId, (Integer) cntRaw);
            }
        }

        System.debug('Association Count Map: ' + associationCountMap);

        // Qualified Proposals
        Set<Id> qualifiedProposalIds = new Set<Id>();

        if (!proposalIds.isEmpty()) {
            system.debug('Proposal Ids to check for qualification: ' + proposalIds);
            List<Proposal__c> proposalList = [
                SELECT Id
                FROM Proposal__c
                WHERE Id IN :proposalIds
                AND Proposal_Status__c = :STATUS_DRAFT
            ];

            System.debug('Qualified Proposal Records: ' + proposalList.size());

            for (Proposal__c proposal : proposalList) {
                // NULL CHECK: defensive, SOQL rows/Id should never be null here
                if (proposal == null || proposal.Id == null) {
                    continue;
                }
                qualifiedProposalIds.add(proposal.Id);
            }
        }

        System.debug('Qualified Proposal Ids: ' + qualifiedProposalIds);

        // Create clones
        List<SObject> recordsToInsert = new List<SObject>();

        for (SObject record : newRecords) {

            // NULL CHECK: skip null entries in the list
            if (record == null) {
                System.debug('Skipping null record in newRecords list.');
                continue;
            }

            Id contactId = (Id) record.get('Contact__c');

            if (contactId == null) {
                System.debug('Skipping Record ' + record.Id + ' because Contact__c is null.');
                continue;
            }

            List<Applicant_Proposal_Association__c> associations =
                contactToAssociations.get(contactId);

            // NULL CHECK: no associations found / empty list for this contact
            if (associations == null || associations.isEmpty()) {
                System.debug('No associations found for Contact: ' + contactId);
                continue;
            }

            Integer contactCount =
                contactCountMap.containsKey(contactId)
                ? contactCountMap.get(contactId)
                : 0;

            System.debug('-------------------------------------------');
            System.debug('Processing Record: ' + record.Id);
            System.debug('Contact Id: ' + contactId);
            System.debug('Contact Count: ' + contactCount);

            for (Applicant_Proposal_Association__c apa : associations) {

                // NULL CHECK: skip malformed association entries
                if (apa == null || apa.Id == null) {
                    System.debug('Skipping null/invalid Applicant_Proposal_Association__c entry.');
                    continue;
                }

                Integer associationCount =
                    associationCountMap.containsKey(apa.Id)
                    ? associationCountMap.get(apa.Id)
                    : 0;

                System.debug('Checking APA: ' + apa.Id);
                System.debug('Association Count: ' + associationCount);

                if (associationCount == contactCount) {
                    System.debug('Skipping APA because Association Count equals Contact Count.');
                    continue;
                }

                if (apa.Proposal__c == null ||
                    !qualifiedProposalIds.contains(apa.Proposal__c)) {

                    System.debug('Skipping APA because Proposal is not qualified. Proposal Id: ' + apa.Proposal__c);
                    continue;
                }

                System.debug('Creating clone for APA: ' + apa.Id);

                SObject cloneRecord = record.clone(false, false, false, false);

                // NULL CHECK: clone should never be null, but guard anyway
                if (cloneRecord == null) {
                    System.debug('Clone operation returned null for Record: ' + record.Id);
                    continue;
                }

                cloneRecord.put('Contact__c', null);
                cloneRecord.put(
                    'Applicant_Proposal_Association__c',
                    apa.Id
                );

                recordsToInsert.add(cloneRecord);
            }
        }

        System.debug('Total Clone Records To Insert: ' + recordsToInsert.size());

        if (!recordsToInsert.isEmpty()) {
            System.debug('Inserting Clone Records...');
            insert recordsToInsert;
            System.debug('Clone Records Inserted Successfully.');
        } else {
            System.debug('No Clone Records to Insert.');
        }

        System.debug('========== GenericApplicantAssociationHandler END ==========');
    }
}