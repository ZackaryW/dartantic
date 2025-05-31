import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/code_utils.dart';

class CreateMethodGenerator {
  static ASG generate(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
  ) {
    // Build parameter list using field metadata with named parameters
    final parameters = CodeUtils.generateCreateMethodParameters(fieldMetaDict);

    // Build values map creation using field metadata
    final valueAssignments = CodeUtils.generateValueAssignments(fieldMetaDict);
    valueAssignments.addAll([
      'final processedValues = dttPreprocess(values);',
      'dttValidate(processedValues);',
      'return dttPostprocess(processedValues);',
    ]);

    return CodeUtils.createMethod(
      name: 'dttCreate',
      returnType: 'Map<String, dynamic>',
      parameters: [
        '{${parameters.join(', ')}}',
      ], // Named parameters with braces
      bodyLines: valueAssignments,
    );
  }
}
