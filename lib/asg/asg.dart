class ASG {
  /**
   * this class allows programmatically generate source code snippets
   * 
   */
  int indentCounter = 0;
  final StringBuffer buffer = StringBuffer();

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
      final line = lines[i];
      // Keep empty lines that are between non-empty lines
      if (line.trim().isEmpty) {
        if (i > 0 && i < lines.length - 1 && 
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

  static ASG WHILE({
    required String condition,
    ASG? body,
  }) {
    final newSa = ASG();
    newSa.advanceScope('while ($condition)', () {
      if (body != null) {
        newSa.add(body.source);
      }
    });
    return newSa;
  }

  static ASG DO_WHILE({
    required String condition,
    required ASG body,
  }) {
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

  static ASG METHOD({
    required String name,
    String? returnType,
    List<String>? parameters,
    ASG? body,
    bool isStatic = false,
    bool isAsync = false,
    bool isOverride = false,
  }) {
    final newSa = ASG();
    
    // Add override annotation on its own line if present
    if (isOverride) {
      newSa.addLine('@override');
    }

    final modifiers = [
      if (isStatic) 'static',
    ].where((m) => m.isNotEmpty).join(' ');

    final returnTypeStr = returnType ?? 'void';
    final paramsStr = parameters?.join(', ') ?? '';
    final asyncStr = isAsync ? 'async' : '';

    final methodHeader = [
      if (modifiers.isNotEmpty) modifiers,
      returnTypeStr,
      '$name($paramsStr)',
      if (asyncStr.isNotEmpty) asyncStr,
    ].where((s) => s.isNotEmpty).join(' ');

    newSa.advanceScope(methodHeader, () {
      if (body != null) {
        newSa.add(body.source);
      }
    });
    return newSa;
  }

  static ASG CLASS({
    required String name,
    String? extendsClass,
    List<String>? implementsList,
    List<String>? mixinsList,
    List<ASG>? fields,
    List<ASG>? constructors,
    List<ASG>? methods,
  }) {
    final newSa = ASG();
    
    // Build class declaration
    final declaration = [
      'class $name',
      if (extendsClass != null) 'extends $extendsClass',
      if (implementsList?.isNotEmpty ?? false) 'implements ${implementsList!.join(', ')}',
      if (mixinsList?.isNotEmpty ?? false) 'with ${mixinsList!.join(', ')}',
    ].where((s) => s.isNotEmpty).join(' ');

    newSa.advanceScope(declaration, () {
      // Add fields
      if (fields != null) {
        for (var i = 0; i < fields.length; i++) {
          newSa.add(fields[i].source);
        }
        if (constructors?.isNotEmpty == true || methods?.isNotEmpty == true) {
          newSa.addLine('');
        }
      }

      // Add constructors
      if (constructors != null) {
        for (var i = 0; i < constructors.length; i++) {
          newSa.add(constructors[i].source);
          // Add newline between constructors
          if (i < constructors.length - 1) {
            newSa.addLine('');
          }
        }
        if (methods?.isNotEmpty == true) {
          newSa.addLine('');
        }
      }

      // Add methods
      if (methods != null) {
        for (var i = 0; i < methods.length; i++) {
          newSa.add(methods[i].source);
        }
      }
    });
    return newSa;
  }

  static ASG CONSTRUCTOR({
    required String name,
    List<String>? parameters,
    List<String>? initializers,
    ASG? body,
    bool isConst = false,
    bool isFactory = false,
    bool isPrivate = false,
  }) {
    final newSa = ASG();
    final modifiers = [
      if (isConst) 'const',
      if (isFactory) 'factory',
    ].where((m) => m.isNotEmpty).join(' ');

    final paramsStr = parameters?.join(', ') ?? '';
    final initializersStr = initializers?.join(', ') ?? '';
    // For private constructors, use the name as is since it should already include ._internal
    final constructorName = name;

    newSa.advanceScope(
      '${modifiers.isNotEmpty ? '$modifiers ' : ''}$constructorName($paramsStr)${initializersStr.isNotEmpty ? ' : $initializersStr' : ''}',
      () {
        if (body != null) {
          newSa.add(body.source);
        }
      },
    );
    return newSa;
  }
}
