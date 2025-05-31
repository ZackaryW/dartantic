// Helper extension to count occurrences of a substring
extension StringCount on String {
  int count(String substring) {
    return split(substring).length - 1;
  }
}

class ASG {
  /**
   * this class allows programmatically generate source code snippets
   * 
   */
  int indentCounter = 0;
  final StringBuffer buffer = StringBuffer();

  void optimizeAssignments(RegExp regex) {
    // Split the buffer into lines
    final lines = buffer.toString().split('\n');
    final optimizedLines = <String>[];
    final seenAssignments = <String>[];
    for (final line in lines) {
      // Check if it's an assignment (contains '=' but not '==' or '!=')
      if (line.contains('=') && !line.contains('==') && !line.contains('!=')) {
        // Check if the line matches the regex
        if (regex.hasMatch(line)) {
          // Extract the assignment part (everything after the '=')
          final assignment = line.substring(line.indexOf('=')).trim();

          // Find the last seen assignment in the same scope
          var shouldKeep = true;
          for (var i = seenAssignments.length - 1; i >= 0; i--) {
            final prevAssignment = seenAssignments[i];
            if (prevAssignment == assignment) {
              shouldKeep = false;
              break;
            }
            // Stop looking if we hit a scope boundary
            if (prevAssignment == 'SCOPE_BOUNDARY') {
              break;
            }
          }

          if (shouldKeep) {
            seenAssignments.add(assignment);
            optimizedLines.add(line);
          }
          continue;
        }
      }

      // Add scope boundaries
      if (line.contains('{')) {
        seenAssignments.add('SCOPE_BOUNDARY');
      }

      // Keep non-assignment lines
      optimizedLines.add(line);
    }

    // Clear the buffer and add the optimized lines
    buffer.clear();
    for (final line in optimizedLines) {
      if (line.isNotEmpty) {
        buffer.writeln(line);
      }
    }
  }

