@IsTest
private class AssignGrantsMembersForYearlySchemeTest {

    @IsTest
    static void getGrantsManagerUsers_returnsList() {
        Test.startTest();
        List<AssignGrantsMembersForYearlyScheme.GrantsManagerUser> users =
            AssignGrantsMembersForYearlyScheme.getGrantsManagerUsers();
        Test.stopTest();

        System.assertNotEquals(null, users, 'Expected a non-null user list.');
    }

    @IsTest
    static void addGrantsTeamMembers_requiresSelection() {
        Yearly_Schemes__c yearlyScheme = new Yearly_Schemes__c();
        insert yearlyScheme;

        Boolean exceptionThrown = false;
        try {
            AssignGrantsMembersForYearlyScheme.addGrantsTeamMembers(
                yearlyScheme.Id,
                new List<Id>()
            );
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'Expected error when no users are selected.');
    }

    @IsTest
    static void addGrantsTeamMembers_requiresYearlySchemeId() {
        Boolean exceptionThrown = false;
        try {
            AssignGrantsMembersForYearlyScheme.addGrantsTeamMembers(
                null,
                new List<Id>{ UserInfo.getUserId() }
            );
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'Expected error when Yearly Scheme Id is missing.');
    }

    @IsTest
    static void addGrantsTeamMembers_createsRecordsWhenRoleMatches() {
        Yearly_Schemes__c yearlyScheme = new Yearly_Schemes__c();
        insert yearlyScheme;

        List<User> grantsManagers = [
            SELECT Id, Name
            FROM User
            WHERE UserRole.Name = 'Grants Manager'
            AND IsActive = TRUE
            LIMIT 1
        ];

        if (grantsManagers.isEmpty()) {
            return;
        }

        Test.startTest();
        Integer createdCount = AssignGrantsMembersForYearlyScheme.addGrantsTeamMembers(
            yearlyScheme.Id,
            new List<Id>{ grantsManagers[0].Id }
        );
        Test.stopTest();

        System.assertEquals(1, createdCount, 'Expected one team member to be created.');

        List<Grants_Team_Members__c> members = [
            SELECT Id, Name, Yearly_Scheme__c, OwnerId
            FROM Grants_Team_Members__c
            WHERE Yearly_Scheme__c = :yearlyScheme.Id
        ];
        System.assertEquals(1, members.size(), 'Expected one Grants_Team_Members__c record.');
        System.assertEquals(grantsManagers[0].Id, members[0].OwnerId);
        System.assertEquals(grantsManagers[0].Name, members[0].Name);
    }
}