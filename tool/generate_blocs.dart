#!/usr/bin/env dart

import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as path;

// Import the ASG system
import '../lib/asg/asg.dart';

/// Standalone bloc generator that runs after dartantic model generation
void main(List<String> args) async {
  print('🔥 Dartantic Bloc Generator');
  print('📂 Scanning for @dttBloc annotated classes...');

  final workingDir = Directory.current;
  final libDir = Directory(path.join(workingDir.path, 'lib'));
  final testDir = Directory(path.join(workingDir.path, 'test'));

  var filesProcessed = 0;
  var blocsGenerated = 0;

  // Process lib directory
  if (await libDir.exists()) {
    final count = await _processDirectory(libDir);
    filesProcessed += count['files']!;
    blocsGenerated += count['blocs']!;
  }

  // Process test directory
  if (await testDir.exists()) {
    final count = await _processDirectory(testDir);
    filesProcessed += count['files']!;
    blocsGenerated += count['blocs']!;
  }

  print('✅ Processed $filesProcessed files');
  print('🎯 Generated $blocsGenerated bloc files');
  print('🚀 Bloc generation complete!');
}

Future<Map<String, int>> _processDirectory(Directory dir) async {
  var filesProcessed = 0;
  var blocsGenerated = 0;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip generated files
      if (entity.path.endsWith('.g.dart')) continue;

      filesProcessed++;
      final generated = await _processFile(entity);
      if (generated) blocsGenerated++;
    }
  }

  return {'files': filesProcessed, 'blocs': blocsGenerated};
}

Future<bool> _processFile(File file) async {
  try {
    final content = await file.readAsString();

    // Quick check for @dttBloc annotation
    if (!content.contains('@dttBloc')) {
      return false;
    }

    print('🔍 Analyzing ${path.relative(file.path)}');

    // Parse the Dart file
    final parseResult = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
      path: file.path,
    );

    final visitor = BlocAnnotationVisitor();
    parseResult.unit.accept(visitor);

    if (visitor.blocClasses.isEmpty) {
      return false;
    }

    // Generate bloc files for each @dttBloc class
    for (final className in visitor.blocClasses) {
      await _generateBlocFile(file, className);
    }

    return true;
  } catch (e) {
    print('❌ Error processing ${file.path}: $e');
    return false;
  }
}

Future<void> _generateBlocFile(File originalFile, String className) async {
  // Check if corresponding .dartantic.g.dart file exists
  final dartanticFile = File(
    originalFile.path.replaceAll('.dart', '.dartantic.g.dart'),
  );

  if (!await dartanticFile.exists()) {
    print('⚠️  Skipping $className - no .dartantic.g.dart file found');
    print('   Run "dart run build_runner build" first to generate model files');
    return;
  }

  print('🔨 Generating bloc for $className');

  // Read and parse metadata from .dartantic.g.dart file
  final dartanticContent = await dartanticFile.readAsString();
  final metadata = _parseModelMetadata(className, dartanticContent);

  if (metadata == null) {
    print('⚠️  Could not parse metadata for $className');
    return;
  }

  // Add original file name to metadata
  final originalFileName = path.basenameWithoutExtension(originalFile.path);
  metadata['originalFileName'] = originalFileName;

  // Generate bloc code using ASG
  final blocCode = _generateBlocCodeWithASG(className, metadata);

  // Write bloc file
  final blocFile = File(originalFile.path.replaceAll('.dart', '.bloc.g.dart'));
  await blocFile.writeAsString(blocCode);

  print('✅ Generated ${path.relative(blocFile.path)}');
}

Map<String, dynamic>? _parseModelMetadata(String className, String content) {
  // Parse DttModelMeta from generated file
  final metaRegex = RegExp(
    r'final DttModelMeta _dtt_' +
        className +
        r'_fieldMeta\s*=\s*DttModelMeta\(\s*fields:\s*\{([^}]+)\}',
    multiLine: true,
    dotAll: true,
  );

  final metaMatch = metaRegex.firstMatch(content);
  if (metaMatch == null) return null;

  final fieldsContent = metaMatch.group(1)!;
  final fields = <String, Map<String, dynamic>>{};

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
    final subModel = fieldMatch.group(6);

    fields[fieldName] = {
      'type': type,
      'isFinal': isFinal,
      'isLate': isLate,
      'subModel': subModel,
      'isNullable': type.endsWith('?'),
    };
  }

  return {'className': className, 'fields': fields};
}

