import 'package:dartantic/asg/asg.dart';
import 'metadata_parser.dart';

class BlocUtils {
  /// Generate import statements for bloc
  static List<String> generateBlocImports() {
    return [
      "import 'package:flutter_bloc/flutter_bloc.dart';",
      "import 'package:equatable/equatable.dart';",
    ];
  }

  /// Generate a method using ASG
  static ASG createMethod({
    required String name,
    required String returnType,
    required List<String> parameters,
    required List<String> bodyLines,
    bool isAsync = false,
    bool isOverride = false,
  }) {
    final asg = ASG();

    if (isOverride) {
      asg.addLine('@override');
    }

    final asyncKeyword = isAsync ? 'async ' : '';
    final returnTypeWithAsync =
        isAsync && returnType != 'void' ? 'Future<$returnType>' : returnType;

    asg.addLine(
      'static $returnTypeWithAsync $name(${parameters.join(', ')}) $asyncKeyword{',
    );
    asg.indentCounter++;

    for (final line in bodyLines) {
      if (line.trim().isEmpty) {
        asg.addLine('');
      } else {
        asg.addLine(line);
      }
    }

    asg.indentCounter--;
    asg.addLine('}');

    return asg;
  }

  /// Generate a class using ASG
  static ASG createClass({
    required String name,
    String? extendsClass,
    List<String> implementsClasses = const [],
    List<String> mixins = const [],
    required List<String> bodyLines,
    bool isAbstract = false,
  }) {
    final asg = ASG();

    final abstractKeyword = isAbstract ? 'abstract ' : '';
    var classDeclaration = '${abstractKeyword}class $name';

    if (extendsClass != null) {
      classDeclaration += ' extends $extendsClass';
    }

    if (mixins.isNotEmpty) {
      classDeclaration += ' with ${mixins.join(', ')}';
    }

    if (implementsClasses.isNotEmpty) {
      classDeclaration += ' implements ${implementsClasses.join(', ')}';
    }

    asg.addLine('$classDeclaration {');
    asg.indentCounter++;

    for (final line in bodyLines) {
      if (line.trim().isEmpty) {
        asg.addLine('');
      } else {
        asg.addLine(line);
      }
    }

    asg.indentCounter--;
    asg.addLine('}');

    return asg;
  }

  /// Generate property declarations
  static List<String> generateProperties(Map<String, ParsedFieldMeta> fields) {
    final properties = <String>[];

    for (final field in fields.values) {
      properties.add('final ${field.type} ${field.name};');
    }

    return properties;
  }

  /// Generate constructor parameters
  static List<String> generateConstructorParams(
    Map<String, ParsedFieldMeta> fields,
  ) {
    final params = <String>[];

    for (final field in fields.values) {
      final required = field.isNullable ? '' : 'required ';
      params.add('${required}this.${field.name}');
    }

    return params;
  }

  /// Generate field-based event names
  static List<String> generateEventNames(Map<String, ParsedFieldMeta> fields) {
    final events = <String>[];

    for (final field in fields.values) {
      final eventName = _capitalize(field.name);
      events.add('Update$eventName');
    }

    events.addAll(['Reset', 'Load', 'Save']);

    return events;
  }

  /// Generate validation calls for fields
  static List<String> generateValidationCalls(
    String className,
    Map<String, ParsedFieldMeta> fields,
  ) {
    final validations = <String>[];

    validations.add('// Validate using generated dartantic validation');
    validations.add('try {');
    validations.add('  final validatedData = _\$${className}Mixin.dttCreate(');

    final params = <String>[];
    for (final field in fields.values) {
      params.add('    ${field.name}: ${field.name}');
    }

    validations.add(params.join(',\n') + ',');
    validations.add('  );');
    validations.add('  return ${className}State.success(validatedData);');
    validations.add('} catch (e) {');
    validations.add('  return ${className}State.error(e.toString());');
    validations.add('}');

    return validations;
  }

  /// Generate copyWith method parameters
  static List<String> generateCopyWithParams(
    Map<String, ParsedFieldMeta> fields,
  ) {
    final params = <String>[];

    for (final field in fields.values) {
      params.add('${field.type}? ${field.name}');
    }

    return params;
  }

  /// Generate copyWith method body
  static List<String> generateCopyWithBody(
    String className,
    Map<String, ParsedFieldMeta> fields,
  ) {
    final body = <String>[];

    body.add('return ${className}State(');

    for (final field in fields.values) {
      body.add('  ${field.name}: ${field.name} ?? this.${field.name},');
    }

    body.add(');');

    return body;
  }

  /// Capitalize first letter
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Convert camelCase to snake_case
  static String toSnakeCase(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst('_', '');
  }
}
