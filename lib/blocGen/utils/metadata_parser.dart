import 'dart:async';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as path;

/// Model field metadata parsed from generated files
class ParsedFieldMeta {
  final String name;
  final String type;
  final bool isFinal;
  final bool isLate;
  final String? subModel;
  final bool isNullable;

  ParsedFieldMeta({
    required this.name,
    required this.type,
    required this.isFinal,
    required this.isLate,
    this.subModel,
    required this.isNullable,
  });

  /// Parse from DttFieldMeta structure
  factory ParsedFieldMeta.fromDttFieldMeta(
    String name,
    Map<String, dynamic> fieldMeta,
  ) {
    final type = fieldMeta['type'] as String;
    return ParsedFieldMeta(
      name: name,
      type: type,
      isFinal: fieldMeta['isFinal'] as bool,
      isLate: fieldMeta['isLate'] as bool,
      subModel: fieldMeta['subModel'] as String?,
      isNullable: type.endsWith('?'),
    );
  }
}

/// Parsed model metadata from generated files
class ParsedModelMeta {
  final String className;
  final Map<String, ParsedFieldMeta> fields;

  ParsedModelMeta({required this.className, required this.fields});
}

class MetadataParser {
  /// Parse metadata from the corresponding .dartantic.g.dart file
  static Future<ParsedModelMeta?> parseGeneratedFile(
    ClassElement element,
    BuildStep buildStep,
  ) async {
    try {
      // Construct path to generated file
      final originalAssetId = buildStep.inputId;
      final generatedAssetId = AssetId(
        originalAssetId.package,
        originalAssetId.path.replaceAll('.dart', '.dartantic.g.dart'),
      );

      // Check if generated file exists
      if (!await buildStep.canRead(generatedAssetId)) {
        return null;
      }

      // Read the generated file content
      final generatedContent = await buildStep.readAsString(generatedAssetId);

      // Parse metadata from the generated content
      return _parseMetadataFromContent(element.name, generatedContent);
    } catch (e) {
      // Return null if parsing fails
      return null;
    }
  }

  /// Parse DttModelMeta from generated file content
  static ParsedModelMeta? _parseMetadataFromContent(
    String className,
    String content,
  ) {
    try {
      // Look for the metadata variable definition
      final metaRegex = RegExp(
        r'final DttModelMeta _dtt_' +
            className +
            r'_fieldMeta\s*=\s*DttModelMeta\(\s*fields:\s*\{([^}]+)\}',
        multiLine: true,
        dotAll: true,
      );

      final metaMatch = metaRegex.firstMatch(content);
      if (metaMatch == null) {
        return null;
      }

      final fieldsContent = metaMatch.group(1)!;
      final fields = <String, ParsedFieldMeta>{};

      // Parse each field definition
      final fieldRegex = RegExp(
        r"'(\w+)':\s*DttFieldMeta\(\s*type:\s*'([^']+)',\s*isFinal:\s*(true|false),\s*isLate:\s*(true|false),\s*subModel:\s*(null|'([^']+)'),",
        multiLine: true,
      );

      for (final fieldMatch in fieldRegex.allMatches(fieldsContent)) {
        final fieldName = fieldMatch.group(1)!;
        final type = fieldMatch.group(2)!;
        final isFinal = fieldMatch.group(3) == 'true';
        final isLate = fieldMatch.group(4) == 'true';
        final subModel = fieldMatch.group(
          6,
        ); // Group 5 is the full subModel match

        fields[fieldName] = ParsedFieldMeta(
          name: fieldName,
          type: type,
          isFinal: isFinal,
          isLate: isLate,
          subModel: subModel,
          isNullable: type.endsWith('?'),
        );
      }

      return ParsedModelMeta(className: className, fields: fields);
    } catch (e) {
      return null;
    }
  }
}
