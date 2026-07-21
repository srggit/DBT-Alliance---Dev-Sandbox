// public with sharing class FieldHistoryTrackerUtil {

//     private static Map<String, List<Tracked_Field__mdt>> configByObject;

//     public static void trackChanges(List<SObject> newRecords, Map<Id, SObject> oldMap) {
//         if (newRecords == null || newRecords.isEmpty()) return;

//         String objectApiName = newRecords[0].getSObjectType().getDescribe().getName();
//         List<Tracked_Field__mdt> configs = getConfig(objectApiName);
//         if (configs.isEmpty()) return;

//         Map<String, Schema.SObjectField> fieldMap =
//             newRecords[0].getSObjectType().getDescribe().fields.getMap();

//         // Step 1: figure out which tracked fields are Lookups, and collect every
//         // old/new Id value for those fields so we can resolve them to Names in one query per object type
//         Set<String> lookupFieldNames = new Set<String>();
//         for (Tracked_Field__mdt cfg : configs) {
//             Schema.SObjectField sf = fieldMap.get(cfg.Field_API_Name__c);
//             if (sf != null && sf.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
//                 lookupFieldNames.add(cfg.Field_API_Name__c);
//             }
//         }

//         Map<Id, String> idToName = resolveNames(newRecords, oldMap, lookupFieldNames);

//         // Step 2: group configs by target history object
//         Map<String, List<Tracked_Field__mdt>> configsByHistoryObject = new Map<String, List<Tracked_Field__mdt>>();
//         for (Tracked_Field__mdt cfg : configs) {
//             if (!configsByHistoryObject.containsKey(cfg.History_Object_API_Name__c)) {
//                 configsByHistoryObject.put(cfg.History_Object_API_Name__c, new List<Tracked_Field__mdt>());
//             }
//             configsByHistoryObject.get(cfg.History_Object_API_Name__c).add(cfg);
//         }

//         for (String historyObjectName : configsByHistoryObject.keySet()) {
//             List<SObject> historyRecordsToInsert = new List<SObject>();
//             SObjectType historyType = Schema.getGlobalDescribe().get(historyObjectName);

//             for (SObject newRec : newRecords) {
//                 SObject oldRec = oldMap.get((Id) newRec.get('Id'));
//                 if (oldRec == null) continue;

//                 for (Tracked_Field__mdt cfg : configsByHistoryObject.get(historyObjectName)) {
//                     Object oldVal = oldRec.get(cfg.Field_API_Name__c);
//                     Object newVal = newRec.get(cfg.Field_API_Name__c);

//                     if (!isSame(oldVal, newVal)) {
//                         Boolean isLookup = lookupFieldNames.contains(cfg.Field_API_Name__c);

//                         SObject historyRec = historyType.newSObject();
//                         historyRec.put('Field_Name__c', cfg.Field_API_Name__c);
//                         historyRec.put('Old_Value__c', formatValue(oldVal, isLookup, idToName));
//                         historyRec.put('New_Value__c', formatValue(newVal, isLookup, idToName));
//                         historyRec.put(cfg.Parent_Lookup_Field__c, (Id) newRec.get('Id'));
//                         historyRec.put('Changed_By__c', UserInfo.getUserId());
//                         historyRec.put('Changed_On__c', System.now());
//                         historyRecordsToInsert.add(historyRec);
//                     }
//                 }
//             }

//             if (!historyRecordsToInsert.isEmpty()) {
//                 insert historyRecordsToInsert;
//             }
//         }
//     }

//     // Bulk-resolves every Id found in lookup-tracked fields (old + new values) to its Name,
//     // grouping by actual SObjectType so it works for polymorphic fields like OwnerId (User or Group)
//     private static Map<Id, String> resolveNames(List<SObject> newRecords, Map<Id, SObject> oldMap, Set<String> lookupFieldNames) {
//         Map<Id, String> idToName = new Map<Id, String>();
//         if (lookupFieldNames.isEmpty()) return idToName;

//         Map<String, Set<Id>> idsByObjectType = new Map<String, Set<Id>>();

//         for (SObject newRec : newRecords) {
//             SObject oldRec = oldMap.get((Id) newRec.get('Id'));
//             if (oldRec == null) continue;

//             for (String fieldName : lookupFieldNames) {
//                 collectId(oldRec.get(fieldName), idsByObjectType);
//                 collectId(newRec.get(fieldName), idsByObjectType);
//             }
//         }

//         for (String typeName : idsByObjectType.keySet()) {
//             Set<Id> ids = idsByObjectType.get(typeName);
//             if (ids.isEmpty()) continue;
//             try {
//                 for (SObject rec : Database.query(
//                     'SELECT Id, Name FROM ' + typeName + ' WHERE Id IN :ids'
//                 )) {
//                     idToName.put((Id) rec.get('Id'), (String) rec.get('Name'));
//                 }
//             } catch (Exception e) {
//                 // Object has no queryable Name field (rare) — fall back to Id for that type
//                 System.debug('FieldHistoryTrackerUtil: could not resolve Name for ' + typeName + ' - ' + e.getMessage());
//             }
//         }
//         return idToName;
//     }

