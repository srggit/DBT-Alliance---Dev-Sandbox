/**
 * @description
 * GET REST API to fetch Applicant Host Association / Host / Participant data.
 *
 * Endpoint (Experience Cloud / external):
 *   GET /services/apexrest/applicantHostInfo/?proposalId={proposalId}&ContactId={contactId}
 *
 * Behavior:
 *   - If proposalId IS provided (Approach 1):
 *       -> Applicant_Host_Association__c records for that Proposal, each with
 *          its Host Account, whose "hostContacts" are now the Participants
 *          from Proposal_Participant_Association__c for that same Proposal
 *          (each entry includes the Participant's Role + full Contact data).
 *      (ContactId is ignored in this case.)
 *   - If proposalId is NOT provided (Approach 2):
 *       -> ContactId is validated first. If ContactId is missing, malformed,
 *          or does not match an existing Contact, the response returns
 *          success = false, message = "Applicant is not exist." and no data.
 *       -> If the Contact exists, returns ALL Accounts (Host) with all their Contacts.
 *
 * Example:
 *   GET https://<your-domain>/services/apexrest/applicantHostInfo/?proposalId=a0YXXXXXXXXXXXXAAA
 *   GET https://<your-domain>/services/apexrest/applicantHostInfo/?ContactId=003XXXXXXXXXXXXAAA
 *
 * Response shape (proposalId provided):
 * {
 *   "success": true,
 *   "message": "Proposal host details fetched successfully.",
 *   "proposalId": "a0Y...",
 *   "associations": [
 *     {
 *       "associationId": "a0X...",
 *       "associationName": "AHA-0001",
 *       "proposalId": "a0Y...",
 *       "isNonProfit": "Yes",
 *       "ownerId": "005...",
 *       "host": {
 *         "id": "001...",
 *         "name": "Some University",
 *         "phone": "123-456-7890",
 *         "email": "contact@host.org",
 *         "district": "...",
 *         "billingStreet": "...",
 *         "billingCity": "...",
 *         "billingState": "...",
 *         "billingPostalCode": "...",
 *         "billingCountry": "...",
 *         "hostContacts": [
 *           {
 *             "participantAssociationId": "a0V...",
 *             "roles": "Mentor",
 *             "contact": { ...Contact fields... }
 *           }
 *         ]
 *       }
 *     }
 *   ]
 * }
 *
 * Response shape (proposalId NOT provided):
 * {
 *   "success": true,
 *   "message": "All Host accounts fetched successfully.",
 *   "hosts": [
 *     {
 *       "id": "001...",
 *       "name": "Some University",
 *       ...
 *       "hostContacts": [ { ...Contact fields... }, ... ]
 *     }
 *   ]
 * }
 */
