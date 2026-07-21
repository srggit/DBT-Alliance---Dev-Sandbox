/**
 * @description
 * POST REST API to create OR update a Proposal, together with its:
 *   - Applicant_Proposal_Association__c (the Applicant tied to the Proposal)
 *   - Applicant_Host_Association__c     (0..N Hosts for that Proposal/Applicant)
 *   - Proposal_Participant_Association__c (0..N Participants for that Proposal)
 * all in a single request / single transaction.
 *
 * The Proposal's RecordTypeId is NOT passed in directly. Instead it is
 * derived from "yearlySchemeId":
 *   Yearly_Schemes__c.Scheme_Items__c (lookup) --> Scheme_Items__c.Name
 *   --> mapped to a Proposal__c Record Type Developer Name (see
 *       SCHEME_ITEM_TO_RECORD_TYPE below) --> resolved to the actual
 *       RecordTypeId at runtime via Schema describe (so this works across
 *       sandboxes/orgs without hardcoded 15/18-char Ids).
 *
 * NOTE: Assumes the "Scheme Items" object's API name is Scheme_Items__c.
 * Update SCHEME_ITEMS_OBJECT references below if the actual API name differs.
 *
 * Endpoint:
 *   POST /services/apexrest/proposalDetails
 *
 * CREATE vs UPDATE:
 *   - Pass no "proposalId" (or blank) -> creates a new Proposal__c.
 *   - Pass an existing "proposalId" -> updates that Proposal__c.
 *   - Same pattern applies per-record for applicantProposalAssociationId,
 *     hostAssociationId (inside each host), and participantAssociationId
 *     (inside each participant) -> if provided, that specific record is
 *     updated; if blank, a new one is created.
 *
 * Sample Request Body:
 * {
 *   "proposalId": "a0Y...",                 // omit/blank to create a new Proposal
 *   "yearlySchemeId": "a0W...",
 *   "contactId": "003...",
 *   "applicantProposalAssociationId": "a0Z...", // omit/blank to create new
 *   "proposalInBasicBiomedicalResearch": true,
 *   "hosts": [
 *     {
 *       "hostAssociationId": "a0X...",      // omit/blank to create new
 *       "hostAccountId": "001...",
 *       "isNonProfit": "Yes",
 *     //  "roles": "Mentor"
 *     }
 *   ],
 *   "participants": [
 *     {
 *       "participantAssociationId": "a0V...", // omit/blank to create new
 *       "participantContactId": "003...",
 *       "roles": "Mentor"
 *     }
 *   ]
 * }
 *
 * Sample Response Body:
 * {
 *   "success": true,
 *   "message": "Proposal created successfully.",
 *   "proposalId": "a0Y...",
 *   "applicantProposalAssociationId": "a0Z...",
 *   "proposalInBasicBiomedicalResearch": true,
 *   "hostAssociationIds": ["a0X...", "a0X..."],
 *   "participantAssociationIds": ["a0V..."]
 * }
 */
