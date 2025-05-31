import 'package:analyzer/dart/element/element.dart';

class FieldUtils {
  /// Extract field name from method names like _dttpreprocess_fieldName
  static String? extractFieldName(String methodName, String prefix) {
    final regex = RegExp('^_dtt' + prefix + r'_([a-zA-Z0-9]+)(?:_|$)');
    final regex2 = RegExp(r'^_dtt' + prefix + r'_([a-zA-Z0-9]+)');
    final match = regex.firstMatch(methodName);
    final match2 = regex2.firstMatch(methodName);
    if (match != null) {
      return match.group(1);
    }
    if (match2 != null) {
      return match2.group(1);
    }
    return null;
  }

  /// Generate field metadata dictionary for a class
  static Map<String, dynamic> generateFieldMetaDict(
    ClassElement element,
    Map<String, ClassElement> modelClasses,
  ) {
    final fields = element.fields.where((field) => !field.isStatic).toList();
    final fieldMap = <String, Map<String, dynamic>>{};

    for (final field in fields) {
      final fieldType = field.type.element;
      final isModel =
          fieldType is ClassElement && modelClasses.containsKey(fieldType.name);

      fieldMap[field.name] = {
        'type': field.type.getDisplayString(withNullability: true),
        'isFinal': field.isFinal,
        'isLate': field.isLate,
        'subModel': isModel ? fieldType.name : null,
      };
    }

    return fieldMap;
  }

  /// Get all static methods of a specific type (preprocess, validate, postprocess)
  static List<MethodElement> getStaticMethodsByType(
    ClassElement element,
    String methodType,
  ) {
    return element.methods
        .where((m) => m.isStatic && m.name.startsWith('_dtt$methodType' + '_'))
        .toList();
  }

  /// Check if a field exists in the metadata dictionary
  static bool fieldExistsInMeta(
    String fieldName,
    Map<String, dynamic> fieldMetaDict,
  ) {
    return fieldMetaDict.containsKey(fieldName);
  }

  /// Get field info from metadata dictionary
  static Map<String, dynamic>? getFieldInfo(
    String fieldName,
    Map<String, dynamic> fieldMetaDict,
  ) {
    return fieldMetaDict[fieldName] as Map<String, dynamic>?;
  }
}