String _generateBlocCodeWithASG(
  String className,
  Map<String, dynamic> metadata,
) {
  final fields = metadata['fields'] as Map<String, Map<String, dynamic>>;
  final originalFileName = metadata['originalFileName'] as String;

  final asg = ASG();

  // Add file header
  asg.addLine('// GENERATED BY DARTANTIC BLOC GENERATOR');
  asg.addLine('');
  asg.addLine("part of '$originalFileName.dart';");
  asg.addLine('');
  asg.addLine(
    '// **************************************************************************',
  );
  asg.addLine('// BlocGenerator');
  asg.addLine(
    '// **************************************************************************',
  );
  asg.addLine('');

  // Generate standalone base classes
  asg.add(_generateStandaloneBaseClasses().source);
  asg.addLine('');

  // Generate state classes using ASG
  asg.add(_generateStateClassesWithASG(className, fields).source);
  asg.addLine('');

  // Generate event classes using ASG
  asg.add(_generateEventClassesWithASG(className, fields).source);
  asg.addLine('');

  // Generate cubit class using ASG
  asg.add(_generateCubitClassWithASG(className, fields).source);

  return asg.source;
}

ASG _generateStandaloneBaseClasses() {
  final asg = ASG();

  asg.addLine('// Standalone bloc implementation (no external dependencies)');

  // Generate _Equatable class
  asg.add(
    ASG
        .CLASS(
          name: '_Equatable',
          methods: [
            ASG.GETTER(
              name: 'props',
              returnType: 'List<Object?>',
              isOverride: true,
              body: ASG.fromLines(['return [];']),
            ),
            ASG.METHOD(
              name: 'operator ==',
              returnType: 'bool',
              parameters: ['Object other'],
              isOverride: true,
              body: ASG.fromLines([
                'if (identical(this, other)) return true;',
                'if (other.runtimeType != runtimeType) return false;',
                'final otherEquatable = other as _Equatable;',
                'return _listEquals(props, otherEquatable.props);',
              ]),
            ),
            ASG.GETTER(
              name: 'hashCode',
              returnType: 'int',
              isOverride: true,
              body: ASG.fromLines(['return _listHashCode(props);']),
            ),
            ASG.METHOD(
              name: '_listEquals',
              returnType: 'bool',
              parameters: ['List<Object?> a', 'List<Object?> b'],
              isStatic: true,
              body: ASG.fromLines([
                'if (a.length != b.length) return false;',
                'for (int i = 0; i < a.length; i++) {',
                '  if (a[i] != b[i]) return false;',
                '}',
                'return true;',
              ]),
            ),
            ASG.METHOD(
              name: '_listHashCode',
              returnType: 'int',
              parameters: ['List<Object?> list'],
              isStatic: true,
              body: ASG.fromLines([
                'int hash = 0;',
                'for (final item in list) {',
                '  hash = hash ^ (item?.hashCode ?? 0);',
                '}',
                'return hash;',
              ]),
            ),
          ],
          constructors: [
            ASG.CONSTRUCTOR(name: '_Equatable', isConst: true, noBody: true),
          ],
        )
        .source,
  );

  asg.addLine('');

  // Generate _Cubit class
  asg.add(
    ASG
        .CLASS(
          name: '_Cubit<State>',
          fields: [
            ASG.FIELD(name: '_state', type: 'State'),
            ASG.FIELD(
              name: '_listeners',
              type: 'List<void Function(State)>',
              initializer: '[]',
              isFinal: true,
            ),
          ],
          constructors: [
            ASG.CONSTRUCTOR(name: '_Cubit', parameters: ['this._state']),
          ],
          methods: [
            ASG.GETTER(
              name: 'state',
              returnType: 'State',
              body: ASG.fromLines(['return _state;']),
            ),
            ASG.METHOD(
              name: 'emit',
              returnType: 'void',
              parameters: ['State newState'],
              body: ASG.fromLines([
                '_state = newState;',
                'for (final listener in _listeners) {',
                '  listener(newState);',
                '}',
              ]),
            ),
            ASG.METHOD(
              name: 'listen',
              returnType: 'void',
              parameters: ['void Function(State) listener'],
              body: ASG.fromLines(['_listeners.add(listener);']),
            ),
            ASG.METHOD(
              name: 'dispose',
              returnType: 'void',
              body: ASG.fromLines(['_listeners.clear();']),
            ),
          ],
        )
        .source,
  );

  return asg;
}

