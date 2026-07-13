public with sharing class EligibilityFormulaParser {

  public class ParsedCondition {
    public Integer sequence;
    public String objectApiName;
    public String fieldApiName;
    public String operatorToken;
    public String expectedValue;
    public String logicalOperator;
  }

  public static List<ParsedCondition> parse(String formula) {
    List<ParsedCondition> parsedConditions = new List<ParsedCondition>();

    if (String.isBlank(formula)) {
      return parsedConditions;
    }

    String text = formula.trim();
    Pattern fieldPattern = Pattern.compile('([A-Za-z0-9_]+)\\.([A-Za-z0-9_]+)');
    Matcher fieldMatcher = fieldPattern.matcher(text);
    Integer sequence = 1;

    while (fieldMatcher.find()) {
      ParsedCondition condition = new ParsedCondition();
      condition.sequence = sequence++;
      condition.objectApiName = fieldMatcher.group(1);
      condition.fieldApiName = fieldMatcher.group(2);

      String afterField = text.substring(fieldMatcher.end());
      Pattern operatorPattern = Pattern.compile('^\\s*(>=|<=|!=|\\+|\\-|=|>|<)\\s+');
      Matcher operatorMatcher = operatorPattern.matcher(afterField);

      if (!operatorMatcher.find()) {
        throw new EligibilityFormulaParserException(
          'Operator is required after ' + condition.objectApiName + '.' + condition.fieldApiName + '.'
        );
      }

      condition.operatorToken = operatorMatcher.group(1);
      String afterOperator = afterField.substring(operatorMatcher.end());

      Pattern valuePattern = Pattern.compile('^(\'[^\']*\'|[^\\s)]+)');
      Matcher valueMatcher = valuePattern.matcher(afterOperator);

      if (!valueMatcher.find()) {
        throw new EligibilityFormulaParserException(
          'Value is required after the operator for ' +
          condition.objectApiName +
          '.' +
          condition.fieldApiName +
          '.'
        );
      }

      condition.expectedValue = normalizeExpectedValue(valueMatcher.group(1));

      String afterValue = afterOperator.substring(valueMatcher.end()).trim();
      condition.logicalOperator = extractLogicalOperator(afterValue);

      parsedConditions.add(condition);
    }

    if (parsedConditions.isEmpty()) {
      throw new EligibilityFormulaParserException(
        'Formula must include at least one Object.Field reference.'
      );
    }

    return parsedConditions;
  }

  private static String normalizeExpectedValue(String rawValue) {
    if (String.isBlank(rawValue)) {
      return '';
    }

    String trimmedValue = rawValue.trim();
    if (trimmedValue.startsWith('\'') && trimmedValue.endsWith('\'')) {
      return trimmedValue.substring(1, trimmedValue.length() - 1);
    }

    return trimmedValue;
  }

  private static String extractLogicalOperator(String remainder) {
    if (String.isBlank(remainder)) {
      return '';
    }

    String upperRemainder = remainder.toUpperCase();
    if (upperRemainder.startsWith('AND')) {
      return 'AND';
    }
    if (upperRemainder.startsWith('OR')) {
      return 'OR';
    }

    return '';
  }

  public class EligibilityFormulaParserException extends Exception {
  }
}
