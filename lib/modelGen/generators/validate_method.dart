import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/field_utils.dart';
import '../utils/code_utils.dart';

class ValidateMethodGenerator {
  static ASG generate(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
  ) {
    final validationLines = <String>[];

    // Process field annotations using fieldMetaDict - generate validation code directly
    _generateAnnotationValidations(element, fieldMetaDict, validationLines);

    // Process static validation methods
    _generateStaticValidations(element, fieldMetaDict, validationLines);

    // If no validations, add a comment
    if (validationLines.isEmpty) {
      validationLines.add('// No validations found');
    }

    return CodeUtils.createMethod(
      name: 'dttValidate',
      returnType: 'void',
      parameters: ['Map<String, dynamic> values'],
      bodyLines: validationLines,
    );
  }

  static void _generateAnnotationValidations(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
    List<String> validationLines,
  ) {
    for (final fieldName in fieldMetaDict.keys) {
      // Find the actual field element to get annotations
      final field = element.fields.firstWhere(
        (f) => f.name == fieldName && !f.isStatic,
        orElse: () => throw StateError('Field $fieldName not found'),
      );

      // Check each annotation on the field
      for (final annotation in field.metadata) {
        final obj = annotation.computeConstantValue();
        if (obj == null) continue;

        final typeStr = obj.type?.getDisplayString();
        if (typeStr == null) continue;

        // Generate validation code based on annotation type
        try {
          if (typeStr == 'DttvNotNull') {
            validationLines.addAll(CodeUtils.generateNullCheck(fieldName));
          } else if (typeStr == 'DttvMinLength') {
            final minLength = obj.getField('minLength')?.toIntValue() ?? 0;
            validationLines.addAll(
              CodeUtils.generateConditionalValidation(
                fieldName,
                'values[\'$fieldName\'].length < $minLength',
                '$fieldName must be at least $minLength characters',
              ),
            );
          } else if (typeStr == 'DttvMaxLength') {
            final maxLength = obj.getField('maxLength')?.toIntValue() ?? 0;
            validationLines.addAll(
              CodeUtils.generateConditionalValidation(
                fieldName,
                'values[\'$fieldName\'].length > $maxLength',
                '$fieldName must be at most $maxLength characters',
              ),
            );
          } else if (typeStr == 'DttValidateMethod') {
            // Get the function parameter from the annotation
            final funcField = obj.getField('func');
            if (funcField != null) {
              final funcName = funcField.toFunctionValue()?.displayName;
              if (funcName != null) {
                validationLines.addAll(
                  CodeUtils.generateConditionalValidation(
                    fieldName,
                    '!$funcName(values[\'$fieldName\'])',
                    '$fieldName failed custom validation',
                  ),
                );
              }
            }
          }
        } catch (e) {
          validationLines.add(
            '// Error generating validation for $typeStr on $fieldName: $e',
          );
        }
      }
    }
  }

  static void _generateStaticValidations(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
    List<String> validationLines,
  ) {
    final validateMethods = FieldUtils.getStaticMethodsByType(
      element,
      'validate',
    );

    for (final method in validateMethods) {
      final fieldName = FieldUtils.extractFieldName(method.name, 'validate');
      if (fieldName != null &&
          FieldUtils.fieldExistsInMeta(fieldName, fieldMetaDict)) {
        final hasValuesParam = method.parameters.length > 1;
        final validationCall = CodeUtils.generateStaticMethodCall(
          element.name,
          method.name,
          fieldName,
          hasValuesParam,
        );
        validationLines.addAll(
          CodeUtils.generateConditionalValidation(
            fieldName,
            '!$validationCall',
            '$fieldName failed custom validation',
          ),
        );
      } else if (fieldName != null) {
        validationLines.add(CodeUtils.generateFieldWarning(fieldName));
      }
    }
  }
}
