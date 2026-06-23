@isTest
public class IndiaAllianceCustomerPortalSelf_Test {
    public static testmethod void sampleTest(){
        List<User> acc= new List<User>();
        Country__c co = new Country__c(Active__c = true, Country_Code__c = 'IN' , Display__c = true);
        insert co;
        
        Account a = new Account(
            Name = 't',
            Department__c = 'd',
            Address__c = 'Address__c',
            City__c = 'City__c',
            Country__c = co.Id,
            Pincode__c = 54545454,
            Institution_Categories__c = 'Other'
        );
        a.Name='MasthanVali';
        insert a;
      
        ID adminProfileID = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].ID;
        user u= new user();
        u.FirstName='abhishek';
        u.Date_of_Birth__c=system.today();
        u.Nationality__c='India';
        u.Expertise__c='ans';
        u.Position__c='sales';
        u.Department__c='item';
        u.Gender__c='male';
        u.Organisation__c='hs';
        u.Address__c='hds';
        u.City__c='bundi';
        u.Countries__c='india';
        u.Postal_Code__c='560030';
        u.International_Dialing_Code__c=90.39;
        u.Phone='9933832822';
        u.Alias = 'firstusr';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.Username='saket.sharma48d@gmail.com   ';
        u.LastName='sharma';
        u.Email='masthanvali.n@appistoki.com    ';
        // u.ContactId = c.Id;
        u.ProfileId =adminProfileID;
        insert u;
        IndiaAllianceCustomerPortalSelfRegister ia= new IndiaAllianceCustomerPortalSelfRegister();
        ia.handleUnsetRequiredFields(u);
        ia.generateRandomPassword();
        ia.addMissingPasswordRequirements('22',true,true,true,true);
        ia.generateRandomInt(8);
        ia.generateContact(u,a.id);
        ia.generateAlias();
        ia.generateLastName();
        ia.generateUsername();
        ia.generateEmail();
        ia.generateCommunityNickname();
        Map<SObjectField, String> registrationAttributes = new Map<SObjectField, String>();
        // Site.validatePassword(u, '2', '44');
       // site.createExternalUser(u, a.id, '53');
        ia.createUser(a.id,adminProfileID,registrationAttributes,'2');
    }
}