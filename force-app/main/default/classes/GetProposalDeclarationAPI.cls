/*
@RestResource(urlMapping='/ProposalDeclaration/get/*')
global without sharing class GetProposalDeclarationAPI {

    @HttpGet
    global static GetDeclarationResponseWrapper getDeclaration() {
        GetDeclarationResponseWrapper response = new GetDeclarationResponseWrapper();

        try {
            RestRequest req = RestContext.request;
            String apaId = req.params.get('apaId');
            String proposalId = req.params.get('proposalId');
            String contactId = req.params.get('contactId');

            Applicant_Proposal_Association__c apaRecord;

            if (String.isNotBlank(apaId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :apaId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given apaId.';
                    return response;
                }
                apaRecord = apaList[0];

            } else if (String.isNotBlank(proposalId) && String.isNotBlank(contactId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :proposalId
                    AND Contact__c = :contactId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given proposalId/contactId combination.';
                    return response;
                }
                apaRecord = apaList[0];

            } else {
                response.success = false;
                response.message = 'Either apaId, or both proposalId and contactId, must be provided.';
                return response;
            }

            response.declaration1 = apaRecord.Declaration_1__c;
            response.declaration2 = apaRecord.Declaration_2__c;
            response.apaId = apaRecord.Id;

            if (apaRecord.Proposal__c != null) {
                List<Proposal__c> proposalList = [
                    SELECT Id, Proposal_Status__c, Application_Date__c
                    FROM Proposal__c
                    WHERE Id = :apaRecord.Proposal__c
                    LIMIT 1
                ];
                if (!proposalList.isEmpty()) {
                    response.proposalId = proposalList[0].Id;
                    response.proposalStatus = proposalList[0].Proposal_Status__c;
                    response.applicationDate = proposalList[0].Application_Date__c;
                }
            }

            response.success = true;
            response.message = 'Declaration and proposal details retrieved successfully.';

        } catch (Exception ex) {
            response.success = false;
            response.message = 'Error retrieving declaration: ' + ex.getMessage();
        }

        return response;
    }

    global class GetDeclarationResponseWrapper {
        global Boolean success;
        global String message;
        global String apaId;
        global String proposalId;
        global Boolean declaration1;
        global Boolean declaration2;
        global String proposalStatus;
        global Date applicationDate;
    }
}*/








// @RestResource(urlMapping='/ProposalDeclaration/get/*')
// global without sharing class GetProposalDeclarationAPI {

//     @HttpGet
//     global static GetDeclarationResponseWrapper getDeclaration() {
//         GetDeclarationResponseWrapper response = new GetDeclarationResponseWrapper();

//         try {
//             RestRequest req = RestContext.request;
//             String apaId = req.params.get('apaId');
//             String proposalId = req.params.get('proposalId');
//             String contactId = req.params.get('contactId');

//             Applicant_Proposal_Association__c apaRecord;

//             if (String.isNotBlank(apaId)) {
//                 List<Applicant_Proposal_Association__c> apaList = [
//                     SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
//                     FROM Applicant_Proposal_Association__c
//                     WHERE Id = :apaId
//                     LIMIT 1
//                 ];
//                 if (apaList.isEmpty()) {
//                     response.success = false;
//                     response.message = 'No Applicant Proposal Association found for the given apaId.';
//                     return response;
//                 }
//                 apaRecord = apaList[0];

//             } else if (String.isNotBlank(proposalId) && String.isNotBlank(contactId)) {
//                 List<Applicant_Proposal_Association__c> apaList = [
//                     SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
//                     FROM Applicant_Proposal_Association__c
//                     WHERE Proposal__c = :proposalId
//                     AND Contact__c = :contactId
//                     LIMIT 1
//                 ];
//                 if (apaList.isEmpty()) {
//                     response.success = false;
//                     response.message = 'No Applicant Proposal Association found for the given proposalId/contactId combination.';
//                     return response;
//                 }
//                 apaRecord = apaList[0];

//             } else {
//                 response.success = false;
//                 response.message = 'Either apaId, or both proposalId and contactId, must be provided.';
//                 return response;
//             }

//             response.declaration1 = apaRecord.Declaration_1__c;
//             response.declaration2 = apaRecord.Declaration_2__c;
//             response.apaId = apaRecord.Id;

