import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/code_utils.dart';

class FromMapMethodGenerator {
  static ASG generate(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
  ) {
    final fromMapLines = <String>[
      '// Process and validate map data (including nested models)',
      'final processedMap = <String, dynamic>{',
    ];

    // Generate map processing for each field
    for (final entry in fieldMetaDict.entries) {
      final fieldName = entry.key;
      final fieldInfo = entry.value;
      final fieldType = fieldInfo['type'] as String;
      final subModel = fieldInfo['subModel'] as String?;

      if (subModel != null) {
        // Nested model field
        fromMapLines.add(
          CodeUtils.generateNestedDeserialization(
            subModel,
            fieldName,
            fieldType.endsWith('?'),
          ),
        );
      } else {
        // Regular field
        fromMapLines.add('  \'$fieldName\': map[\'$fieldName\'],');
      }
    }

    fromMapLines.addAll([
      '};',
      '',
      '// Apply preprocessing, validation, and postprocessing to the processed map',
      'final preprocessed = dttPreprocess(processedMap);',
      'dttValidate(preprocessed);',
      'return dttPostprocess(preprocessed);',
    ]);

    return CodeUtils.createMethod(
      name: 'dttFromMap',
      returnType: 'Map<String, dynamic>',
      parameters: ['Map<String, dynamic> map'],
      bodyLines: fromMapLines,
    );
  }
}