//     private static void collectId(Object val, Map<String, Set<Id>> idsByObjectType) {
//         if (val == null) return;
//         Id recId = (Id) val;
//         String typeName = recId.getSObjectType().getDescribe().getName();
//         if (!idsByObjectType.containsKey(typeName)) {
//             idsByObjectType.put(typeName, new Set<Id>());
//         }
//         idsByObjectType.get(typeName).add(recId);
//     }

//     private static Boolean isSame(Object oldVal, Object newVal) {
//         if (oldVal == null && newVal == null) return true;
//         if (oldVal == null || newVal == null) return false;
//         return String.valueOf(oldVal) == String.valueOf(newVal);
//     }

//     private static String formatValue(Object val, Boolean isLookup, Map<Id, String> idToName) {
//         if (val == null) return null;
//         String result;

//         if (isLookup) {
//             Id recId = (Id) val;
//             result = idToName.containsKey(recId) ? idToName.get(recId) : String.valueOf(recId);
//         } else if (val instanceof Datetime) {
//             result = ((Datetime) val).format('dd-MMM-yyyy HH:mm');
//         } else if (val instanceof Date) {
//             result = ((Date) val).format();
//         } else {
//             result = String.valueOf(val);
//         }
//         return result.length() > 255 ? result.substring(0, 255) : result;
//     }

//     private static List<Tracked_Field__mdt> getConfig(String objectApiName) {
//         if (configByObject == null) {
//             configByObject = new Map<String, List<Tracked_Field__mdt>>();
//             for (Tracked_Field__mdt cfg : [
//                 SELECT Object_API_Name__c, Field_API_Name__c,
//                        History_Object_API_Name__c, Parent_Lookup_Field__c
//                 FROM Tracked_Field__mdt
//                 WHERE Active__c = true
//             ]) {
//                 if (!configByObject.containsKey(cfg.Object_API_Name__c)) {
//                     configByObject.put(cfg.Object_API_Name__c, new List<Tracked_Field__mdt>());
//                 }
//                 configByObject.get(cfg.Object_API_Name__c).add(cfg);
//             }
//         }
//         return configByObject.containsKey(objectApiName) ? configByObject.get(objectApiName) : new List<Tracked_Field__mdt>();
//     }
// }





