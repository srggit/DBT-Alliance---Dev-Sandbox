@RestResource(urlMapping='/getEligibilityCriteria')
global with sharing class getEligibilityCriteriaAPI {

    @HttpGet
    global static ResponseWrapper getEligibilityCriteria() {
        ResponseWrapper response = new ResponseWrapper();

        String yearlySchemeId = RestContext.request.params.get('yearlySchemeId');
        System.debug('yearlySchemeId: ' + yearlySchemeId);

        if(String.isBlank(yearlySchemeId)) {
            response.success = false;
            response.message = 'Yearly scheme ID is required';
            return response;
        }

        try {
            List<Eligibility_Criteria__c> eligibilityCriteria = [
                SELECT Id, Name, Validation_Type__c, Is_Active__c, Yearly_Scheme__c, Eligibility_Type__c, Stage__c, Pass_Message__c, Fail_Message__c,
                    (SELECT Id, Eligibility_Criteria__c, Sequence__c, Object_API_Name__c, Field_API_Name__c, Operator__c, Value__c, Logical_Operator__c 
                    FROM Eligibility_Conditions__r)
                FROM Eligibility_Criteria__c 
                WHERE Is_Active__c = true
                AND Yearly_Scheme__c = :yearlySchemeId
            ];

            List<EligibilityCriteriaWrapper> eligibilityCriteriaWrappers = new List<EligibilityCriteriaWrapper>();
            List<EligibilityConditionWrapper> eligibilityConditionWrappers = new List<EligibilityConditionWrapper>();

            for(Eligibility_Criteria__c eligibilityCriterion : eligibilityCriteria) {
                EligibilityCriteriaWrapper eligibilityCriteriaWrapper = new EligibilityCriteriaWrapper();
                eligibilityCriteriaWrapper.eligibilityCriteriaId = eligibilityCriterion.Id;
                eligibilityCriteriaWrapper.eligibilityCriteriaName = eligibilityCriterion.Name;
                eligibilityCriteriaWrapper.validationType = eligibilityCriterion.Validation_Type__c;
                eligibilityCriteriaWrapper.isActive = eligibilityCriterion.Is_Active__c;
                eligibilityCriteriaWrapper.yearlySchemeId = eligibilityCriterion.Yearly_Scheme__c;
                eligibilityCriteriaWrapper.eligibilityType = eligibilityCriterion.Eligibility_Type__c;
                eligibilityCriteriaWrapper.stage = eligibilityCriterion.Stage__c;
                eligibilityCriteriaWrapper.passMessage = eligibilityCriterion.Pass_Message__c;
                eligibilityCriteriaWrapper.failMessage = eligibilityCriterion.Fail_Message__c;

                for(Eligibility_Condition__c eligibilityCondition : eligibilityCriterion.Eligibility_Conditions__r) {
                    EligibilityConditionWrapper ecw = new EligibilityConditionWrapper();
                    ecw.eligibilityCriteriaId = eligibilityCondition.Eligibility_Criteria__c;
                    ecw.sequence = eligibilityCondition.Sequence__c;
                    ecw.objectApiName = eligibilityCondition.Object_API_Name__c;
                    ecw.fieldApiName = eligibilityCondition.Field_API_Name__c;
                    ecw.operator = eligibilityCondition.Operator__c;
                    ecw.value = eligibilityCondition.Value__c;
                    ecw.logicalOperator = eligibilityCondition.Logical_Operator__c;
                    eligibilityConditionWrappers.add(ecw);
                    eligibilityCriteriaWrapper.eligibilityConditions = eligibilityConditionWrappers;
                }

                eligibilityCriteriaWrappers.add(eligibilityCriteriaWrapper);
            }

            response.success = true;
            response.message = 'Eligibility criteria fetched successfully';
            response.data = eligibilityCriteriaWrappers;

            return response;
        }
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Error: ' + e.getStackTraceString());

            response.success = false;
            response.message = e.getMessage();
            response.data = null;
            return response;
        }
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public List<EligibilityCriteriaWrapper> data;
    }

    global class EligibilityCriteriaWrapper {
        public String eligibilityCriteriaId;
        public String eligibilityCriteriaName;
        public String validationType;
        public Boolean isActive;
        public String yearlySchemeId;
        public String eligibilityType;
        public String stage;
        public String passMessage;
        public String failMessage;
        public List<EligibilityConditionWrapper> eligibilityConditions;
    }

    global class EligibilityConditionWrapper {
        public String eligibilityCriteriaId;
        public Decimal sequence;
        public String objectApiName;
        public String fieldApiName;
        public String operator;
        public String value;
        public String logicalOperator;
    }
}