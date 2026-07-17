/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : YearlySchemeTriggerHandler
 * Author          : <YourName>
 * Created Date    : Jul 1, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Jul 1, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jul 1, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class YearlySchemeTriggerHandler {

    public static void validateDuplicateYearScheme(List<Yearly_Schemes__c> newRecords) {

        Set<Id> yearIds = new Set<Id>();
        Set<Id> schemeIds = new Set<Id>();

        for (Yearly_Schemes__c ys : newRecords) {
            if (ys.Year__c != null) {
                yearIds.add(ys.Year__c);
            }
            if (ys.Scheme_Items__c != null) {
                schemeIds.add(ys.Scheme_Items__c);
            }
        }
        if (yearIds.isEmpty() || schemeIds.isEmpty()) {
            return;
        }

        List<Yearly_Schemes__c> existingRecords = [SELECT Id, Year__c, Scheme_Items__c FROM Yearly_Schemes__c 
													WHERE Year__c IN :yearIds AND Scheme_Items__c IN :schemeIds];

        Map<String, Id> existingMap = new Map<String, Id>();
        for (Yearly_Schemes__c record : existingRecords) {
            String key = record.Year__c + '-' + record.Scheme_Items__c;
            existingMap.put(key, record.Id);
        }

        Set<String> currentBatchKeys = new Set<String>();
        for (Yearly_Schemes__c ys : newRecords) {
            if (ys.Year__c == null || ys.Scheme_Items__c == null) {
                continue;
            }
            String key = ys.Year__c + '-' + ys.Scheme_Items__c;
            // Check duplicate within the same transaction
            if (currentBatchKeys.contains(key)) {
                ys.addError('A Yearly Scheme already exists for the selected Year and Scheme.');
                continue;
            }
            currentBatchKeys.add(key);
            // Check duplicate against existing records
            if (existingMap.containsKey(key) && existingMap.get(key) != ys.Id) {
                ys.addError('A Yearly Scheme already exists for the selected Year and Scheme.');
            }
        }
    }

    public static void updateProposalIds(Map<Id, Yearly_Schemes__c> newMap, Map<Id, Yearly_Schemes__c> oldMap){

        Set<Id> yearlySchemeIds = new Set<Id>();

        for(Id ysId : newMap.keySet()){

            Yearly_Schemes__c newRec = newMap.get(ysId);
            Yearly_Schemes__c oldRec = oldMap.get(ysId);

            if (
                newRec.Is_Active__c && oldRec.Is_Active__c &&
                newRec.Approval_Status__c == 'Approved' && oldRec.Approval_Status__c == 'Approved' &&
                oldRec.Application_Stages__c == 'Prelims' && newRec.Application_Stages__c == 'Full') {

                yearlySchemeIds.add(ysId);
            }
        }

        if(yearlySchemeIds.isEmpty()){
            return;
        }

        ProposalTriggerHandler.updateProposalIdsToFull(yearlySchemeIds);

    }
}