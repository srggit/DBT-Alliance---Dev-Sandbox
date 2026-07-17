public with sharing class NotificationHandler {

    private static final String STATUS_REJECTED          = 'Rejected';
    private static final String NOTIFICATION_STATUS_SENT = 'Sent'; // assumption - adjust if needed

    /**
     * Single method - call from both Proposal__c and Yearly_Schemes__c after-insert triggers:
     *   NotificationHandler.createNotifications('Yearly_Schemes__c', Trigger.new);
     *   NotificationHandler.createNotifications('Proposal__c', Trigger.new);
     */
    public static void createNotifications(String objectApiName, List<SObject> newRecords) {

        System.debug('========== NotificationHandler START ==========');
        System.debug('Object API Name: ' + objectApiName);

        // NULL CHECK: inputs must be valid
        if (String.isBlank(objectApiName)) {
            System.debug('Object API Name is blank. Exiting.');
            return;
        }

        if (newRecords == null || newRecords.isEmpty()) {
            System.debug('No records found. Exiting.');
            return;
        }

        List<Notification__c> notificationsToInsert = new List<Notification__c>();

        // ------------------------------------------------------------------
        // Yearly_Schemes__c -> one "For All" notification per newly active scheme
        // ------------------------------------------------------------------
        if (objectApiName == 'Yearly_Schemes__c') {

            for (SObject rec : newRecords) {

                // NULL CHECK: skip null entries
                if (rec == null) {
                    continue;
                }

                Yearly_Schemes__c scheme = (Yearly_Schemes__c) rec;

                // Only proceed when Is_Active__c is explicitly true (also handles null safely)
                if (scheme.Is_Active__c != true) {
                    System.debug('Skipping Yearly_Schemes__c ' + scheme.Id + ' - Is_Active__c not true.');
                    continue;
                }

                // NULL CHECK: Scheme__c must have a value to build the message
                if (String.isBlank(scheme.Scheme__c)) {
                    System.debug('Skipping Yearly_Schemes__c ' + scheme.Id + ' - Scheme__c is blank.');
                    continue;
                }

                Notification__c notif = new Notification__c();
                notif.For_all__c = true;
                notif.Message__c = 'New Yearly Scheme (' + scheme.Scheme__c + ') is introduced.';
                notif.Status__c  = NOTIFICATION_STATUS_SENT;
                // Contact__c intentionally left blank - this is a broadcast notification

                notificationsToInsert.add(notif);
            }

        // ------------------------------------------------------------------
        // Proposal__c -> one notification per Contact linked via
        // Applicant_Proposal_Association__c, when the Proposal is Rejected
        // ------------------------------------------------------------------
        } else if (objectApiName == 'Proposal__c') {

            // Step 1: collect Ids of newly-rejected proposals
            Set<Id> rejectedProposalIds = new Set<Id>();

            for (SObject rec : newRecords) {

                // NULL CHECK: skip null entries
                if (rec == null) {
                    continue;
                }

                Proposal__c proposal = (Proposal__c) rec;

                if (proposal.Id == null) {
                    continue;
                }

                if (proposal.Proposal_Status__c == STATUS_REJECTED) {
                    rejectedProposalIds.add(proposal.Id);
                }
            }

            System.debug('Rejected Proposal Ids: ' + rejectedProposalIds);

            if (!rejectedProposalIds.isEmpty()) {

                // Step 2: re-query proposals for Project_Title__c (safe even though it's
                // after-insert, guards against the field not being on the trigger's record set)
                Map<Id, Proposal__c> proposalsWithTitle = new Map<Id, Proposal__c>([
                    SELECT Id, Project_Title__c
                    FROM Proposal__c
                    WHERE Id IN :rejectedProposalIds
                ]);

                // Step 3: find Applicant_Proposal_Association__c records tied to these proposals
                List<Applicant_Proposal_Association__c> associations = [
                    SELECT Id, Contact__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c IN :rejectedProposalIds
                ];

                System.debug('Applicant Proposal Associations Found: ' + associations.size());

                for (Applicant_Proposal_Association__c apa : associations) {

                    // NULL CHECK: need both a Contact and a Proposal to build a valid notification
                    if (apa == null || apa.Contact__c == null || apa.Proposal__c == null) {
                        System.debug('Skipping invalid Applicant_Proposal_Association__c row: ' + apa);
                        continue;
                    }

                    Proposal__c relatedProposal = proposalsWithTitle.get(apa.Proposal__c);

                    // NULL CHECK: proposal must still be resolvable
                    if (relatedProposal == null) {
                        System.debug('No matching Proposal found for APA: ' + apa.Id);
                        continue;
                    }

                    String projectTitle = String.isBlank(relatedProposal.Project_Title__c)
                        ? ''
                        : relatedProposal.Project_Title__c;

                    Notification__c notif = new Notification__c();
                    notif.For_all__c = false;
                    notif.Contact__c = apa.Contact__c;
                    notif.Message__c = 'Your Proposal ' + projectTitle + ' is Rejected.';
                    notif.Status__c  = NOTIFICATION_STATUS_SENT;

                    notificationsToInsert.add(notif);
                }
            }

        } else {
            System.debug('Unsupported Object API Name for notifications: ' + objectApiName);
            return;
        }

        System.debug('Total Notifications To Insert: ' + notificationsToInsert.size());

        if (!notificationsToInsert.isEmpty()) {
            insert notificationsToInsert;
            System.debug('Notifications Inserted Successfully.');
        } else {
            System.debug('No Notifications to insert.');
        }

        System.debug('========== NotificationHandler END ==========');
    }
}