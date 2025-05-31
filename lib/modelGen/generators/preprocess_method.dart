import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/field_utils.dart';
import '../utils/code_utils.dart';

class PreprocessMethodGenerator {
  static ASG generate(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
  ) {
    final preprocessLines = <String>[
      '// Preprocessing step - modify values before validation',
    ];

    // Detect static preprocessing methods and validate field existence
    bool hasPreprocessing = false;
    final preprocessMethods = FieldUtils.getStaticMethodsByType(
      element,
      'preprocess',
    );

    for (final method in preprocessMethods) {
      final fieldName = FieldUtils.extractFieldName(method.name, 'preprocess');
      if (fieldName != null &&
          FieldUtils.fieldExistsInMeta(fieldName, fieldMetaDict)) {
        hasPreprocessing = true;
        preprocessLines.add(
          'values[\'$fieldName\'] = ${element.name}.${method.name}(values[\'$fieldName\']);',
        );
      } else if (fieldName != null) {
        preprocessLines.add(CodeUtils.generateFieldWarning(fieldName));
      }
    }

    if (!hasPreprocessing) {
      preprocessLines.add('// No preprocessing methods found');
    }

    preprocessLines.add('return values;');

    return CodeUtils.createMethod(
      name: 'dttPreprocess',
      returnType: 'Map<String, dynamic>',
      parameters: ['Map<String, dynamic> values'],
      bodyLines: preprocessLines,
    );
  }
}
