public with sharing class ReviewerController {
    /**
     * Lightweight data object used to return a reviewer together with
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
     * Returns all reviewers together with keyword-match metadata based on
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

        // Identify reviewers already mapped to this proposal.
        Set<Id> mappedReviewerIds = new Set<Id>();
        if (proposalId != null) {
            for (Reviewer_Mapping__c existing : [
                SELECT Reviewer__c
                FROM Reviewer_Mapping__c
                WHERE Proposal__c = :proposalId
            ]) {
                mappedReviewerIds.add(existing.Reviewer__c);
            }
        }

        // Query all reviewers and their related keyword records.
        List<Reviewer__c> reviewerRecords = [
            SELECT
                Id, Title__c, First_Name__c, Last_Name__c, Mobile_Number__c, Alternate_Phone_Number__c,
                Designation__c, Department__c, Country__c, State_Province__c, City__c, Organisation__c,
                Email_Address__c, Reviewer_Type__c,
                (SELECT Keyword_Name__c FROM Keywords__r)
            FROM Reviewer__c
            LIMIT 1000
        ];

        // Score each reviewer and build a result for every reviewer.
        List<ReviewerResult> results = new List<ReviewerResult>();
        for (Reviewer__c reviewer : reviewerRecords) {
            Set<String> matchedKeywordNames = new Set<String>();

            // A proposal keyword matches when it is a substring of a reviewer keyword.
            // Comparison is case-insensitive.
            List<SObject> keywordRecords = reviewer.getSObjects('Keywords__r');
            if (keywordRecords != null) {
                for (SObject keywordRecord : keywordRecords) {
                    String keywordName = (String) keywordRecord.get('Keyword_Name__c');
                    if (String.isBlank(keywordName)) {
                        continue;
                    }
                    String reviewerKeyword = keywordName.toLowerCase();

                    for (String proposalKeyword : proposalKeywords) {
                        if (reviewerKeyword.contains(proposalKeyword)) {
                            matchedKeywordNames.add(keywordName);
                        }
                    }
                }
            }

            ReviewerResult result = new ReviewerResult();
            result.Id = reviewer.Id;
            result.Name = buildReviewerName(reviewer.First_Name__c, reviewer.Last_Name__c);
            result.Email = reviewer.Email_Address__c;
            result.Phone = reviewer.Mobile_Number__c;
            result.reviewerType = reviewer.Reviewer_Type__c;
            result.qualifyingDegree = '';
            result.isAlreadyMapped = mappedReviewerIds.contains(reviewer.Id);
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
    public static void createReviewerMappings(Id proposalId, List<Id> reviewerIds) {
        if (proposalId == null || reviewerIds == null || reviewerIds.isEmpty()) {
            throw new AuraHandledException('Proposal and at least one reviewer are required.');
        }

        Set<Id> uniqueReviewerIds = new Set<Id>(reviewerIds);

        Set<Id> existingReviewerIds = new Set<Id>();
        for (Reviewer_Mapping__c existing : [
            SELECT Reviewer__c
            FROM Reviewer_Mapping__c
            WHERE Proposal__c = :proposalId AND Reviewer__c IN :uniqueReviewerIds
        ]) {
            existingReviewerIds.add(existing.Reviewer__c);
        }

        List<Reviewer_Mapping__c> mappingsToInsert = new List<Reviewer_Mapping__c>();
        for (Id reviewerId : uniqueReviewerIds) {
            if (!existingReviewerIds.contains(reviewerId)) {
                mappingsToInsert.add(
                    new Reviewer_Mapping__c(Proposal__c = proposalId, Reviewer__c = reviewerId)
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

    /**
     * Builds a full name from first and last name parts, trimming blank values.
     */
    private static String buildReviewerName(String firstName, String lastName) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(firstName)) {
            parts.add(firstName.trim());
        }
        if (String.isNotBlank(lastName)) {
            parts.add(lastName.trim());
        }
        return String.join(parts, ' ');
    }
}