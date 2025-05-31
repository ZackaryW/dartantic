import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/field_utils.dart';
import '../utils/code_utils.dart';

class PostprocessMethodGenerator {
  static ASG generate(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
  ) {
    final postprocessLines = <String>[
      '// Postprocessing step - modify values after validation',
    ];

    // Detect static postprocessing methods and validate field existence
    bool hasPostprocessing = false;
    final postprocessMethods = FieldUtils.getStaticMethodsByType(
      element,
      'postprocess',
    );

    for (final method in postprocessMethods) {
      final fieldName = FieldUtils.extractFieldName(method.name, 'postprocess');
      if (fieldName != null &&
          FieldUtils.fieldExistsInMeta(fieldName, fieldMetaDict)) {
        hasPostprocessing = true;
        postprocessLines.add(
          'values[\'$fieldName\'] = ${element.name}.${method.name}(values[\'$fieldName\']);',
        );
      } else if (fieldName != null) {
        postprocessLines.add(CodeUtils.generateFieldWarning(fieldName));
      }
    }

    if (!hasPostprocessing) {
      postprocessLines.add('// No postprocessing methods found');
    }

    postprocessLines.add('return values;');

    return CodeUtils.createMethod(
      name: 'dttPostprocess',
      returnType: 'Map<String, dynamic>',
      parameters: ['Map<String, dynamic> values'],
      bodyLines: postprocessLines,
    );
  }
}