public with sharing class FieldHistoryTrackerUtil {

    private static Map<String, List<Tracked_Field__mdt>> configByObject;

    public static void trackChanges(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) return;

        String objectApiName = newRecords[0].getSObjectType().getDescribe().getName();
        List<Tracked_Field__mdt> configs = getConfig(objectApiName);
        if (configs.isEmpty()) return;

        Map<String, Schema.SObjectField> fieldMap =
            newRecords[0].getSObjectType().getDescribe().fields.getMap();

        // Step 1: figure out which tracked fields are Lookups, and build API name -> Label map.
        // fieldMap keys are always lowercase, so look up using the lowercased API name.
        Set<String> lookupFieldNames = new Set<String>();
        Map<String, String> fieldLabelByApiName = new Map<String, String>();

        for (Tracked_Field__mdt cfg : configs) {
            Schema.SObjectField sf = fieldMap.get(cfg.Field_API_Name__c.toLowerCase());
            if (sf != null) {
                Schema.DescribeFieldResult dfr = sf.getDescribe();
                fieldLabelByApiName.put(cfg.Field_API_Name__c, dfr.getLabel());
                if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                    lookupFieldNames.add(cfg.Field_API_Name__c);
                }
            }
        }

        Map<Id, String> idToName = resolveNames(newRecords, oldMap, lookupFieldNames);

        // Step 2: group configs by target history object
        Map<String, List<Tracked_Field__mdt>> configsByHistoryObject = new Map<String, List<Tracked_Field__mdt>>();
        for (Tracked_Field__mdt cfg : configs) {
            if (!configsByHistoryObject.containsKey(cfg.History_Object_API_Name__c)) {
                configsByHistoryObject.put(cfg.History_Object_API_Name__c, new List<Tracked_Field__mdt>());
            }
            configsByHistoryObject.get(cfg.History_Object_API_Name__c).add(cfg);
        }

        for (String historyObjectName : configsByHistoryObject.keySet()) {
            List<SObject> historyRecordsToInsert = new List<SObject>();
            SObjectType historyType = Schema.getGlobalDescribe().get(historyObjectName);

            for (SObject newRec : newRecords) {
                SObject oldRec = oldMap.get((Id) newRec.get('Id'));
                if (oldRec == null) continue;

                for (Tracked_Field__mdt cfg : configsByHistoryObject.get(historyObjectName)) {
                    Object oldVal = oldRec.get(cfg.Field_API_Name__c);
                    Object newVal = newRec.get(cfg.Field_API_Name__c);

                    if (!isSame(oldVal, newVal)) {
                        Boolean isLookup = lookupFieldNames.contains(cfg.Field_API_Name__c);

                        String fieldDisplayName = fieldLabelByApiName.containsKey(cfg.Field_API_Name__c)
                            ? fieldLabelByApiName.get(cfg.Field_API_Name__c)
                            : cfg.Field_API_Name__c; // fallback if describe lookup failed for some reason

                        SObject historyRec = historyType.newSObject();
                        historyRec.put('Field_Name__c', fieldDisplayName);
                        historyRec.put('Old_Value__c', formatValue(oldVal, isLookup, idToName));
                        historyRec.put('New_Value__c', formatValue(newVal, isLookup, idToName));
                        historyRec.put(cfg.Parent_Lookup_Field__c, (Id) newRec.get('Id'));
                        historyRec.put('Changed_By__c', UserInfo.getUserId());
                        historyRec.put('Changed_On__c', System.now());
                        historyRecordsToInsert.add(historyRec);
                    }
                }
            }

            if (!historyRecordsToInsert.isEmpty()) {
                insert historyRecordsToInsert;
            }
        }
    }

    // Bulk-resolves every Id found in lookup-tracked fields (old + new values) to its Name,
    // grouping by actual SObjectType so it works for polymorphic fields like OwnerId (User or Group)
    private static Map<Id, String> resolveNames(List<SObject> newRecords, Map<Id, SObject> oldMap, Set<String> lookupFieldNames) {
        Map<Id, String> idToName = new Map<Id, String>();
        if (lookupFieldNames.isEmpty()) return idToName;

        Map<String, Set<Id>> idsByObjectType = new Map<String, Set<Id>>();

        for (SObject newRec : newRecords) {
            SObject oldRec = oldMap.get((Id) newRec.get('Id'));
            if (oldRec == null) continue;

            for (String fieldName : lookupFieldNames) {
                collectId(oldRec.get(fieldName), idsByObjectType);
                collectId(newRec.get(fieldName), idsByObjectType);
            }
        }

        for (String typeName : idsByObjectType.keySet()) {
            Set<Id> ids = idsByObjectType.get(typeName);
            if (ids.isEmpty()) continue;
            try {
                for (SObject rec : Database.query(
                    'SELECT Id, Name FROM ' + typeName + ' WHERE Id IN :ids'
                )) {
                    idToName.put((Id) rec.get('Id'), (String) rec.get('Name'));
                }
            } catch (Exception e) {
                // Object has no queryable Name field (rare) — fall back to Id for that type
                System.debug('FieldHistoryTrackerUtil: could not resolve Name for ' + typeName + ' - ' + e.getMessage());
            }
        }
        return idToName;
    }

    private static void collectId(Object val, Map<String, Set<Id>> idsByObjectType) {
        if (val == null) return;
        Id recId = (Id) val;
        String typeName = recId.getSObjectType().getDescribe().getName();
        if (!idsByObjectType.containsKey(typeName)) {
            idsByObjectType.put(typeName, new Set<Id>());
        }
        idsByObjectType.get(typeName).add(recId);
    }

    private static Boolean isSame(Object oldVal, Object newVal) {
        if (oldVal == null && newVal == null) return true;
        if (oldVal == null || newVal == null) return false;
        return String.valueOf(oldVal) == String.valueOf(newVal);
    }

    private static String formatValue(Object val, Boolean isLookup, Map<Id, String> idToName) {
        if (val == null) return null;
        String result;

        if (isLookup) {
            Id recId = (Id) val;
            result = idToName.containsKey(recId) ? idToName.get(recId) : String.valueOf(recId);
        } else if (val instanceof Datetime) {
            result = ((Datetime) val).format('dd-MMM-yyyy HH:mm');
        } else if (val instanceof Date) {
            result = ((Date) val).format();
        } else {
            result = String.valueOf(val);
        }
        return result.length() > 255 ? result.substring(0, 255) : result;
    }

    private static List<Tracked_Field__mdt> getConfig(String objectApiName) {
        if (configByObject == null) {
            configByObject = new Map<String, List<Tracked_Field__mdt>>();
            for (Tracked_Field__mdt cfg : [
                SELECT Object_API_Name__c, Field_API_Name__c,
                       History_Object_API_Name__c, Parent_Lookup_Field__c
                FROM Tracked_Field__mdt
                WHERE Active__c = true
            ]) {
                if (!configByObject.containsKey(cfg.Object_API_Name__c)) {
                    configByObject.put(cfg.Object_API_Name__c, new List<Tracked_Field__mdt>());
                }
                configByObject.get(cfg.Object_API_Name__c).add(cfg);
            }
        }
        return configByObject.containsKey(objectApiName) ? configByObject.get(objectApiName) : new List<Tracked_Field__mdt>();
    }
}