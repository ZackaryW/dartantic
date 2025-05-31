import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/metadata_parser.dart';
import '../utils/bloc_utils.dart';

class BlocCubitGenerator {
  static ASG generate(ClassElement element, ParsedModelMeta metadata) {
    final className = element.name;
    final asg = ASG();

    // Generate imports
    asg.addLine("import 'package:flutter_bloc/flutter_bloc.dart';");
    asg.addLine('');

    // Generate the main cubit class
    asg.add(_generateCubitClass(className, metadata).source);

    return asg;
  }

  /// Generate the main cubit class
  static ASG _generateCubitClass(String className, ParsedModelMeta metadata) {
    return ASG.CLASS(
      name: '${className}Cubit',
      extendsClass: 'Cubit<${className}State>',
      constructors: [
        ASG.CONSTRUCTOR(
          name: '${className}Cubit',
          initializers: ['super(${className}State.initial())'],
          noBody: true,
        ),
      ],
      methods: [
        // Field update methods
        ..._generateFieldUpdateMethods(className, metadata),
        // Load data method
        ASG.METHOD(
          name: 'loadData',
          parameters: ['Map<String, dynamic> data'],
          body: ASG.tryCatch(
            tryBlock: ASG.fromLines([
              'emit(${className}State.loading());',
              'final validatedData = _\$${className}Mixin.dttFromMap(data);',
              'emit(${className}State.success(validatedData));',
            ]),
            catchBlock: ASG.fromLines([
              'emit(${className}State.error(e.toString()));',
            ]),
          ),
        ),
        // Save data method
        ASG.METHOD(
          name: 'saveData',
          body: ASG.IF(
            condition: 'state is ${className}Data',
            then: ASG.tryCatch(
              tryBlock: ASG.fromLines([
                'final currentData = state as ${className}Data;',
                'final validatedData = _\$${className}Mixin.dttCreate(',
                ..._generateSaveParameters(metadata),
                ');',
                'emit(${className}State.success(validatedData));',
              ]),
              catchBlock: ASG.fromLines([
                'emit(${className}State.error(e.toString()));',
              ]),
            ),
          ),
        ),
        // Reset method
        ASG.METHOD(
          name: 'reset',
          body: ASG.fromLines(['emit(${className}State.initial());']),
        ),
        // Validate method
        ASG.METHOD(
          name: 'validate',
          body: ASG.IF(
            condition: 'state is ${className}Data',
            then: ASG.fromLines([
              'final currentData = state as ${className}Data;',
              'if (currentData.isValid) {',
              '  emit(${className}State.success(currentData.toMap()));',
              '} else {',
              '  emit(${className}State.error("Validation failed"));',
              '}',
            ]),
          ),
        ),
        // Current data map getter
        ASG.GETTER(
          name: 'currentDataMap',
          returnType: 'Map<String, dynamic>?',
          body: ASG.IF(
            condition: 'state is ${className}Data',
            then: ASG.fromLines([
              'return (state as ${className}Data).toMap();',
            ]),
            elseClause: ASG.fromLines(['return null;']),
          ),
        ),
        // Is valid getter
        ASG.GETTER(
          name: 'isValid',
          returnType: 'bool',
          body: ASG.IF(
            condition: 'state is ${className}Data',
            then: ASG.fromLines([
              'return (state as ${className}Data).isValid;',
            ]),
            elseClause: ASG.fromLines(['return false;']),
          ),
        ),
      ],
    );
  }

  /// Generate update methods for each field
  static List<ASG> _generateFieldUpdateMethods(
    String className,
    ParsedModelMeta metadata,
  ) {
    final methods = <ASG>[];

    for (final field in metadata.fields.values) {
      final methodName = 'update${_capitalize(field.name)}';

      methods.add(
        ASG.METHOD(
          name: methodName,
          parameters: ['${field.type} ${field.name}'],
          body: ASG.IF(
            condition: 'state is ${className}Data',
            then: ASG.tryCatch(
              tryBlock: ASG.fromLines([
                'final currentData = state as ${className}Data;',
                'final updatedData = currentData.copyWith(${field.name}: ${field.name});',
                'emit(updatedData);',
              ]),
              catchBlock: ASG.fromLines([
                'emit(${className}State.error(e.toString()));',
              ]),
            ),
            elseClause: ASG.tryCatch(
              tryBlock: ASG.fromLines([
                'final data = <String, dynamic>{',
                "  '${field.name}': ${field.name},",
                ..._generateDefaultFieldValues(metadata, field.name),
                '};',
                'final validatedData = _\$${className}Mixin.dttFromMap(data);',
                'emit(${className}State.success(validatedData));',
              ]),
              catchBlock: ASG.fromLines([
                'emit(${className}State.error(e.toString()));',
              ]),
            ),
          ),
        ),
      );
    }

    return methods;
  }

  /// Generate default values for fields when creating new state
  static List<String> _generateDefaultFieldValues(
    ParsedModelMeta metadata,
    String excludeField,
  ) {
    final defaults = <String>[];

    for (final field in metadata.fields.values) {
      if (field.name == excludeField) continue;

      if (field.isNullable) {
        defaults.add("  '${field.name}': null,");
      } else {
        // Generate appropriate default based on type
        final defaultValue = _getDefaultValue(field.type);
        defaults.add("  '${field.name}': $defaultValue,");
      }
    }

    return defaults;
  }

  /// Generate parameters for save method
  static List<String> _generateSaveParameters(ParsedModelMeta metadata) {
    final params = <String>[];

    for (final field in metadata.fields.values) {
      params.add('    ${field.name}: currentData.${field.name},');
    }

    return params;
  }

  /// Get default value for a type
  static String _getDefaultValue(String type) {
    switch (type) {
      case 'String':
        return "''";
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'DateTime':
        return 'DateTime.now()';
      default:
        // For custom types, try to call default constructor
        return 'null';
    }
  }

  /// Capitalize first letter
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
