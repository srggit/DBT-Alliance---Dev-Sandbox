public with sharing class AssignGrantsMembersForYearlyScheme {

    private static final String GRANTS_MANAGER_ROLE = 'Grants Manager';

    @AuraEnabled(cacheable=true)
    public static List<GrantsManagerUser> getGrantsManagerUsers(Id yearlySchemeId) {
        Set<Id> existingUserIds = getExistingMemberUserIds(yearlySchemeId);
        List<GrantsManagerUser> results = new List<GrantsManagerUser>();

        for (User grantsManager : [
            SELECT Id, Name, Email, Username, UserRole.Name, IsActive
            FROM User
            WHERE UserRole.Name = :GRANTS_MANAGER_ROLE
            AND IsActive = TRUE
            ORDER BY Name
        ]) {
            results.add(new GrantsManagerUser(
                grantsManager,
                existingUserIds.contains(grantsManager.Id)
            ));
        }

        return results;
    }

    @AuraEnabled
    public static Integer addGrantsTeamMembers(Id yearlySchemeId, List<Id> userIds) {
        if (yearlySchemeId == null) {
            throw new AuraHandledException('Yearly Scheme record Id is required.');
        }
        if (userIds == null || userIds.isEmpty()) {
            throw new AuraHandledException('Select at least one Grants Manager.');
        }

        Set<Id> selectedUserIds = new Set<Id>(userIds);
        Set<Id> existingUserIds = getExistingMemberUserIds(yearlySchemeId);

        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, Name
            FROM User
            WHERE Id IN :selectedUserIds
            AND IsActive = TRUE
            AND UserRole.Name = :GRANTS_MANAGER_ROLE
        ]);

        List<Grants_Team_Members__c> membersToInsert = new List<Grants_Team_Members__c>();
        for (Id userId : selectedUserIds) {
            if (existingUserIds.contains(userId) || !usersById.containsKey(userId)) {
                continue;
            }

            membersToInsert.add(new Grants_Team_Members__c(
                Name = usersById.get(userId).Name,
                Yearly_Scheme__c = yearlySchemeId,
                User__c = userId
            ));
        }

        if (membersToInsert.isEmpty()) {
            throw new AuraHandledException('No new Grants Managers to add. Selected users may already be team members.');
        }

        insert membersToInsert;
        return membersToInsert.size();
    }

    private static Set<Id> getExistingMemberUserIds(Id yearlySchemeId) {
        Set<Id> existingUserIds = new Set<Id>();
        if (yearlySchemeId == null) {
            return existingUserIds;
        }

        for (Grants_Team_Members__c existingMember : [
            SELECT User__c
            FROM Grants_Team_Members__c
            WHERE Yearly_Scheme__c = :yearlySchemeId
            AND User__c != NULL
        ]) {
            existingUserIds.add(existingMember.User__c);
        }

        return existingUserIds;
    }

    public class GrantsManagerUser {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String username;
        @AuraEnabled public String role;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean isAlreadyAdded;

        public GrantsManagerUser(User grantsManager, Boolean isAlreadyAdded) {
            this.id = grantsManager.Id;
            this.name = grantsManager.Name;
            this.email = grantsManager.Email;
            this.username = grantsManager.Username;
            this.role = grantsManager.UserRole.Name;
            this.isActive = grantsManager.IsActive;
            this.isAlreadyAdded = isAlreadyAdded;
        }
    }
}