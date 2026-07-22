public with sharing class ReviewerController {
    /**
     * Lightweight data object used to return a reviewer contact together with
     * keyword-match metadata for display and sorting in the Lightning web component.
     */
    public class ReviewerResult implements Comparable {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Email;
        @AuraEnabled public String Phone;
        @AuraEnabled public String reviewerType;
        @AuraEnabled public String qualifyingDegree;
        @AuraEnabled public Integer matchCount;
        @AuraEnabled public String matchedKeywords;
        @AuraEnabled public Boolean isAlreadyMapped;

        /**
         * Sort unmapped reviewers first, then descending by match count, then ascending by name.
         */
        public Integer compareTo(Object obj) {
            ReviewerResult other = (ReviewerResult) obj;
            if (this.isAlreadyMapped != other.isAlreadyMapped) {
                return this.isAlreadyMapped ? 1 : -1;
            }
            if (this.matchCount > other.matchCount) {
                return -1;
            }
            if (this.matchCount < other.matchCount) {
                return 1;
            }
            return this.Name.compareTo(other.Name);
        }
    }

    /**
     * Returns all reviewer contacts together with keyword-match metadata based on
     * the proposal's comma-separated keywords (case-insensitive). Results are ranked
     * by how many proposal keywords they match; unmatched reviewers still appear
     * with a match count of 0 and an empty matched-keywords value.
     *
     * @param proposalId The Id of the proposal whose Keywords__c field drives the match.
     */
    @AuraEnabled(cacheable=true)
    public static List<ReviewerResult> getReviewerContacts(Id proposalId) {
        // Build the normalized list of proposal keywords from the proposal record.
        List<String> proposalKeywords = getProposalKeywords(proposalId);
        Boolean hasProposalKeywords = !proposalKeywords.isEmpty();

        // Identify reviewer contacts already mapped to this proposal.
        Set<Id> mappedContactIds = new Set<Id>();
        if (proposalId != null) {
            for (Reviewer_Mapping__c existing : [
                SELECT Contact__c
                FROM Reviewer_Mapping__c
                WHERE Proposal__c = :proposalId
            ]) {
                mappedContactIds.add(existing.Contact__c);
            }
        }

        // Query all reviewer contacts and their related keyword records.
        List<Contact> reviewerContacts = [
            SELECT
                Id,
                Name,
                Email,
                Phone,
                ReviewerType__c,
                Qualifying_Degree__c,
                (SELECT Keyword_Name__c FROM Keywords__r)
            FROM Contact
            WHERE RecordType.Name = 'Reviewer'
            ORDER BY Name
            LIMIT 1000
        ];

        // Score each contact and build a result for every reviewer.
        List<ReviewerResult> results = new List<ReviewerResult>();
        for (Contact reviewer : reviewerContacts) {
            Set<String> matchedKeywordNames = new Set<String>();

            // A proposal keyword matches when it is a substring of a contact keyword.
            // Comparison is case-insensitive.
            List<SObject> keywordRecords = reviewer.getSObjects('Keywords__r');
            if (keywordRecords != null) {
                for (SObject keywordRecord : keywordRecords) {
                    String keywordName = (String) keywordRecord.get('Keyword_Name__c');
                    if (String.isBlank(keywordName)) {
                        continue;
                    }
                    String contactKeyword = keywordName.toLowerCase();

                    for (String proposalKeyword : proposalKeywords) {
                        if (contactKeyword.contains(proposalKeyword)) {
                            matchedKeywordNames.add(keywordName);
                        }
                    }
                }
            }

            ReviewerResult result = new ReviewerResult();
            result.Id = reviewer.Id;
            result.Name = reviewer.Name;
            result.Email = reviewer.Email;
            result.Phone = reviewer.Phone;
            result.reviewerType = reviewer.ReviewerType__c;
            result.qualifyingDegree = reviewer.Qualifying_Degree__c;
            result.isAlreadyMapped = mappedContactIds.contains(reviewer.Id);
            result.matchCount = matchedKeywordNames.size();
            // Produce a deterministic, comma-separated list of matched keywords for display.
            List<String> matchedList = new List<String>(matchedKeywordNames);
            matchedList.sort();
            result.matchedKeywords = String.join(matchedList, ', ');

            // Include all keyword-matched reviewers. Already-mapped reviewers are shown in the
            // component with disabled checkboxes so they cannot be re-selected.
            Boolean hasMatches = !matchedKeywordNames.isEmpty();
            if (hasMatches || !hasProposalKeywords) {
                results.add(result);
            }
        }

        // Rank results by number of matched keywords, then alphabetically by name.
        results.sort();
        return results;
    }

    /**
     * Reads the proposal's Keywords__c field and returns a list of trimmed,
     * lower-cased keywords suitable for case-insensitive matching.
     */
    private static List<String> getProposalKeywords(Id proposalId) {
        List<String> keywords = new List<String>();

        if (proposalId == null) {
            return keywords;
        }

        List<Proposal__c> proposals = [
            SELECT Keywords__c
            FROM Proposal__c
            WHERE Id = :proposalId
            LIMIT 1
        ];

        if (proposals.isEmpty() || String.isBlank(proposals[0].Keywords__c)) {
            return keywords;
        }

        for (String keyword : proposals[0].Keywords__c.split(',')) {
            String normalized = keyword.trim().toLowerCase();
            if (String.isNotBlank(normalized)) {
                keywords.add(normalized);
            }
        }

        return keywords;
    }

    @AuraEnabled
    public static void createReviewerMappings(Id proposalId, List<Id> contactIds) {
        if (proposalId == null || contactIds == null || contactIds.isEmpty()) {
            throw new AuraHandledException('Proposal and at least one reviewer contact are required.');
        }

        Set<Id> uniqueContactIds = new Set<Id>(contactIds);

        Set<Id> existingContactIds = new Set<Id>();
        for (Reviewer_Mapping__c existing : [
            SELECT Contact__c
            FROM Reviewer_Mapping__c
            WHERE Proposal__c = :proposalId AND Contact__c IN :uniqueContactIds
        ]) {
            existingContactIds.add(existing.Contact__c);
        }

        List<Reviewer_Mapping__c> mappingsToInsert = new List<Reviewer_Mapping__c>();
        for (Id contactId : uniqueContactIds) {
            if (!existingContactIds.contains(contactId)) {
                mappingsToInsert.add(
                    new Reviewer_Mapping__c(Proposal__c = proposalId, Contact__c = contactId)
                );
            }
        }

        if (!mappingsToInsert.isEmpty()) {
            try {
                insert mappingsToInsert;
            } catch (DmlException e) {
                throw new AuraHandledException('Unable to create reviewer mappings: ' + e.getDmlMessage(0));
            }
        }
    }
}