ASG _generateStateClassesWithASG(
  String className,
  Map<String, Map<String, dynamic>> fields,
) {
  final asg = ASG();

  asg.addLine('// State Classes');

  // Abstract base state class
  asg.add(
    ASG
        .CLASS(
          name: '${className}State',
          extendsClass: '_Equatable',
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}State',
              isConst: true,
              noBody: true,
            ),
          ],
          methods: [
            ASG.GETTER(
              name: 'props',
              returnType: 'List<Object?>',
              isOverride: true,
              body: ASG.fromLines(['return [];']),
            ),
            // Factory constructors
            ASG.METHOD(
              name: 'initial',
              returnType: '${className}State',
              isStatic: true,
              body: ASG.fromLines(['return ${className}Initial();']),
            ),
            ASG.METHOD(
              name: 'loading',
              returnType: '${className}State',
              isStatic: true,
              body: ASG.fromLines(['return ${className}Loading();']),
            ),
            ASG.METHOD(
              name: 'success',
              returnType: '${className}State',
              parameters: ['Map<String, dynamic> data'],
              isStatic: true,
              body: ASG.fromLines([
                'return ${className}Data.fromValidated(data);',
              ]),
            ),
            ASG.METHOD(
              name: 'error',
              returnType: '${className}State',
              parameters: ['String message'],
              isStatic: true,
              body: ASG.fromLines(['return ${className}Error(message);']),
            ),
          ],
        )
        .source,
  );

  asg.addLine('');

  // Data state class
  final dataFields = <ASG>[];
  final constructorParams = <String>[];
  final copyWithParams = <String>[];
  final propsFields = <String>[];

  for (final field in fields.entries) {
    final fieldName = field.key;
    final fieldType = field.value['type'] as String;
    final isNullable = field.value['isNullable'] as bool;

    dataFields.add(ASG.FIELD(name: fieldName, type: fieldType, isFinal: true));
    constructorParams.add('${isNullable ? '' : 'required '}this.$fieldName');
    copyWithParams.add('${isNullable ? fieldType : '$fieldType?'} $fieldName');
    propsFields.add(fieldName);
  }

  final dataClassMethods = <ASG>[
    // fromValidated factory
    ASG.METHOD(
      name: 'fromValidated',
      returnType: '${className}Data',
      parameters: ['Map<String, dynamic> data'],
      isStatic: true,
      body: ASG.fromLines([
        'return ${className}Data(',
        ...fields.entries.map(
          (e) => "  ${e.key}: data['${e.key}'] as ${e.value['type']},",
        ),
        ');',
      ]),
    ),

    // copyWith method
    ASG.METHOD(
      name: 'copyWith',
      returnType: '${className}Data',
      parameters: ['{${copyWithParams.join(', ')}}'],
      body: ASG.fromLines([
        'return ${className}Data(',
        ...fields.entries.map((e) => '  ${e.key}: ${e.key} ?? this.${e.key},'),
        ');',
      ]),
    ),

    // toMap method
    ASG.METHOD(
      name: 'toMap',
      returnType: 'Map<String, dynamic>',
      body: ASG.fromLines([
        'return {',
        ...fields.entries.map((e) => "  '${e.key}': ${e.key},"),
        '};',
      ]),
    ),

    // props getter
    ASG.GETTER(
      name: 'props',
      returnType: 'List<Object?>',
      isOverride: true,
      body: ASG.fromLines(['return [${propsFields.join(', ')}];']),
    ),

    // isValid getter
    ASG.GETTER(
      name: 'isValid',
      returnType: 'bool',
      body: ASG.fromLines([
        'try {',
        '  _\$${className}Mixin.dttValidate(toMap());',
        '  return true;',
        '} catch (e) {',
        '  return false;',
        '}',
      ]),
    ),
  ];

  asg.add(
    ASG
        .CLASS(
          name: '${className}Data',
          extendsClass: '${className}State',
          fields: dataFields,
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}Data',
              parameters: ['{${constructorParams.join(', ')}}'],
              isConst: true,
              noBody: true,
            ),
          ],
          methods: dataClassMethods,
        )
        .source,
  );

  asg.addLine('');

  // Loading state
  asg.add(
    ASG
        .CLASS(
          name: '${className}Loading',
          extendsClass: '${className}State',
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}Loading',
              isConst: true,
              noBody: true,
            ),
          ],
        )
        .source,
  );

  asg.addLine('');

  // Error state
  asg.add(
    ASG
        .CLASS(
          name: '${className}Error',
          extendsClass: '${className}State',
          fields: [ASG.FIELD(name: 'message', type: 'String', isFinal: true)],
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}Error',
              parameters: ['this.message'],
              isConst: true,
              noBody: true,
            ),
          ],
          methods: [
            ASG.GETTER(
              name: 'props',
              returnType: 'List<Object?>',
              isOverride: true,
              body: ASG.fromLines(['return [message];']),
            ),
          ],
        )
        .source,
  );

  asg.addLine('');

  // Initial state
  asg.add(
    ASG
        .CLASS(
          name: '${className}Initial',
          extendsClass: '${className}State',
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}Initial',
              isConst: true,
              noBody: true,
            ),
          ],
        )
        .source,
  );

  return asg;
}