//             if (apaRecord.Proposal__c != null) {
//                 List<Proposal__c> proposalList = [
//                     SELECT Id, Proposal_Status__c, Application_Date__c
//                     FROM Proposal__c
//                     WHERE Id = :apaRecord.Proposal__c
//                     LIMIT 1
//                 ];
//                 if (!proposalList.isEmpty()) {
//                     response.proposalId = proposalList[0].Id;
//                     response.proposalStatus = proposalList[0].Proposal_Status__c;
//                     response.applicationDate = proposalList[0].Application_Date__c;
//                 }
//             }

//             // ---- Host Contact details ----
//             // Priority 1: contacts already saved as Proposal_Participant_Association__c for this proposal
//             // Priority 2 (fallback): all contacts under the Host Account(s) linked via Applicant_Host_Association__c
//             List<HostContactWrapper> hostContactDetails = new List<HostContactWrapper>();
//             Boolean hostContactsSourcedFromParticipants = false;

//             if (apaRecord.Proposal__c != null) {

//                 List<Proposal_Participant_Association__c> ppaList = [
//                     SELECT Id, Participant__c, Roles__c
//                     FROM Proposal_Participant_Association__c
//                     WHERE (Proposal__c = :apaRecord.Proposal__c OR Proposal__c = : proposalId)
//                     AND Participant__c != null
//                 ];

//                 Set<Id> contactIdsToQuery = new Set<Id>();
//                 Map<Id, String> contactIdToRole = new Map<Id, String>();

//                 if (!ppaList.isEmpty()) {
//                     hostContactsSourcedFromParticipants = true;
//                     for (Proposal_Participant_Association__c ppa : ppaList) {
//                         contactIdsToQuery.add(ppa.Participant__c);
//                         contactIdToRole.put(ppa.Participant__c, ppa.Roles__c);
//                     }
//                 } else {
//                     List<Applicant_Host_Association__c> ahaList = [
//                         SELECT Id, Host__c
//                         FROM Applicant_Host_Association__c
//                         WHERE (Proposal__c = :apaRecord.Proposal__c OR Proposal__c = : proposalId)
//                         AND Host__c != null
//                     ];

//                     if (!ahaList.isEmpty()) {
//                         Set<Id> hostAccountIds = new Set<Id>();
//                         for (Applicant_Host_Association__c aha : ahaList) {
//                             hostAccountIds.add(aha.Host__c);
//                         }

//                         List<Contact> hostAccountContacts = [
//                             SELECT Id FROM Contact WHERE AccountId IN :hostAccountIds
//                         ];
//                         for (Contact con : hostAccountContacts) {
//                             contactIdsToQuery.add(con.Id);
//                         }
//                     }
//                 }

//                 if (!contactIdsToQuery.isEmpty()) {
//                     List<Contact> contacts = [
//                         SELECT Id, Name, Salutation, FirstName, MiddleName, LastName, Suffix, Account.Name,
//                                AccountId, Email, Birthdate, Department, Gender__c, Nationality__c,
//                                MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
//                                OwnerId, CreatedById, LastModifiedById, CurrencyIsoCode
//                         FROM Contact
//                         WHERE Id IN :contactIdsToQuery
//                     ];

//                     for (Contact con : contacts) {
//                         HostContactWrapper hostWrapper = new HostContactWrapper();
//                         hostWrapper.contactId = con.Id;
//                         hostWrapper.name = con.Name;
//                         hostWrapper.salutation = con.Salutation;
//                         hostWrapper.firstName = con.FirstName;
//                         hostWrapper.middleName = con.MiddleName;
//                         hostWrapper.lastName = con.LastName;
//                         hostWrapper.suffix = con.Suffix;
//                         hostWrapper.accountId = con.AccountId;
//                         hostWrapper.accountName = con.Account.Name;
//                         hostWrapper.email = con.Email;
//                         hostWrapper.birthdate = con.Birthdate;
//                         hostWrapper.department = con.Department;
//                         hostWrapper.gender = con.Gender__c;
//                         hostWrapper.nationality = con.Nationality__c;
//                         hostWrapper.mailingStreet = con.MailingStreet;
//                         hostWrapper.mailingCity = con.MailingCity;
//                         hostWrapper.mailingState = con.MailingState;
//                         hostWrapper.mailingPostalCode = con.MailingPostalCode;
//                         hostWrapper.mailingCountry = con.MailingCountry;
//                         hostWrapper.currencyPicklist = con.CurrencyIsoCode;
//                         hostWrapper.role = contactIdToRole.get(con.Id);
//                         hostContactDetails.add(hostWrapper);
//                     }
//                 }
//             }

