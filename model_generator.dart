import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/model.dart';
import 'package:analyzer/dart/element/element.dart';

class ModelGenerator extends GeneratorForAnnotation<ddtModel> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    // ignore: deprecated_member_use
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // ignore: deprecated_member_use
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'The @ddtModel annotation can only be used on classes.',
        element: element,
      );
    }
    final className = element.name;
    final buffer = StringBuffer();

    // Generate the mixin class
    buffer.writeln('mixin _\$${className}Mixin {');
    buffer.writeln('  static Map<String, dynamic> create({');
    for (final field in element.fields.where((f) => !f.isStatic)) {
      buffer.writeln(
        '    required ${field.type.getDisplayString()} ${field.name},',
      );
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final values = <String, dynamic>{');
    for (final field in element.fields.where((f) => !f.isStatic)) {
      buffer.writeln('      \'${field.name}\': ${field.name},');
    }
    buffer.writeln('    };');
    buffer.writeln('    final processedValues = _preprocess(values);');
    buffer.writeln('    _validate(processedValues);');
    buffer.writeln('    return _postprocess(processedValues);');
    buffer.writeln('  }');

    // Generate _preprocess method
    buffer.writeln(
      '  static Map<String, dynamic> _preprocess(Map<String, dynamic> values) {',
    );
    for (final method in element.methods.where((m) => m.isStatic)) {
      if (method.name.startsWith('_preprocess_')) {
        final fieldName = _extractFieldName(method.name, 'preprocess');
        if (fieldName != null) {
          buffer.writeln(
            '    values[\'$fieldName\'] = ${element.name}.${method.name}(values[\'$fieldName\']);',
          );
        }
      }
    }
    buffer.writeln('    return values;');
    buffer.writeln('  }');

    // Generate _validate method
    buffer.writeln('  static void _validate(Map<String, dynamic> values) {');

    // First handle regular field validations
    for (final field in element.fields.where((f) => !f.isStatic)) {
      for (final meta in field.metadata) {
        final obj = meta.computeConstantValue();
        if (obj == null) continue;
        final typeStr = obj.type?.getDisplayString();
        print(
          '[GENERATOR] Field: ${field.name}, Annotation type: $typeStr, Full type: ${obj.type}',
        );
        if (typeStr == 'ddtRequired') {
          buffer.writeln(
            '    if (values[\'${field.name}\'] == null) throw DdtValidationError("${field.name} is required");',
          );
        } else if (typeStr == 'ddtMaxLength') {
          final len = obj.getField('length')?.toIntValue();
          buffer.writeln(
            '    if (values[\'${field.name}\'] != null && values[\'${field.name}\'].length > $len) throw DdtValidationError("${field.name} must be at most $len characters");',
          );
        }
      }
    }

    // Then handle custom validations from methods
    for (final method in element.methods.where(
      (m) => m.isStatic && m.name.startsWith('_validate_'),
    )) {
      for (final meta in method.metadata) {
        final obj = meta.computeConstantValue();
        if (obj == null) continue;
        final typeStr = obj.type?.getDisplayString();
        if (typeStr == 'ddtCustom') {
          final fieldName = _extractFieldName(method.name, 'validate');
          if (fieldName != null) {
            final hasValuesParam = method.parameters.length > 1;
            final validationCall =
                hasValuesParam
                    ? '${element.name}.${method.name}(values[\'$fieldName\'], values)'
                    : '${element.name}.${method.name}(values[\'$fieldName\'])';
            buffer.writeln(
              '    if (values[\'$fieldName\'] != null && !$validationCall) throw DdtValidationError("$fieldName failed custom validation");',
            );
          }
        }
      }
    }

    buffer.writeln('  }');

    // Generate _postprocess method
    buffer.writeln(
      '  static Map<String, dynamic> _postprocess(Map<String, dynamic> values) {',
    );
    for (final method in element.methods.where((m) => m.isStatic)) {
      if (method.name.startsWith('_postprocess_')) {
        final fieldName = _extractFieldName(method.name, 'postprocess');
        if (fieldName != null) {
          buffer.writeln(
            '    values[\'$fieldName\'] = ${element.name}.${method.name}(values[\'$fieldName\']);',
          );
        }
      }
    }
    buffer.writeln('    return values;');
    buffer.writeln('  }');

    buffer.writeln('}');
    return buffer.toString();
  }

  String? _extractFieldName(String methodName, String prefix) {
    final regex = RegExp('^_' + prefix + r'_([a-zA-Z0-9]+)(?:_|$)');
    final regex2 = RegExp(r'^_' + prefix + r'_([a-zA-Z0-9]+)');
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
}

Builder modelGeneratorBuilder(BuilderOptions options) => PartBuilder(
  [ModelGenerator()],
  '.dartantic.g.dart',
  header: '// GENERATED BY DARTANTIC\n',
);
