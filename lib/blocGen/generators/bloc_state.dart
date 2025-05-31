import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/metadata_parser.dart';
import '../utils/bloc_utils.dart';

class BlocStateGenerator {
  static ASG generate(ClassElement element, ParsedModelMeta metadata) {
    final className = element.name;
    final asg = ASG();

    // Generate base state class
    asg.add(_generateBaseState(className).source);
    asg.addLine('');

    // Generate specific state implementations
    asg.add(_generateDataState(className, metadata).source);
    asg.addLine('');
    asg.add(_generateLoadingState(className).source);
    asg.addLine('');
    asg.add(_generateErrorState(className).source);
    asg.addLine('');
    asg.add(_generateInitialState(className).source);

    return asg;
  }

  /// Generate abstract base state class
  static ASG _generateBaseState(String className) {
    final asg = ASG();
    asg.addLine('abstract class ${className}State extends Equatable {');
    asg.indentCounter++;

    // Add const constructor
    asg.add(
      ASG
          .CONSTRUCTOR(name: '${className}State', isConst: true, noBody: true)
          .source,
    );
    asg.addLine('');

    // Add factory constructors
    asg.add(
      ASG
          .METHOD(
            name: 'initial',
            isStatic: true,
            returnType: '${className}State',
            body: ASG.fromLines(['return ${className}Initial();']),
          )
          .source,
    );
    asg.addLine('');

    asg.add(
      ASG
          .METHOD(
            name: 'loading',
            isStatic: true,
            returnType: '${className}State',
            body: ASG.fromLines(['return ${className}Loading();']),
          )
          .source,
    );
    asg.addLine('');

    asg.add(
      ASG
          .METHOD(
            name: 'success',
            isStatic: true,
            returnType: '${className}State',
            parameters: ['${className} data'],
            body: ASG.fromLines(['return ${className}Data(data);']),
          )
          .source,
    );
    asg.addLine('');

    asg.add(
      ASG
          .METHOD(
            name: 'error',
            isStatic: true,
            returnType: '${className}State',
            parameters: ['String message'],
            body: ASG.fromLines(['return ${className}Error(message);']),
          )
          .source,
    );
    asg.addLine('');

    // Add props getter
    asg.add(
      ASG
          .GETTER(
            name: 'props',
            returnType: 'List<Object?>',
            body: ASG.fromLines(['return [];']),
          )
          .source,
    );

    asg.indentCounter--;
    asg.addLine('}');
    return asg;
  }

  /// Generate data state with validated fields
  static ASG _generateDataState(String className, ParsedModelMeta metadata) {
    // Generate fields
    final fields =
        metadata.fields.values
            .map(
              (field) =>
                  ASG.FIELD(name: field.name, type: field.type, isFinal: true),
            )
            .toList();

    // Generate constructor parameters
    final constructorParams =
        metadata.fields.values
            .map((field) => '${field.type} ${field.name}')
            .toList();

    // Generate copyWith parameters
    final copyWithParams =
        metadata.fields.values
            .map((field) => '${field.type}? ${field.name}')
            .toList();

    return ASG.CLASS(
      name: '${className}Data',
      extendsClass: '${className}State',
      fields: fields,
      constructors: [
        // Main constructor
        ASG.CONSTRUCTOR(
          name: '${className}Data',
          parameters: constructorParams,
          isConst: true,
          noBody: true,
        ),
        // fromValidated factory
        ASG.CONSTRUCTOR(
          name: '${className}Data.fromValidated',
          parameters: ['Map<String, dynamic> data'],
          isFactory: true,
          body: ASG.fromLines([
            'return ${className}Data(',
            ...metadata.fields.values.map(
              (field) =>
                  "  ${field.name}: data['${field.name}'] as ${field.type},",
            ),
            ');',
          ]),
        ),
      ],
      methods: [
        // copyWith method
        ASG.METHOD(
          name: 'copyWith',
          returnType: '${className}Data',
          parameters: copyWithParams.map((p) => '{$p}').toList(),
          body: ASG.fromLines([
            'return ${className}Data(',
            ...metadata.fields.values.map(
              (field) =>
                  '  ${field.name}: ${field.name} ?? this.${field.name},',
            ),
            ');',
          ]),
        ),
        // toMap method
        ASG.METHOD(
          name: 'toMap',
          returnType: 'Map<String, dynamic>',
          body: ASG.fromLines([
            'return {',
            ...metadata.fields.values.map(
              (field) => "  '${field.name}': ${field.name},",
            ),
            '};',
          ]),
        ),
        // isValid getter
        ASG.GETTER(
          name: 'isValid',
          returnType: 'bool',
          body: ASG.tryCatch(
            tryBlock: ASG.fromLines([
              '_\$${className}Mixin.dttValidate(toMap());',
              'return true;',
            ]),
            catchBlock: ASG.fromLines(['return false;']),
          ),
        ),
        // props getter
        ASG.GETTER(
          name: 'props',
          returnType: 'List<Object?>',
          isOverride: true,
          body: ASG.fromLines([
            'return [',
            ...metadata.fields.keys.map((name) => '  $name,'),
            '];',
          ]),
        ),
      ],
    );
  }

  /// Generate loading state
  static ASG _generateLoadingState(String className) {
    return ASG.CLASS(
      name: '${className}Loading',
      extendsClass: '${className}State',
      constructors: [
        ASG.CONSTRUCTOR(
          name: '${className}Loading',
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
    );
  }

  /// Generate error state
  static ASG _generateErrorState(String className) {
    return ASG.CLASS(
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
    );
  }

  /// Generate initial state
  static ASG _generateInitialState(String className) {
    return ASG.CLASS(
      name: '${className}Initial',
      extendsClass: '${className}State',
      constructors: [
        ASG.CONSTRUCTOR(
          name: '${className}Initial',
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
    );
  }
}