//             response.hostContactDetails = hostContactDetails;
//             response.hostContactsSourcedFromParticipants = hostContactsSourcedFromParticipants;

//             response.success = true;
//             response.message = 'Declaration and proposal details retrieved successfully.';

//         } catch (Exception ex) {
//             response.success = false;
//             response.message = 'Error retrieving declaration: ' + ex.getMessage();
//         }

//         return response;
//     }

//     global class GetDeclarationResponseWrapper {
//         global Boolean success;
//         global String message;
//         global String apaId;
//         global String proposalId;
//         global Boolean declaration1;
//         global Boolean declaration2;
//         global String proposalStatus;
//         global Date applicationDate;

//         global List<HostContactWrapper> hostContactDetails;
//         global Boolean hostContactsSourcedFromParticipants;
//     }

//     global class HostContactWrapper {
//         global Id contactId;
//         global String name;
//         global String salutation;
//         global String firstName;
//         global String middleName;
//         global String lastName;
//         global String suffix;
//         global Id accountId;
//         global String accountName;
//         global String email;
//         global Date birthdate;
//         global String department;
//         global String gender;
//         global String nationality;
//         global String mailingStreet;
//         global String mailingCity;
//         global String mailingState;
//         global String mailingPostalCode;
//         global String mailingCountry;
//         global String currencyPicklist;
//         global String role;
//     }
// }






