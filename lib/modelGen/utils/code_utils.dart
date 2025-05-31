import 'package:dartantic/asg/asg.dart';

class CodeUtils {
  /// Generate method parameters for create method
  static List<String> generateCreateMethodParameters(
    Map<String, dynamic> fieldMetaDict,
  ) {
    final parameters = <String>[];
    for (final entry in fieldMetaDict.entries) {
      final fieldName = entry.key;
      final fieldInfo = entry.value;
      final fieldType = fieldInfo['type'] as String;

      // For nullable types, don't use required
      if (fieldType.endsWith('?')) {
        parameters.add('$fieldType $fieldName');
      } else {
        parameters.add('required $fieldType $fieldName');
      }
    }
    return parameters;
  }

  /// Generate value assignments for create method
  static List<String> generateValueAssignments(
    Map<String, dynamic> fieldMetaDict,
  ) {
    final valueAssignments = <String>[];
    valueAssignments.add('final values = <String, dynamic>{');
    for (final fieldName in fieldMetaDict.keys) {
      valueAssignments.add("  '$fieldName': $fieldName,");
    }
    valueAssignments.add('};');
    return valueAssignments;
  }

  /// Generate validation error line
  static String generateValidationError(String fieldName, String message) {
    return 'throw DttValidationError(\'$fieldName\', \'$message\');';
  }

  /// Generate conditional validation check
  static List<String> generateConditionalValidation(
    String fieldName,
    String condition,
    String errorMessage,
  ) {
    return [
      'if (values[\'$fieldName\'] != null && $condition) {',
      '  ${generateValidationError(fieldName, errorMessage)}',
      '}',
    ];
  }

  /// Generate null check validation
  static List<String> generateNullCheck(String fieldName) {
    return [
      'if (values[\'$fieldName\'] == null) {',
      '  ${generateValidationError(fieldName, '$fieldName is required')}',
      '}',
    ];
  }

  /// Generate static method call
  static String generateStaticMethodCall(
    String className,
    String methodName,
    String fieldName,
    bool hasValuesParam,
  ) {
    final args =
        hasValuesParam
            ? 'values[\'$fieldName\'], values'
            : 'values[\'$fieldName\']';
    return '$className.$methodName($args)';
  }

  /// Generate field warning comment
  static String generateFieldWarning(String fieldName) {
    return '// Warning: Field \'$fieldName\' not found in model metadata';
  }

  /// Generate nested model serialization call
  static String generateNestedSerialization(
    String subModel,
    String fieldName,
    bool isOptional,
  ) {
    if (isOptional) {
      return '\'$fieldName\': obj.$fieldName != null ? _\$${subModel}Mixin.dttToMap(obj.$fieldName!) : null,';
    } else {
      return '\'$fieldName\': _\$${subModel}Mixin.dttToMap(obj.$fieldName),';
    }
  }

  /// Generate nested model deserialization call
  static String generateNestedDeserialization(
    String subModel,
    String fieldName,
    bool isOptional,
  ) {
    if (isOptional) {
      return '\'$fieldName\': map[\'$fieldName\'] != null ? _\$${subModel}Mixin.dttFromMap(map[\'$fieldName\'] as Map<String, dynamic>) : null,';
    } else {
      return '\'$fieldName\': _\$${subModel}Mixin.dttFromMap(map[\'$fieldName\'] as Map<String, dynamic>),';
    }
  }

  /// Create a standard ASG method with common patterns
  static ASG createMethod({
    required String name,
    required String returnType,
    required List<String> parameters,
    required List<String> bodyLines,
    bool isStatic = true,
  }) {
    return ASG.METHOD(
      name: name,
      returnType: returnType,
      parameters: parameters,
      isStatic: isStatic,
      body: ASG.fromLines(bodyLines),
    );
  }
}
