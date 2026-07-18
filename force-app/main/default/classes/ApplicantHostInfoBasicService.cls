@RestResource(urlMapping='/applicantHostInfoBasic/*')
global without sharing class ApplicantHostInfoBasicService {

    @HttpGet
    global static ApplicantHostWrapper getApplicantHostInfo() {

        ApplicantHostWrapper response = new ApplicantHostWrapper();

        try {
            String proposalId = getParam('proposalId');
            String contactId = getParam('ContactId', 'contactId');

            if (String.isNotBlank(proposalId)) {
                // Approach 1: proposalId provided
                populateByProposal(proposalId,contactId, response);

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

    private static void populateByProposal(String proposalId, String contactId, ApplicantHostWrapper response) {

        // Fetch the Proposal's checkbox value
        List<Proposal__c> proposals = [SELECT Id, Proposal_In_Basic_Biomedical_Research__c FROM Proposal__c WHERE Id = :proposalId LIMIT 1];
        Boolean proposalInBasicBiomedicalResearch = proposals.isEmpty() ? false : proposals[0].Proposal_In_Basic_Biomedical_Research__c;

        // Fetch the Applicant Proposal Association for this Proposal
        List<Applicant_Proposal_Association__c> apas = [
            SELECT Id, Contact__c,Proposal__c
            FROM Applicant_Proposal_Association__c
            WHERE Proposal__c = :proposalId And Contact__c = : contactId  
            LIMIT 1];
        Id applicantProposalAssociationId = apas.isEmpty() ? null : apas[0].Id;


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

        List<AssociationWrapper> associationWrappers = new List<AssociationWrapper>();
        for (Applicant_Host_Association__c assoc : associations) {
            AssociationWrapper aw = new AssociationWrapper();
            aw.associationId = assoc.Id;
            aw.associationName = assoc.Name;
            aw.proposalId = assoc.Proposal__c;
            aw.proposalInBasicBiomedicalResearch = proposalInBasicBiomedicalResearch;
            aw.isNonProfit = assoc.Is_the_Host_Instituition_not_for_profit__c;
            aw.ownerId = assoc.OwnerId;

            if (assoc.Host__c != null && hostAccountMap.containsKey(assoc.Host__c)) {
                Account host = hostAccountMap.get(assoc.Host__c);
                aw.host = new HostWrapper(host);
            }

            associationWrappers.add(aw);
        }

        response.success = true;
        response.message = 'Proposal host details fetched successfully.';
        response.proposalId = proposalId;
        response.applicantProposalAssociationId = applicantProposalAssociationId;
        response.associations = associationWrappers;
    }

    // ---------- Case 2: proposalId not provided ----------

    private static void populateAllHosts(ApplicantHostWrapper response) {

        List<Account> allHosts = [
            SELECT Id, Name, Phone, Email__c, District__c,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
        ];

        List<HostWrapper> hostWrappers = new List<HostWrapper>();
        for (Account acc : allHosts) {
            hostWrappers.add(new HostWrapper(acc));
        }

        response.success = true;
        response.message = 'All Host accounts fetched successfully.';
        response.hosts = hostWrappers;
    }

    // ---------- Wrapper Classes ----------

    global class ApplicantHostWrapper {
        global Boolean success;
        global String message;
        global Id proposalId;
        global Id applicantId;
        global Id applicantProposalAssociationId;
        global List<AssociationWrapper> associations;
        global List<HostWrapper> hosts;
    }

    global class AssociationWrapper {
        global Id associationId;
        global String associationName;
        global Id proposalId;
        global Boolean proposalInBasicBiomedicalResearch;
        global String isNonProfit;
        global Id ownerId;
        global HostWrapper host;
    }

    // Single, unified Host wrapper - used in both Approach 1 (inside association) and Approach 2 (top-level list)
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

        global HostWrapper(Account acc) {
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
        }
    }
}