@RestResource(urlMapping='/proposalDetails')
global without sharing class ProposalDetailsAPI {

    // Scheme Item Name -> Proposal__c Record Type Developer Name
    private static final Map<String, String> SCHEME_ITEM_TO_RECORD_TYPE = new Map<String, String>{
        'Career Development Grants [CDG]' => 'Career_Development_Grants_CDG',
        'Catalytic Collaborative Grants [CCG]' => 'Catalytic_Collaborative_Grants_CCG',
        'Clinical and Public Health Early Career Research Fellowship – [CPHE]' => 'Clinical_and_Public_Health_Early_Career_Research_Fellowship_CPHE',
        'Clinical and Public Health Intermediate Research Fellowship - [CPHI]' => 'Clinical_and_Public_Health_Intermediate_Research_Fellowship_CPHI',
        'Early Career Fellowship - Basic [ECF]' => 'Early_Career_Fellowship_Basic_ECF',
        'Intermediate Fellowship - Basic' => 'Intermediate_Fellowship_Basic',
        'Multi-institutional Collaborative Grants [MCG]' => 'Multi_institutional_Collaborative_Grants_MCG',
        'RM Fellowships [RMF]' => 'RM_Fellowships_RMF',
        'RM Grants [RMG]' => 'RM_Grants_RMG',
        'RM Travel Bursaries [RMTB]' => 'RM_Travel_Bursaries_RMTB'
    };

    @HttpPost
    global static ResponseWrapper saveProposalDetails() {

        ResponseWrapper response = new ResponseWrapper();
        Savepoint sp = Database.setSavepoint();

        try {
            String requestBody = RestContext.request.requestBody.toString();
            RequestWrapper req = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);

            if (String.isBlank(req.contactId)) {
                response.success = false;
                response.message = 'Missing required field: contactId.';
                return response;
            }

            if (String.isBlank(req.yearlySchemeId)) {
                response.success = false;
                response.message = 'Missing required field: yearlySchemeId.';
                return response;
            }

            // Resolve the Proposal Record Type from the Yearly Scheme's Scheme Item
            Id resolvedRecordTypeId = resolveRecordTypeId(req.yearlySchemeId);

            // 1. Create/Update Proposal__c
            Proposal__c proposal = new Proposal__c();
            if (String.isNotBlank(req.proposalId)) {
                proposal.Id = req.proposalId;
            }
            proposal.RecordTypeId = resolvedRecordTypeId;
            proposal.Yearly_Scheme__c = req.yearlySchemeId;  
            proposal.Proposal_In_Basic_Biomedical_Research__c = req.proposalInBasicBiomedicalResearch == null ? false : req.proposalInBasicBiomedicalResearch;         
            upsert proposal;

            // 2. Create/Update Applicant_Proposal_Association__c
            Applicant_Proposal_Association__c apa = new Applicant_Proposal_Association__c();
            if (String.isNotBlank(req.applicantProposalAssociationId)) {
                apa.Id = req.applicantProposalAssociationId;
            }
            apa.Contact__c = req.contactId;
            apa.Proposal__c = proposal.Id;
            apa.Is_Coordinator__c = true;
            apa.Yearly_Scheme__c = req.yearlySchemeId;
            upsert apa;

            // 3. Create/Update Applicant_Host_Association__c records
            List<Id> hostAssociationIds = new List<Id>();
            if (req.hosts != null && !req.hosts.isEmpty()) {
                List<Applicant_Host_Association__c> hostRecords = new List<Applicant_Host_Association__c>();
                for (HostInput h : req.hosts) {
                    if (String.isBlank(h.hostAccountId)) {
                        continue; // skip incomplete entries
                    }
                    Applicant_Host_Association__c aha = new Applicant_Host_Association__c();
                    if (String.isNotBlank(h.hostAssociationId)) {
                        aha.Id = h.hostAssociationId;
                    }
                    aha.Applicant__c = req.contactId;
                    aha.Host__c = h.hostAccountId;
                    aha.Proposal__c = proposal.Id;
                    aha.Is_the_Host_Instituition_not_for_profit__c = h.isNonProfit;
                    //aha.Roles__c = h.roles;
                    hostRecords.add(aha);
                }
                if (!hostRecords.isEmpty()) {
                    upsert hostRecords;
                    for (Applicant_Host_Association__c r : hostRecords) {
                        hostAssociationIds.add(r.Id);
                    }
                }
            }

            // 4. Create/Update Proposal_Participant_Association__c records
            List<Id> participantAssociationIds = new List<Id>();
            if (req.participants != null && !req.participants.isEmpty()) {
                List<Proposal_Participant_Association__c> participantRecords = new List<Proposal_Participant_Association__c>();
                for (ParticipantInput p : req.participants) {
                    if (String.isBlank(p.participantContactId)) {
                        continue; // skip incomplete entries
                    }
                    Proposal_Participant_Association__c ppa = new Proposal_Participant_Association__c();
                    if (String.isNotBlank(p.participantAssociationId)) {
                        ppa.Id = p.participantAssociationId;
                    }
                    ppa.Participant__c = p.participantContactId;
                    ppa.Proposal__c = proposal.Id;
                    ppa.Roles__c = p.roles;
                    participantRecords.add(ppa);
                }
                if (!participantRecords.isEmpty()) {
                    upsert participantRecords;
                    for (Proposal_Participant_Association__c r : participantRecords) {
                        participantAssociationIds.add(r.Id);
                    }
                }
            }

            response.success = true;
            response.message = String.isNotBlank(req.proposalId)
                ? 'Proposal updated successfully.'
                : 'Proposal created successfully.';
            response.proposalId = proposal.Id;
            response.applicantProposalAssociationId = apa.Id;
            response.hostAssociationIds = hostAssociationIds;
            response.participantAssociationIds = participantAssociationIds;
            
            // --------------- BLOCK TO UPDATE THE SECTION UPDATE --------------- //
            if (String.isNotBlank(req.sectionName) && String.isNotBlank(req.applicantProposalAssociationId)) { 
                List<Scheme_Section__c> schemeSectionList = [
                    SELECT Id, Name, Applicant_Proposal_Association__c, Data_Filled_Successfully__c, Section_Name__c
                    FROM Scheme_Section__c
                    WHERE Applicant_Proposal_Association__c = :req.applicantProposalAssociationId
                    AND Section_Name__c = :req.sectionName
                ];

                if (!schemeSectionList.isEmpty()) {
                    schemeSectionList[0].Data_Filled_Successfully__c = true;
                    update schemeSectionList;

                    response.sectionId = schemeSectionList[0].Id;
                    response.sectionUpdateResult = true;
                } 
                else {
                    response.sectionUpdateResult = false;
                }
            }

        } catch (Exception ex) {
            Database.rollback(sp);
            response.success = false;
            response.message = 'An error occurred while saving proposal details: ' + ex.getMessage();
        }

        return response;
    }

    /**
     * Resolves the Proposal__c RecordTypeId from a Yearly Scheme:
     *   Yearly_Schemes__c -> Scheme_Items__c (lookup) -> Scheme_Items__c.Name
     *   -> SCHEME_ITEM_TO_RECORD_TYPE map -> Schema describe -> RecordTypeId
     */
    private static Id resolveRecordTypeId(String yearlySchemeId) {

        List<Yearly_Schemes__c> schemes = [
            SELECT Id, Scheme_Items__c
            FROM Yearly_Schemes__c
            WHERE Id = :yearlySchemeId
            LIMIT 1
        ];

        if (schemes.isEmpty()) {
            throw new ProposalDetailsException('Yearly Scheme not found for Id: ' + yearlySchemeId);
        }

        Yearly_Schemes__c scheme = schemes[0];
        if (scheme.Scheme_Items__c == null) {
            throw new ProposalDetailsException('Yearly Scheme has no Scheme Item linked: ' + yearlySchemeId);
        }

        List<Scheme_Items__c> schemeItems = [
            SELECT Id, Name
            FROM Scheme_Items__c
            WHERE Id = :scheme.Scheme_Items__c
            LIMIT 1
        ];

        if (schemeItems.isEmpty()) {
            throw new ProposalDetailsException('Scheme Item not found for Id: ' + scheme.Scheme_Items__c);
        }

        String schemeItemName = schemeItems[0].Name;
        String recordTypeDevName = SCHEME_ITEM_TO_RECORD_TYPE.get(schemeItemName);

        if (String.isBlank(recordTypeDevName)) {
            throw new ProposalDetailsException('No Record Type mapping found for Scheme Item: ' + schemeItemName);
        }

        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Proposal__c
            .getRecordTypeInfosByDeveloperName()
            .get(recordTypeDevName);

        if (rtInfo == null) {
            throw new ProposalDetailsException('Proposal Record Type not found for developer name: ' + recordTypeDevName);
        }

        return rtInfo.getRecordTypeId();
    }

    // ---------- Custom Exception ----------

    global class ProposalDetailsException extends Exception {}

    // ---------- Request Wrappers ----------

    global class RequestWrapper {
        public String proposalId;
        public String yearlySchemeId;
        public String contactId;
        public String applicantProposalAssociationId;
        public Boolean proposalInBasicBiomedicalResearch;
        public List<HostInput> hosts;
        public List<ParticipantInput> participants;
        public String sectionName;
    }

    global class HostInput {
        public String hostAssociationId;
        public String hostAccountId;
        public String isNonProfit;
      //  public String roles;
    }

    global class ParticipantInput {
        public String participantAssociationId;
        public String participantContactId;
        public String roles;
    }

    // ---------- Response Wrapper ----------

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public String proposalId;
        public String applicantProposalAssociationId;
        public List<Id> hostAssociationIds;
        public List<Id> participantAssociationIds;
        public Boolean sectionUpdateResult;
        public String sectionId;
    }
}