  void add(String code) {
    if (code.contains('\n')) {
      // If the code contains newlines, split and add each line with proper indentation
      final lines = code.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          addLine(line);
        }
      }
    } else {
      // For single-line code, just write it without newline
      buffer.write(code);
    }
  }

  void addLine(String code) {
    buffer.writeln("${'  ' * indentCounter}$code");
  }

  String get source {
    final raw = buffer.toString();
    // Split into lines and normalize
    final lines = raw.split('\n');
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      // Handle escaped newlines
      if (line.endsWith('\\n')) {
        line = line.substring(0, line.length - 2);
        result.add(line);
        continue;
      }
      // Keep empty lines that are between non-empty lines
      if (line.trim().isEmpty) {
        if (i > 0 &&
            i < lines.length - 1 &&
            lines[i - 1].trim().isNotEmpty &&
            lines[i + 1].trim().isNotEmpty) {
          result.add('');
        }
        continue;
      }
      result.add(line);
    }

    // Join with newlines and ensure trailing newline
    return result.join('\n') + '\n';
  }

  void advanceScope(String openLine, void Function() scopeContent) {
    addLine('$openLine {');
    indentCounter++;
    scopeContent();
    indentCounter--;
    addLine('}');
  }

  static String mapValue(String varname, String key) {
    return '$varname[\'$key\']';
  }

  static String mapValueWithDefault(
    String varname,
    String key,
    String defaultValue,
  ) {
    return '$varname[\'$key\'] ?? $defaultValue';
  }

  static ASG merge(List<dynamic> asgs) {
    final newSa = ASG();
    for (final asg in asgs) {
      if (asg is ASG) {
        newSa.add(asg.source);
      } else if (asg is String) {
        newSa.add(asg);
      }
    }
    return newSa;
  }

  static ASG IF({
    required String condition,
    ASG? then,
    List<ASG>? elseIfs,
    ASG? elseClause,
  }) {
    final newSa = ASG();
    newSa.advanceScope('if ($condition)', () {
      if (then != null) {
        // Split the source into lines and add each line with proper indentation
        final lines = then.source.split('\n');
        for (final line in lines) {
          if (line.isNotEmpty) {
            newSa.addLine(line);
          }
        }
      }
    });

    if (elseIfs != null) {
      for (final elseIf in elseIfs) {
        // Extract condition from the first line
        final condition = elseIf.source.split('\n')[0];
        newSa.advanceScope('else if ($condition)', () {
          // Add the rest of the lines with proper indentation
          final lines = elseIf.source.split('\n').skip(1);
          for (final line in lines) {
            if (line.isNotEmpty) {
              newSa.addLine(line);
            }
          }
        });
      }
    }

    if (elseClause != null) {
      newSa.advanceScope('else', () {
        // Split the source into lines and add each line with proper indentation
        final lines = elseClause.source.split('\n');
        for (final line in lines) {
          if (line.isNotEmpty) {
            newSa.addLine(line);
          }
        }
      });
    }
    return newSa;
  }

  static ASG throwException({
    required String message,
    String exceptionType = 'Exception',
  }) {
    final newSa = ASG();
    newSa.addLine('throw $exceptionType("$message");');
    return newSa;
  }

  static ASG tryCatch({
    required ASG tryBlock,
    ASG? catchBlock,
    ASG? finallyBlock,
  }) {
    final newSa = ASG();
    newSa.advanceScope('try', () {
      newSa.add(tryBlock.source);
    });

    if (catchBlock != null) {
      newSa.advanceScope('catch (e)', () {
        newSa.add(catchBlock.source);
      });
    }

    if (finallyBlock != null) {
      newSa.advanceScope('finally', () {
        newSa.add(finallyBlock.source);
      });
    }
    return newSa;
  }

  // SECTION: create
  static ASG fromLines(List<String> lines) {
    final newSa = ASG();
    for (final line in lines) {
      newSa.addLine(line);
    }
    return newSa;
  }

  static String assignVar(
    String varname,
    String? value, {
    bool isFinal = false,
  }) {
    if (value == null) {
      return '${isFinal ? 'final ' : ''}$varname = null;';
    } else {
      return '${isFinal ? 'final ' : ''}$varname = $value;';
    }
  }

  static ASG FOR({
    String? initialization,
    String? condition,
    String? increment,
    ASG? body,
  }) {
    final newSa = ASG();
    final loopHeader = [
      if (initialization != null) initialization,
      if (condition != null) condition,
      if (increment != null) increment,
    ].join('; ');

    newSa.advanceScope('for ($loopHeader)', () {
      if (body != null) {
        newSa.add(body.source);
      }
    });
    return newSa;
  }

  static ASG FOR_IN({
    required String variable,
    required String iterable,
    ASG? body,
  }) {
    final newSa = ASG();
    newSa.advanceScope('for (final $variable in $iterable)', () {
      if (body != null) {
        newSa.add(body.source);
      }
    });
    return newSa;
  }

  static ASG WHILE({required String condition, ASG? body}) {
    final newSa = ASG();
    newSa.advanceScope('while ($condition)', () {
      if (body != null) {
        newSa.add(body.source);
      }
    });
    return newSa;
  }

  static ASG DO_WHILE({required String condition, required ASG body}) {
    final newSa = ASG();
    newSa.advanceScope('do', () {
      newSa.add(body.source);
    });
    newSa.addLine('while ($condition);');
    return newSa;
  }

  static ASG FIELD({
    required String name,
    required String type,
    String? initializer,
    bool isFinal = false,
    bool isStatic = false,
    bool isLate = false,
  }) {
    final modifiers = [
      if (isStatic) 'static',
      if (isLate) 'late',
      if (isFinal) 'final',
    ].where((m) => m.isNotEmpty).join(' ');

    final declaration = [
      if (modifiers.isNotEmpty) modifiers,
      '$type $name',
      if (initializer != null) '= $initializer',
    ].join(' ');

    return ASG.fromLines(['$declaration;']);
  }

  /// Generate a Dart getter
  static ASG GETTER({
    required String name,
    required String returnType,
    required ASG body,
    bool isOverride = false,
    bool isStatic = false,
  }) {
    final newSa = ASG();
    if (isOverride) newSa.addLine('@override');
    final staticStr = isStatic ? 'static ' : '';
    newSa.advanceScope('$staticStr$returnType get $name', () {
      newSa.add(body.source);
    });
    return newSa;
  }

  /// Generate a Dart setter
  static ASG SETTER({
    required String name,
    required String paramType,
    required String paramName,
    required ASG body,
    bool isOverride = false,
    bool isStatic = false,
  }) {
    final newSa = ASG();
    if (isOverride) newSa.addLine('@override');
    final staticStr = isStatic ? 'static ' : '';
    newSa.advanceScope('$staticStr set $name($paramType $paramName)', () {
      newSa.add(body.source);
    });
    return newSa;
  }

  /// Generate a Dart method, getter, or setter
  static ASG METHOD({
    required String name,
    String? returnType,
    List<String>? parameters,
    ASG? body,
    bool isStatic = false,
    bool isAsync = false,
    bool isOverride = false,
    bool isGetter = false,
    bool isSetter = false,
    String? setterParamType,
    String? setterParamName,
  }) {
    final newSa = ASG();
    if (isOverride) newSa.addLine('@override');
    final modifiers = [
      if (isStatic) 'static',
    ].where((m) => m.isNotEmpty).join(' ');
    final returnTypeStr = returnType ?? 'void';
    final asyncStr = isAsync ? 'async' : '';
    String methodHeader;
    if (isGetter) {
      methodHeader = [
        if (modifiers.isNotEmpty) modifiers,
        returnTypeStr,
        'get $name',
        if (asyncStr.isNotEmpty) asyncStr,
      ].where((s) => s.isNotEmpty).join(' ');
    } else if (isSetter) {
      final paramType = setterParamType ?? 'dynamic';
      final paramName = setterParamName ?? 'value';
      methodHeader = [
        if (modifiers.isNotEmpty) modifiers,
        'set $name($paramType $paramName)',
        if (asyncStr.isNotEmpty) asyncStr,
      ].where((s) => s.isNotEmpty).join(' ');
    } else {
      final paramsStr = parameters?.join(', ') ?? '';
      methodHeader = [
        if (modifiers.isNotEmpty) modifiers,
        returnTypeStr,
        '$name($paramsStr)',
        if (asyncStr.isNotEmpty) asyncStr,
      ].where((s) => s.isNotEmpty).join(' ');
    }
    newSa.advanceScope(methodHeader, () {
      if (body != null) {
        newSa.add(body.source);
      }
    });
    return newSa;
  }

  /// Generate a Dart constructor.
  /// For const constructors with initializers, emits a body block { }.
  /// For const constructors without initializers, emits a semicolon.
  /// For non-const constructors, emits a body block if body is provided or noBody is false.
  static ASG CONSTRUCTOR({
    required String name,
    List<String> parameters = const [],
    List<String> initializers = const [],
    bool isConst = false,
    bool isFactory = false,
    bool isPrivate = false,
    bool noBody = false,
    ASG? body,
  }) {
    final asg = ASG();

    // Split the name into class name and constructor name
    final parts = name.split('.');
    final className = parts[0];
    final constructorName = parts.length > 1 ? parts[1] : '';

    // Build the prefix with proper privacy handling
    final prefix = [
      if (isFactory) 'factory ',
      if (isConst) 'const ',
      if (isPrivate) '_$className' else className,
      if (constructorName.isNotEmpty) '.$constructorName',
    ].join('');

    // Build constructor header
    final header = [
      prefix,
      '(',
      parameters.join(', '),
      ')',
      if (initializers.isNotEmpty) ' : ${initializers.join(', ')}',
    ].join('');

    // Handle different constructor cases
    if (isConst) {
      if (initializers.isNotEmpty) {
        // Const constructor with initializers gets a body block
        asg.addLine('$header {');
        asg.addLine('}');
      } else {
        // Const constructor without initializers gets a semicolon
        asg.addLine('$header;');
      }
    } else if (body != null || !noBody) {
      // Non-const constructor with body or noBody=false gets a body block
      asg.addLine('$header {');
      if (body != null) {
        asg.indentCounter++;
        asg.add(body.source);
        asg.indentCounter--;
      }
      asg.addLine('}');
    } else {
      // Non-const constructor with noBody=true gets a semicolon
      asg.addLine('$header;');
    }

    return asg;
  }

  /// Generate a class definition
  static ASG CLASS({
    required String name,
    List<Object>? extendsList,
    List<Object>? implementsList,
    List<Object>? mixinsList,
    List<ASG>? fields,
    List<ASG>? constructors,
    List<ASG>? methods,
    bool isAbstract = false,
  }) {
    final asg = ASG();
    final abstractStr = isAbstract ? 'abstract ' : '';
    final extendsStr =
        extendsList?.isNotEmpty == true
            ? ' extends ${extendsList!.map((e) => e is ASG ? e.source : e).join(', ')}'
            : '';
    final implementsStr =
        implementsList?.isNotEmpty == true
            ? ' implements ${implementsList!.map((e) => e is ASG ? e.source : e).join(', ')}'
            : '';
    final mixinsStr =
        mixinsList?.isNotEmpty == true
            ? ' with ${mixinsList!.map((e) => e is ASG ? e.source : e).join(', ')}'
            : '';

    asg.addLine(
      '${abstractStr}class $name$extendsStr$implementsStr$mixinsStr {',
    );
    asg.indentCounter++;
    final hasFields = fields?.isNotEmpty == true;
    final hasConstructors = constructors?.isNotEmpty == true;
    final hasMethods = methods?.isNotEmpty == true;
    if (hasFields) {
      for (final field in fields!) {
        asg.add(field.source);
      }
      if (hasConstructors || hasMethods) {
        asg.addLine(''); // Blank line after fields if constructors or methods
      }
    }
    if (hasConstructors) {
      for (var i = 0; i < constructors!.length; i++) {
        asg.add(constructors[i].source);
        if (i < constructors.length - 1) {
          asg.addLine(''); // Blank line between constructors
        }
      }
      if (hasMethods) {
        asg.addLine(''); // Blank line after constructors if methods
      }
    }
    if (hasMethods) {
      for (var i = 0; i < methods!.length; i++) {
        asg.add(methods[i].source);
        // Do NOT add blank lines between methods
      }
    }
    asg.indentCounter--;
    asg.addLine('}');
    return asg;
  }

  /// Generate a singleton class with standard pattern:
  /// - Private constructor
  /// - Static late instance
  /// - Factory constructor that returns the instance
  static ASG SINGLETON({
    required String name,
    List<String>? implementsList,
    List<String>? mixinsList,
    List<ASG>? fields,
    List<ASG>? methods,
    String? instanceName,
  }) {
    final instanceFieldName = instanceName ?? '_instance';

    return ASG.CLASS(
      name: name,
      implementsList: implementsList,
      mixinsList: mixinsList,
      fields: [
        // Add static late instance field
        ASG.FIELD(
          name: instanceFieldName,
          type: name,
          isStatic: true,
          isLate: true,
        ),
        // Add any additional fields
        if (fields != null) ...fields,
      ],
      constructors: [
        // Private constructor
        ASG.CONSTRUCTOR(name: '$name._internal', isPrivate: true, noBody: true),
        // Factory constructor
        ASG.CONSTRUCTOR(
          name: name,
          isFactory: true,
          body: ASG.fromLines([
            'if ($instanceFieldName == null) {',
            '  $instanceFieldName = $name._internal();',
            '}',
            'return $instanceFieldName!;',
          ]),
        ),
      ],
      methods: methods,
    );
  }

  static ASG PARAMETER({
    required String name,
    required String type,
    bool isNamed = false,
    bool isRequired = false,
    String? defaultValue,
  }) {
    final asg = ASG();
    final namedStr = isNamed ? 'required ' : '';
    final defaultValueStr = defaultValue != null ? ' = $defaultValue' : '';
    asg.addLine('${namedStr}${type} ${name}${defaultValueStr}');
    return asg;
  }

  void generateClass(
    String name, {
    String? extends_,
    List<String>? implements_,
    List<String>? with_,
    List<String>? fields,
    List<String>? constructors,
    List<String>? methods,
  }) {
    // Add class declaration
    final extendsStr = extends_ != null ? ' extends $extends_' : '';
    final implementsStr =
        implements_?.isNotEmpty == true
            ? ' implements ${implements_!.join(', ')}'
            : '';
    final withStr =
        with_?.isNotEmpty == true ? ' with ${with_!.join(', ')}' : '';

    addLine('class $name$extendsStr$implementsStr$withStr {');
    indentCounter++;

    // Add fields with proper spacing
    if (fields?.isNotEmpty == true) {
      for (var field in fields!) {
        addLine(field);
      }
      addLine(''); // Add newline after fields
    }

    // Add constructors with proper spacing
    if (constructors?.isNotEmpty == true) {
      for (var i = 0; i < constructors!.length; i++) {
        addLine(constructors[i]);
        if (i < constructors.length - 1) {
          addLine(''); // Add newline between constructors
        }
      }
      if (methods?.isNotEmpty == true) {
        addLine(''); // Add newline after constructors if there are methods
      }
    }

    // Add methods with proper spacing
    if (methods?.isNotEmpty == true) {
      for (var i = 0; i < methods!.length; i++) {
        addLine(methods[i]);
        if (i < methods.length - 1) {
          addLine(''); // Add newline between methods
        }
      }
    }

    indentCounter--;
    addLine('}');
  }
}
