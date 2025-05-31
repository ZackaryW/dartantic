import 'package:test/test.dart';
import 'package:dartantic/asg/asg.dart';

void main() {
  group('ASG optimizeAssignments', () {
    test('removes duplicate assignments in same scope', () {
      final asg = ASG.fromLines([
        'var a = 1',
        'var b = 2',
        'var a = 1', // Should be removed
        'var c = 3',
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(asg.source, equals('var a = 1\nvar b = 2\nvar c = 3\n'));
    });

    test('keeps assignments in different scopes', () {
      final asg = ASG.fromLines([
        'var a = 1',
        'if (true) {',
        '  var a = 1', // Should be kept (different scope)
        '}',
        'var b = 2',
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(
        asg.source,
        equals('var a = 1\nif (true) {\n  var a = 1\n}\nvar b = 2\n'),
      );
    });

    test('handles nested scopes correctly', () {
      final asg = ASG.fromLines([
        'var a = 1',
        'if (true) {',
        '  var b = 2',
        '  if (false) {',
        '    var a = 1', // Should be kept (different scope)
        '    var b = 2', // Should be kept (different scope)
        '  }',
        '}',
        'var a = 1', // Should be removed (same scope as first)
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(
        asg.source,
        equals(
          'var a = 1\n'
          'if (true) {\n'
          '  var b = 2\n'
          '  if (false) {\n'
          '    var a = 1\n'
          '    var b = 2\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('handles complex assignments', () {
      final asg = ASG.fromLines([
        'var a = 1 + 2',
        'var b = "hello"',
        'var a = 1 + 2', // Should be removed
        'var c = a + b',
        'var d = 1 + 2', // Should be kept (different variable)
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = .+'));
      expect(
        asg.source,
        equals(
          'var a = 1 + 2\n'
          'var b = "hello"\n'
          'var c = a + b\n'
          'var d = 1 + 2\n',
        ),
      );
    });

    test('handles method scopes', () {
      final asg = ASG.fromLines([
        'void method1() {',
        '  var a = 1',
        '  var b = 2',
        '}',
        'void method2() {',
        '  var a = 1', // Should be kept (different method scope)
        '  var c = 3',
        '}',
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(
        asg.source,
        equals(
          'void method1() {\n'
          '  var a = 1\n'
          '  var b = 2\n'
          '}\n'
          'void method2() {\n'
          '  var a = 1\n'
          '  var c = 3\n'
          '}\n',
        ),
      );
    });

    test('handles class scopes', () {
      final asg = ASG.fromLines([
        'class A {',
        '  var a = 1',
        '  void method() {',
        '    var a = 1', // Should be kept (different scope)
        '  }',
        '}',
        'class B {',
        '  var a = 1', // Should be kept (different class scope)
        '}',
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(
        asg.source,
        equals(
          'class A {\n'
          '  var a = 1\n'
          '  void method() {\n'
          '    var a = 1\n'
          '  }\n'
          '}\n'
          'class B {\n'
          '  var a = 1\n'
          '}\n',
        ),
      );
    });

    test('handles try-catch blocks', () {
      final asg = ASG.fromLines([
        'try {',
        '  var a = 1',
        '  var b = 2',
        '} catch (e) {',
        '  var a = 1', // Should be kept (different scope)
        '  var c = 3',
        '}',
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(
        asg.source,
        equals(
          'try {\n'
          '  var a = 1\n'
          '  var b = 2\n'
          '} catch (e) {\n'
          '  var a = 1\n'
          '  var c = 3\n'
          '}\n',
        ),
      );
    });

    test('handles for loops', () {
      final asg = ASG.fromLines([
        'for (var i = 0; i < 10; i++) {',
        '  var a = 1',
        '  var b = 2',
        '}',
        'for (var j = 0; j < 5; j++) {',
        '  var a = 1', // Should be kept (different loop scope)
        '  var c = 3',
        '}',
      ]);

      asg.optimizeAssignments(RegExp(r'var \w+ = \d+'));
      expect(
        asg.source,
        equals(
          'for (var i = 0; i < 10; i++) {\n'
          '  var a = 1\n'
          '  var b = 2\n'
          '}\n'
          'for (var j = 0; j < 5; j++) {\n'
          '  var a = 1\n'
          '  var c = 3\n'
          '}\n',
        ),
      );
    });
  });
}
