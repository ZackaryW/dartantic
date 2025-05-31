import 'package:analyzer/dart/element/element.dart';
import 'package:dartantic/asg/asg.dart';
import '../utils/metadata_parser.dart';
import '../utils/bloc_utils.dart';

class BlocEventGenerator {
  static ASG generate(ClassElement element, ParsedModelMeta metadata) {
    final className = element.name;
    final asg = ASG();

    // Generate base event class
    asg.add(_generateBaseEvent(className).source);
    asg.addLine('');

    // Generate field update events
    for (final field in metadata.fields.values) {
      asg.add(_generateFieldUpdateEvent(className, field).source);
      asg.addLine('');
    }

    // Generate common events
    asg.add(_generateLoadEvent(className).source);
    asg.addLine('');
    asg.add(_generateSaveEvent(className).source);
    asg.addLine('');
    asg.add(_generateResetEvent(className).source);
    asg.addLine('');
    asg.add(_generateValidateEvent(className).source);

    return asg;
  }

  /// Generate abstract base event class
  static ASG _generateBaseEvent(String className) {
    final asg = ASG();
    asg.addLine('abstract class ${className}Event extends Equatable {');
    asg.indentCounter++;

    // Add const constructor
    asg.add(
      ASG
          .CONSTRUCTOR(name: '${className}Event', isConst: true, noBody: true)
          .source,
    );
    asg.addLine('');

    asg.add(
      ASG
          .GETTER(
            name: 'props',
            returnType: 'List<Object?>',
            isOverride: true,
            body: ASG.fromLines(['return [];']),
          )
          .source,
    );
    asg.indentCounter--;
    asg.addLine('}');
    return asg;
  }

  /// Generate field update event
  static ASG _generateFieldUpdateEvent(
    String className,
    ParsedFieldMeta field,
  ) {
    final eventName = 'Update${_capitalize(field.name)}';

    return ASG.CLASS(
      name: '${className}$eventName',
      extendsClass: '${className}Event',
      fields: [ASG.FIELD(name: field.name, type: field.type, isFinal: true)],
      constructors: [
        ASG.CONSTRUCTOR(
          name: '${className}$eventName',
          parameters: ['this.${field.name}'],
          isConst: true,
          noBody: true,
        ),
      ],
      methods: [
        ASG.GETTER(
          name: 'props',
          returnType: 'List<Object?>',
          isOverride: true,
          body: ASG.fromLines(['return [${field.name}];']),
        ),
      ],
    );
  }

  /// Generate load event
  static ASG _generateLoadEvent(String className) {
    return ASG.CLASS(
      name: '${className}Load',
      extendsClass: '${className}Event',
      fields: [
        ASG.FIELD(name: 'data', type: 'Map<String, dynamic>?', isFinal: true),
      ],
      constructors: [
        ASG.CONSTRUCTOR(
          name: '${className}Load',
          parameters: ['[this.data]'],
          isConst: true,
          noBody: true,
        ),
      ],
      methods: [
        ASG.GETTER(
          name: 'props',
          returnType: 'List<Object?>',
          isOverride: true,
          body: ASG.fromLines(['return [data];']),
        ),
      ],
    );
  }

  /// Generate save event
  static ASG _generateSaveEvent(String className) {
    return ASG.CLASS(
      name: '${className}Save',
      extendsClass: '${className}Event',
      constructors: [
        ASG.CONSTRUCTOR(name: '${className}Save', isConst: true, noBody: true),
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

  /// Generate reset event
  static ASG _generateResetEvent(String className) {
    return ASG.CLASS(
      name: '${className}Reset',
      extendsClass: '${className}Event',
      constructors: [
        ASG.CONSTRUCTOR(name: '${className}Reset', isConst: true, noBody: true),
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

  /// Generate validate event
  static ASG _generateValidateEvent(String className) {
    return ASG.CLASS(
      name: '${className}Validate',
      extendsClass: '${className}Event',
      constructors: [
        ASG.CONSTRUCTOR(
          name: '${className}Validate',
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

  /// Capitalize first letter
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