@RestResource(urlMapping='/ProposalDeclaration/get/*')
global without sharing class GetProposalDeclarationAPI {

    @HttpGet
    global static GetDeclarationResponseWrapper getDeclaration() {
        GetDeclarationResponseWrapper response = new GetDeclarationResponseWrapper();

        try {
            RestRequest req = RestContext.request;
            String apaId = req.params.get('apaId');
            String proposalId = req.params.get('proposalId');
            String contactId = req.params.get('contactId');

            Applicant_Proposal_Association__c apaRecord;

            if (String.isNotBlank(apaId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Id = :apaId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given apaId.';
                    return response;
                }
                apaRecord = apaList[0];

            } else if (String.isNotBlank(proposalId) && String.isNotBlank(contactId)) {
                List<Applicant_Proposal_Association__c> apaList = [
                    SELECT Id, Declaration_1__c, Declaration_2__c, Proposal__c
                    FROM Applicant_Proposal_Association__c
                    WHERE Proposal__c = :proposalId
                    AND Contact__c = :contactId
                    LIMIT 1
                ];
                if (apaList.isEmpty()) {
                    response.success = false;
                    response.message = 'No Applicant Proposal Association found for the given proposalId/contactId combination.';
                    return response;
                }
                apaRecord = apaList[0];

            } else {
                response.success = false;
                response.message = 'Either apaId, or both proposalId and contactId, must be provided.';
                return response;
            }

            response.declaration1 = apaRecord.Declaration_1__c;
            response.declaration2 = apaRecord.Declaration_2__c;
            response.apaId = apaRecord.Id;

            if (apaRecord.Proposal__c != null) {
                List<Proposal__c> proposalList = [
                    SELECT Id, Proposal_Status__c, Application_Date__c
                    FROM Proposal__c
                    WHERE Id = :apaRecord.Proposal__c
                    LIMIT 1
                ];
                if (!proposalList.isEmpty()) {
                    response.proposalId = proposalList[0].Id;
                    response.proposalStatus = proposalList[0].Proposal_Status__c;
                    response.applicationDate = proposalList[0].Application_Date__c;
                }
            }

            // ---- Host Contact details ----
            // Priority 1: contacts already saved as Proposal_Participant_Association__c for this proposal
            // Priority 2 (fallback): all contacts under the Host Account(s) linked via Applicant_Host_Association__c
            List<HostContactWrapper> hostContactDetails = new List<HostContactWrapper>();
            Boolean hostContactsSourcedFromParticipants = false;

            // ---- Resolved Host Account (the one new participants get auto-tagged to) ----
            // Mirrors the "first AHA found, ordered by CreatedDate" resolution used in
            // SaveProposalDeclarationAPI, so the UI can show/confirm the same Host.
            Id hostAccountId;
            String hostAccountName;

            if (apaRecord.Proposal__c != null) {

                List<Applicant_Host_Association__c> ahaList = [
                    SELECT Id, Host__c, Host__r.Name
                    FROM Applicant_Host_Association__c
                    WHERE Proposal__c = :apaRecord.Proposal__c
                    AND Host__c != null
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
                if (!ahaList.isEmpty()) {
                    hostAccountId = ahaList[0].Host__c;
                    hostAccountName = ahaList[0].Host__r.Name;
                }

                List<Proposal_Participant_Association__c> ppaList = [
                    SELECT Id, Participant__c, Roles__c
                    FROM Proposal_Participant_Association__c
                    WHERE Proposal__c = :apaRecord.Proposal__c
                    AND Participant__c != null
                ];

                Set<Id> contactIdsToQuery = new Set<Id>();
                Map<Id, String> contactIdToRole = new Map<Id, String>();

                if (!ppaList.isEmpty()) {
                    hostContactsSourcedFromParticipants = true;
                    for (Proposal_Participant_Association__c ppa : ppaList) {
                        contactIdsToQuery.add(ppa.Participant__c);
                        contactIdToRole.put(ppa.Participant__c, ppa.Roles__c);
                    }
                } else if (hostAccountId != null) {
                    List<Contact> hostAccountContacts = [
                        SELECT Id FROM Contact WHERE AccountId = :hostAccountId
                    ];
                    for (Contact con : hostAccountContacts) {
                        contactIdsToQuery.add(con.Id);
                    }
                }

                if (!contactIdsToQuery.isEmpty()) {
                    List<Contact> contacts = [
                        SELECT Id, Name, Salutation, FirstName, MiddleName, LastName, Suffix, Account.Name,
                               AccountId, Email, Birthdate, Department, Gender__c, Nationality__c,
                               MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                               OwnerId, CreatedById, LastModifiedById, CurrencyIsoCode
                        FROM Contact
                        WHERE Id IN :contactIdsToQuery
                    ];

                    for (Contact con : contacts) {
                        HostContactWrapper hostWrapper = new HostContactWrapper();
                        hostWrapper.contactId = con.Id;
                        hostWrapper.name = con.Name;
                        hostWrapper.salutation = con.Salutation;
                        hostWrapper.firstName = con.FirstName;
                        hostWrapper.middleName = con.MiddleName;
                        hostWrapper.lastName = con.LastName;
                        hostWrapper.suffix = con.Suffix;
                        hostWrapper.accountId = con.AccountId;
                        hostWrapper.accountName = con.Account.Name;
                        hostWrapper.email = con.Email;
                        hostWrapper.birthdate = con.Birthdate;
                        hostWrapper.department = con.Department;
                        hostWrapper.gender = con.Gender__c;
                        hostWrapper.nationality = con.Nationality__c;
                        hostWrapper.mailingStreet = con.MailingStreet;
                        hostWrapper.mailingCity = con.MailingCity;
                        hostWrapper.mailingState = con.MailingState;
                        hostWrapper.mailingPostalCode = con.MailingPostalCode;
                        hostWrapper.mailingCountry = con.MailingCountry;
                        hostWrapper.currencyPicklist = con.CurrencyIsoCode;
                        hostWrapper.role = contactIdToRole.get(con.Id);
                        hostContactDetails.add(hostWrapper);
                    }
                }
            }

            response.hostAccountId = hostAccountId;
            response.hostAccountName = hostAccountName;
            response.hostContactDetails = hostContactDetails;
            response.hostContactsSourcedFromParticipants = hostContactsSourcedFromParticipants;

            response.success = true;
            response.message = 'Declaration and proposal details retrieved successfully.';

        } catch (Exception ex) {
            response.success = false;
            response.message = 'Error retrieving declaration: ' + ex.getMessage();
        }

        return response;
    }

    global class GetDeclarationResponseWrapper {
        global Boolean success;
        global String message;
        global String apaId;
        global String proposalId;
        global Boolean declaration1;
        global Boolean declaration2;
        global String proposalStatus;
        global Date applicationDate;
        global Id hostAccountId;
        global String hostAccountName;
        global List<HostContactWrapper> hostContactDetails;
        global Boolean hostContactsSourcedFromParticipants;
    }

    global class HostContactWrapper {
        global Id contactId;
        global String name;
        global String salutation;
        global String firstName;
        global String middleName;
        global String lastName;
        global String suffix;
        global Id accountId;
        global String accountName;
        global String email;
        global Date birthdate;
        global String department;
        global String gender;
        global String nationality;
        global String mailingStreet;
        global String mailingCity;
        global String mailingState;
        global String mailingPostalCode;
        global String mailingCountry;
        global String currencyPicklist;
        global String role;
    }
}