ASG _generateEventClassesWithASG(
  String className,
  Map<String, Map<String, dynamic>> fields,
) {
  final asg = ASG();

  asg.addLine('// Event Classes');

  // Abstract base event class
  asg.add(
    ASG
        .CLASS(
          name: '${className}Event',
          extendsClass: '_Equatable',
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}Event',
              isConst: true,
              noBody: true,
            ),
          ],
          methods: [
            ASG.GETTER(
              name: 'props',
              returnType: 'List<Object?>',
              isOverride: true,
              body: ASG.fromLines(['return [];']),
            ),
          ],
        )
        .source,
  );

  asg.addLine('');

  // Generate field update events
  for (final field in fields.entries) {
    final fieldName = field.key;
    final fieldType = field.value['type'] as String;
    final eventName = 'Update${_capitalize(fieldName)}';

    asg.add(
      ASG
          .CLASS(
            name: '${className}$eventName',
            extendsClass: '${className}Event',
            fields: [
              ASG.FIELD(name: fieldName, type: fieldType, isFinal: true),
            ],
            constructors: [
              ASG.CONSTRUCTOR(
                name: '${className}$eventName',
                parameters: ['this.$fieldName'],
                isConst: true,
                noBody: true,
              ),
            ],
            methods: [
              ASG.GETTER(
                name: 'props',
                returnType: 'List<Object?>',
                isOverride: true,
                body: ASG.fromLines(['return [$fieldName];']),
              ),
            ],
          )
          .source,
    );

    asg.addLine('');
  }

  // Generate common events
  final commonEvents = [
    ('Load', 'final Map<String, dynamic>? data;', '[this.data]', '[data]'),
    ('Save', null, null, null),
    ('Reset', null, null, null),
    ('Validate', null, null, null),
  ];

  for (final eventInfo in commonEvents) {
    final eventName = eventInfo.$1;
    final field = eventInfo.$2;
    final constructorParam = eventInfo.$3;
    final props = eventInfo.$4;

    final eventFields = <ASG>[];
    final constructorParams = <String>[];
    final methods = <ASG>[];

    if (field != null) {
      eventFields.add(
        ASG.FIELD(name: 'data', type: 'Map<String, dynamic>?', isFinal: true),
      );
      methods.add(
        ASG.GETTER(
          name: 'props',
          returnType: 'List<Object?>',
          isOverride: true,
          body: ASG.fromLines(['return $props;']),
        ),
      );
      constructorParams.add(constructorParam!);
    } else {
      methods.add(
        ASG.GETTER(
          name: 'props',
          returnType: 'List<Object?>',
          isOverride: true,
          body: ASG.fromLines(['return [];']),
        ),
      );
    }

    asg.add(
      ASG
          .CLASS(
            name: '${className}$eventName',
            extendsClass: '${className}Event',
            fields: eventFields,
            constructors: [
              ASG.CONSTRUCTOR(
                name: '${className}$eventName',
                parameters: constructorParams,
                isConst: true,
                noBody: true,
              ),
            ],
            methods: methods,
          )
          .source,
    );

    asg.addLine('');
  }

  return asg;
}

