import 'package:test/test.dart';
import 'package:dartantic/asg/asg.dart';

void main() {
  group('ASG Basic Operations', () {
    test('add and addLine handle indentation correctly', () {
      final asg = ASG();
      asg.add('inline code');
      asg.addLine('new line');
      asg.indentCounter++;
      asg.addLine('indented line');
      asg.indentCounter--;
      asg.addLine('back to normal');

      expect(
        asg.source,
        equals(
          'inline codenew line\n'
          '  indented line\n'
          'back to normal\n',
        ),
      );
    });

    test('fromLines creates ASG with multiple lines', () {
      final result = ASG.fromLines(['line 1', 'line 2', 'line 3']);

      expect(
        result.source,
        equals(
          'line 1\n'
          'line 2\n'
          'line 3\n',
        ),
      );
    });
  });

  group('ASG Map Operations', () {
    test('mapValue generates correct map access', () {
      expect(ASG.mapValue('myMap', 'key'), equals("myMap['key']"));
    });

    test('mapValueWithDefault handles null values', () {
      expect(
        ASG.mapValueWithDefault('myMap', 'key', 'default'),
        equals("myMap['key'] ?? default"),
      );
    });
  });

  group('ASG Exception Handling', () {
    test('throwException generates basic exception', () {
      final result = ASG.throwException(message: 'Something went wrong');

      expect(
        result.source,
        equals('throw Exception("Something went wrong");\n'),
      );
    });

    test('throwException with custom exception type', () {
      final result = ASG.throwException(
        message: 'Invalid input',
        exceptionType: 'ValidationError',
      );

      expect(
        result.source,
        equals('throw ValidationError("Invalid input");\n'),
      );
    });

    test('tryCatch generates basic try-catch block', () {
      final result = ASG.tryCatch(
        tryBlock: ASG.fromLines(['doSomething();']),
        catchBlock: ASG.fromLines(['handleError(e);']),
      );

      expect(
        result.source,
        equals(
          'try {\n'
          '  doSomething();\n'
          '}\n'
          'catch (e) {\n'
          '  handleError(e);\n'
          '}\n',
        ),
      );
    });

    test('tryCatch with finally block', () {
      final result = ASG.tryCatch(
        tryBlock: ASG.fromLines(['doSomething();']),
        catchBlock: ASG.fromLines(['handleError(e);']),
        finallyBlock: ASG.fromLines(['cleanup();']),
      );

      expect(
        result.source,
        equals(
          'try {\n'
          '  doSomething();\n'
          '}\n'
          'catch (e) {\n'
          '  handleError(e);\n'
          '}\n'
          'finally {\n'
          '  cleanup();\n'
          '}\n',
        ),
      );
    });

    test('tryCatch with only try and finally', () {
      final result = ASG.tryCatch(
        tryBlock: ASG.fromLines(['doSomething();']),
        finallyBlock: ASG.fromLines(['cleanup();']),
      );

      expect(
        result.source,
        equals(
          'try {\n'
          '  doSomething();\n'
          '}\n'
          'finally {\n'
          '  cleanup();\n'
          '}\n',
        ),
      );
    });
  });

  group('ASG Variable Operations', () {
    test('assignVar creates basic variable assignment', () {
      expect(ASG.assignVar('myVar', '42'), equals('myVar = 42;'));
    });

    test('assignVar creates final variable', () {
      expect(
        ASG.assignVar('myVar', '42', isFinal: true),
        equals('final myVar = 42;'),
      );
    });

    test('assignVar handles null values', () {
      expect(ASG.assignVar('myVar', null), equals('myVar = null;'));
    });

    test('assignVar handles null values with final', () {
      expect(
        ASG.assignVar('myVar', null, isFinal: true),
        equals('final myVar = null;'),
      );
    });
  });

  group('ASG Loop Operations', () {
    test('FOR generates basic for loop', () {
      final result = ASG.FOR(
        initialization: 'int i = 0',
        condition: 'i < 10',
        increment: 'i++',
        body: ASG.fromLines(['print(i);']),
      );

      expect(
        result.source,
        equals(
          'for (int i = 0; i < 10; i++) {\n'
          '  print(i);\n'
          '}\n',
        ),
      );
    });

    test('FOR_IN generates for-in loop', () {
      final result = ASG.FOR_IN(
        variable: 'item',
        iterable: 'items',
        body: ASG.fromLines(['print(item);']),
      );

      expect(
        result.source,
        equals(
          'for (final item in items) {\n'
          '  print(item);\n'
          '}\n',
        ),
      );
    });

    test('WHILE generates while loop', () {
      final result = ASG.WHILE(
        condition: 'i < 10',
        body: ASG.fromLines(['print(i);', 'i++;']),
      );

      expect(
        result.source,
        equals(
          'while (i < 10) {\n'
          '  print(i);\n'
          '  i++;\n'
          '}\n',
        ),
      );
    });

    test('DO_WHILE generates do-while loop', () {
      final result = ASG.DO_WHILE(
        condition: 'i < 10',
        body: ASG.fromLines(['print(i);', 'i++;']),
      );

      expect(
        result.source,
        equals(
          'do {\n'
          '  print(i);\n'
          '  i++;\n'
          '}\n'
          'while (i < 10);\n',
        ),
      );
    });

    test('FOR with partial parameters', () {
      final result = ASG.FOR(
        initialization: 'int i = 0',
        condition: 'i < 10',
        body: ASG.fromLines(['print(i);']),
      );

      expect(
        result.source,
        equals(
          'for (int i = 0; i < 10) {\n'
          '  print(i);\n'
          '}\n',
        ),
      );
    });

    test('nested loops', () {
      final innerLoop = ASG.FOR(
        initialization: 'int j = 0',
        condition: 'j < 5',
        increment: 'j++',
        body: ASG.fromLines(['print("\$i-\$j");']),
      );

      final result = ASG.FOR(
        initialization: 'int i = 0',
        condition: 'i < 3',
        increment: 'i++',
        body: innerLoop,
      );

      expect(
        result.source,
        equals(
          'for (int i = 0; i < 3; i++) {\n'
          '  for (int j = 0; j < 5; j++) {\n'
          '    print("\$i-\$j");\n'
          '  }\n'
          '}\n',
        ),
      );
    });
  });
}
