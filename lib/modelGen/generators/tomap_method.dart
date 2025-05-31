import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/code_utils.dart';

class ToMapMethodGenerator {
  static ASG generate(
    ClassElement element,
    Map<String, dynamic> fieldMetaDict,
  ) {
    final toMapLines = <String>[
      '// Convert object instance to a map',
      'return {',
    ];

    // Generate map entries for each field
    for (final entry in fieldMetaDict.entries) {
      final fieldName = entry.key;
      final fieldInfo = entry.value;
      final fieldType = fieldInfo['type'] as String;
      final subModel = fieldInfo['subModel'] as String?;

      if (subModel != null) {
        // Nested model field - automatically serialize to map
        toMapLines.add(
          CodeUtils.generateNestedSerialization(
            subModel,
            fieldName,
            fieldType.endsWith('?'),
          ),
        );
      } else {
        // Regular field - keep as-is
        toMapLines.add('  \'$fieldName\': obj.$fieldName,');
      }
    }

    toMapLines.add('};');

    return CodeUtils.createMethod(
      name: 'dttToMap',
      returnType: 'Map<String, dynamic>',
      parameters: ['${element.name} obj'],
      bodyLines: toMapLines,
    );
  }
}