ASG _generateCubitClassWithASG(
  String className,
  Map<String, Map<String, dynamic>> fields,
) {
  final asg = ASG();

  asg.addLine('// Cubit Class');

  final methods = <ASG>[];

  // Generate field update methods
  for (final field in fields.entries) {
    final fieldName = field.key;
    final fieldType = field.value['type'] as String;
    final methodName = 'update${_capitalize(fieldName)}';

    // Build default values for other fields
    final defaultValues = <String>[];
    for (final otherField in fields.entries) {
      if (otherField.key != fieldName) {
        final defaultValue = _getDefaultValue(otherField.value['type']);
        defaultValues.add("          '${otherField.key}': $defaultValue,");
      }
    }

    methods.add(
      ASG.METHOD(
        name: methodName,
        returnType: 'void',
        parameters: ['$fieldType $fieldName'],
        body: ASG.fromLines([
          'if (state is ${className}Data) {',
          '  final currentData = state as ${className}Data;',
          '  final updatedData = currentData.copyWith($fieldName: $fieldName);',
          '  emit(updatedData);',
          '} else {',
          '  try {',
          '    final data = <String, dynamic>{',
          "      '$fieldName': $fieldName,",
          ...defaultValues,
          '    };',
          '    final validatedData = _\$${className}Mixin.dttFromMap(data);',
          '    emit(${className}State.success(validatedData));',
          '  } catch (e) {',
          '    emit(${className}State.error(e.toString()));',
          '  }',
          '}',
        ]),
      ),
    );
  }

  // Generate common methods
  methods.addAll([
    ASG.METHOD(
      name: 'loadData',
      returnType: 'void',
      parameters: ['Map<String, dynamic> data'],
      body: ASG.fromLines([
        'emit(${className}State.loading());',
        'try {',
        '  final validatedData = _\$${className}Mixin.dttFromMap(data);',
        '  emit(${className}State.success(validatedData));',
        '} catch (e) {',
        '  emit(${className}State.error(e.toString()));',
        '}',
      ]),
    ),

    ASG.METHOD(
      name: 'saveData',
      returnType: 'void',
      body: ASG.fromLines([
        'if (state is ${className}Data) {',
        '  final currentData = state as ${className}Data;',
        '  try {',
        '    final validatedData = _\$${className}Mixin.dttCreate(',
        ...fields.entries.map((e) => '      ${e.key}: currentData.${e.key},'),
        '    );',
        '    emit(${className}State.success(validatedData));',
        '  } catch (e) {',
        '    emit(${className}State.error(e.toString()));',
        '  }',
        '}',
      ]),
    ),

    ASG.METHOD(
      name: 'reset',
      returnType: 'void',
      body: ASG.fromLines(['emit(${className}State.initial());']),
    ),

    ASG.METHOD(
      name: 'validate',
      returnType: 'void',
      body: ASG.fromLines([
        'if (state is ${className}Data) {',
        '  final currentData = state as ${className}Data;',
        '  if (currentData.isValid) {',
        '    emit(${className}State.success(currentData.toMap()));',
        '  } else {',
        '    emit(${className}State.error("Validation failed"));',
        '  }',
        '}',
      ]),
    ),

    ASG.METHOD(
      name: 'isValid',
      returnType: 'bool',
      body: ASG.fromLines([
        'if (state is ${className}Data) {',
        '  return (state as ${className}Data).isValid;',
        '}',
        'return false;',
      ]),
    ),

    ASG.METHOD(
      name: 'currentDataMap',
      returnType: 'Map<String, dynamic>?',
      body: ASG.fromLines([
        'if (state is ${className}Data) {',
        '  return (state as ${className}Data).toMap();',
        '}',
        'return null;',
      ]),
    ),
  ]);

  asg.add(
    ASG
        .CLASS(
          name: '${className}Cubit',
          extendsClass: '_Cubit<${className}State>',
          constructors: [
            ASG.CONSTRUCTOR(
              name: '${className}Cubit',
              initializers: ['super(${className}State.initial())'],
            ),
          ],
          methods: methods,
        )
        .source,
  );

  return asg;
}

String _getDefaultValue(String type) {
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
      return 'null';
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

class BlocAnnotationVisitor extends RecursiveAstVisitor<void> {
  final List<String> blocClasses = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    bool hasDttBloc = false;
    bool hasDttModel = false;

    for (final annotation in node.metadata) {
      final name = annotation.name.name;
      if (name == 'dttBloc') hasDttBloc = true;
      if (name == 'dttModel') hasDttModel = true;
    }

    if (hasDttBloc && hasDttModel) {
      blocClasses.add(node.name.lexeme);
    }

    super.visitClassDeclaration(node);
  }
}
