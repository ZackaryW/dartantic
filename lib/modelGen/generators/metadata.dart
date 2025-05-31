import 'package:dartantic/asg/asg.dart';

class MetadataGenerator {
  /// Generate the model metadata code
  static String generateModelMetaCode(
    String className,
    Map<String, dynamic> fieldMetaDict,
  ) {
    final asg = ASG();

    // Add the file-level field metadata dictionary
    asg.addLine(
      'const DttModelMeta _dtt_${className}_fieldMeta = DttModelMeta(',
    );
    asg.indentCounter++;
    asg.addLine('fields: {');

    for (final entry in fieldMetaDict.entries) {
      final fieldName = entry.key;
      final fieldInfo = entry.value;
      asg.addLine("'$fieldName': DttFieldMeta(");
      asg.indentCounter++;
      asg.addLine("type: '${fieldInfo['type']}',");
      asg.addLine("isFinal: ${fieldInfo['isFinal']},");
      asg.addLine("isLate: ${fieldInfo['isLate']},");
      asg.addLine(
        "subModel: ${fieldInfo['subModel'] != null ? "'${fieldInfo['subModel']}'" : 'null'},",
      );
      asg.indentCounter--;
      asg.addLine('),');
    }

    asg.indentCounter--;
    asg.addLine('},');
    asg.indentCounter--;
    asg.addLine(');');

    return asg.source;
  }

  /// Generate the class mixin wrapper code
  static String generateClassMixin(
    String className,
    List<String> methodSources,
  ) {
    final asg = ASG();

    // Generate mixin header
    asg.addLine('mixin _\$${className}Mixin {');
    asg.indentCounter++;

    // Add all method sources
    for (final methodSource in methodSources) {
      asg.add(methodSource);
    }

    asg.indentCounter--;
    asg.addLine('}');

    return asg.source;
  }
}