@RestResource(urlMapping='/applicantHostInfo/*')
global without sharing class ApplicantHostInfoService {

    @HttpGet
    global static ApplicantHostWrapper getApplicantHostInfo() {

        ApplicantHostWrapper response = new ApplicantHostWrapper();

        try {
            String proposalId = getParam('proposalId');
            String contactId = getParam('ContactId', 'contactId');

            if (String.isNotBlank(proposalId)) {
                // Approach 1: proposalId provided
                populateByProposal(proposalId, response);

            } else {
                // Approach 2: no proposalId -> verify the Applicant (Contact) exists first
                response.applicantId = contactId;

                if (String.isBlank(contactId) || !isValidContactId(contactId)) {
                    response.success = false;
                    response.message = 'Applicant is not exist.';
                    return response;
                }

                Integer contactCount = [SELECT COUNT() FROM Contact WHERE Id = :contactId];
                if (contactCount == 0) {
                    response.success = false;
                    response.message = 'Applicant is not exist.';
                    return response;
                }

                populateAllHosts(response);
            }

        } catch (Exception ex) {
            response.success = false;
            response.message = 'An error occurred while fetching details: ' + ex.getMessage();
        }

        return response;
    }

    // Reads a query param, trying each provided key name in order (handles case differences).
    private static String getParam(String key1) {
        return getParam(key1, null);
    }

    private static String getParam(String key1, String key2) {
        Map<String, String> params = RestContext.request.params;
        if (params.containsKey(key1) && String.isNotBlank(params.get(key1))) {
            return params.get(key1);
        }
        if (String.isNotBlank(key2) && params.containsKey(key2) && String.isNotBlank(params.get(key2))) {
            return params.get(key2);
        }
        return null;
    }

    private static Boolean isValidContactId(String idStr) {
        try {
            Id recId = (Id) idStr;
            return recId.getSObjectType() == Contact.SObjectType;
        } catch (Exception e) {
            return false;
        }
    }

    // ---------- Case 1: proposalId provided ----------

    private static void populateByProposal(String proposalId, ApplicantHostWrapper response) {

        List<Applicant_Host_Association__c> associations = [
            SELECT Id, Name, Applicant__c, Host__c, Proposal__c,
                   Is_the_Host_Instituition_not_for_profit__c, OwnerId, CurrencyIsoCode
            FROM Applicant_Host_Association__c
            WHERE Proposal__c = :proposalId
        ];

        Set<Id> hostIds = new Set<Id>();
        for (Applicant_Host_Association__c assoc : associations) {
            if (assoc.Host__c != null) {
                hostIds.add(assoc.Host__c);
            }
        }

        Map<Id, Account> hostAccountMap = hostIds.isEmpty()
            ? new Map<Id, Account>()
            : new Map<Id, Account>([
                SELECT Id, Name, Phone, Email__c, District__c,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                FROM Account
                WHERE Id IN :hostIds
            ]);

        // Pull Proposal Participants for this Proposal, with Role + full Contact data,
        // grouped by the Participant's Host Account (Participant__r.AccountId).
        Map<Id, List<ParticipantWrapper>> participantsByHost = getParticipantsByHostAccountId(proposalId, hostIds);

        List<AssociationWrapper> associationWrappers = new List<AssociationWrapper>();
        for (Applicant_Host_Association__c assoc : associations) {
            AssociationWrapper aw = new AssociationWrapper();
            aw.associationId = assoc.Id;
            aw.associationName = assoc.Name;
            aw.proposalId = assoc.Proposal__c;
            aw.isNonProfit = assoc.Is_the_Host_Instituition_not_for_profit__c;
            aw.ownerId = assoc.OwnerId;

            if (assoc.Host__c != null && hostAccountMap.containsKey(assoc.Host__c)) {
                Account host = hostAccountMap.get(assoc.Host__c);
                List<ParticipantWrapper> participantsForHost = participantsByHost.containsKey(host.Id)
                    ? participantsByHost.get(host.Id)
                    : new List<ParticipantWrapper>();
                aw.host = new HostWithParticipantsWrapper(host, participantsForHost);
            }

            associationWrappers.add(aw);
        }

        response.success = true;
        response.message = 'Proposal host details fetched successfully.';
        response.proposalId = proposalId;
        response.associations = associationWrappers;
    }

    private static Map<Id, List<ParticipantWrapper>> getParticipantsByHostAccountId(String proposalId, Set<Id> hostIds) {

        Map<Id, List<ParticipantWrapper>> participantsByHost = new Map<Id, List<ParticipantWrapper>>();

        List<Proposal_Participant_Association__c> ppas = [
            SELECT Id, Name, Roles__c, OwnerId,
                   Participant__c,
                   Participant__r.Id, Participant__r.Name, Participant__r.Salutation,
                   Participant__r.FirstName, Participant__r.MiddleName, Participant__r.LastName,
                   Participant__r.Suffix, Participant__r.AccountId, Participant__r.Email,
                   Participant__r.Birthdate, Participant__r.Department, Participant__r.Gender__c,
                   Participant__r.Nationality__c, Participant__r.MailingStreet,
                   Participant__r.MailingCity, Participant__r.MailingState,
                   Participant__r.MailingPostalCode, Participant__r.MailingCountry,
                   Participant__r.OwnerId, Participant__r.CreatedById,
                   Participant__r.LastModifiedById, Participant__r.CurrencyIsoCode
            FROM Proposal_Participant_Association__c
            WHERE Proposal__c = :proposalId AND Participant__c != null
        ];

        for (Proposal_Participant_Association__c ppa : ppas) {
            if (ppa.Participant__r == null || ppa.Participant__r.AccountId == null) {
                continue;
            }
            Id hostAccountId = ppa.Participant__r.AccountId;
            if (!hostIds.contains(hostAccountId)) {
                continue; // only include participants belonging to one of this proposal's Host accounts
            }

            ParticipantWrapper pw = new ParticipantWrapper();
            pw.participantAssociationId = ppa.Id;
            pw.roles = ppa.Roles__c;
            pw.contact = ppa.Participant__r;

            if (!participantsByHost.containsKey(hostAccountId)) {
                participantsByHost.put(hostAccountId, new List<ParticipantWrapper>());
            }
            participantsByHost.get(hostAccountId).add(pw);
        }

        return participantsByHost;
    }

    // ---------- Case 2: proposalId not provided ----------

    private static void populateAllHosts(ApplicantHostWrapper response) {

        List<Account> allHosts = [
            SELECT Id, Name, Phone, Email__c, District__c,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
        ];

        Set<Id> hostIds = new Set<Id>();
        for (Account acc : allHosts) {
            hostIds.add(acc.Id);
        }

        Map<Id, List<Contact>> contactsByHost = getContactsByAccountId(hostIds);

        List<HostWrapper> hostWrappers = new List<HostWrapper>();
        for (Account acc : allHosts) {
            List<Contact> contactsForHost = contactsByHost.containsKey(acc.Id)
                ? contactsByHost.get(acc.Id)
                : new List<Contact>();
            hostWrappers.add(new HostWrapper(acc, contactsForHost));
        }

        response.success = true;
        response.message = 'All Host accounts fetched successfully.';
        response.hosts = hostWrappers;
    }

    // ---------- Shared helper ----------

    private static Map<Id, List<Contact>> getContactsByAccountId(Set<Id> accountIds) {
        Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();

        if (accountIds.isEmpty()) {
            return contactsByAccount;
        }

        List<Contact> contacts = [
            SELECT Id, Name, Salutation, FirstName, MiddleName, LastName, Suffix,
                   AccountId, Email, Birthdate, Department, Gender__c, Nationality__c,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                   OwnerId, CreatedById, LastModifiedById, CurrencyIsoCode
            FROM Contact
            WHERE AccountId IN :accountIds
        ];

        for (Contact c : contacts) {
            if (!contactsByAccount.containsKey(c.AccountId)) {
                contactsByAccount.put(c.AccountId, new List<Contact>());
            }
            contactsByAccount.get(c.AccountId).add(c);
        }

        return contactsByAccount;
    }

    // ---------- Wrapper Classes ----------

    global class ApplicantHostWrapper {
        global Boolean success;
        global String message;
        global Id proposalId;
        global Id applicantId;
        global List<AssociationWrapper> associations;
        global List<HostWrapper> hosts;
    }

    global class AssociationWrapper {
        global Id associationId;
        global String associationName;
        global Id proposalId;
        global String isNonProfit;
        global Id ownerId;
        global HostWithParticipantsWrapper host;
    }

    // Participant entry: Role from Proposal_Participant_Association__c + full Contact data
    global class ParticipantWrapper {
        global Id participantAssociationId;
        global String roles;
        global Contact contact;
    }

    // Used in Approach 1 (proposalId provided): hostContacts are Participants (with Role)
    global class HostWithParticipantsWrapper {
        global Id id;
        global String name;
        global String phone;
        global String email;
        global String district;
        global String billingStreet;
        global String billingCity;
        global String billingState;
        global String billingPostalCode;
        global String billingCountry;
        global List<ParticipantWrapper> hostContacts;

        global HostWithParticipantsWrapper(Account acc, List<ParticipantWrapper> participants) {
            this.id = acc.Id;
            this.name = acc.Name;
            this.phone = acc.Phone;
            this.email = acc.Email__c;
            this.district = acc.District__c;
            this.billingStreet = acc.BillingStreet;
            this.billingCity = acc.BillingCity;
            this.billingState = acc.BillingState;
            this.billingPostalCode = acc.BillingPostalCode;
            this.billingCountry = acc.BillingCountry;
            this.hostContacts = participants;
        }
    }

    // Used in Approach 2 (no proposalId): hostContacts are plain Contacts (no role context)
    global class HostWrapper {
        global Id id;
        global String name;
        global String phone;
        global String email;
        global String district;
        global String billingStreet;
        global String billingCity;
        global String billingState;
        global String billingPostalCode;
        global String billingCountry;
        global List<Contact> hostContacts;

        global HostWrapper(Account acc, List<Contact> contacts) {
            this.id = acc.Id;
            this.name = acc.Name;
            this.phone = acc.Phone;
            this.email = acc.Email__c;
            this.district = acc.District__c;
            this.billingStreet = acc.BillingStreet;
            this.billingCity = acc.BillingCity;
            this.billingState = acc.BillingState;
            this.billingPostalCode = acc.BillingPostalCode;
            this.billingCountry = acc.BillingCountry;
            this.hostContacts = contacts;
        }
    }
}