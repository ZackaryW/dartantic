import 'package:test/test.dart';
import 'package:dartantic/asg/asg.dart';

void main() {
  group('ASG IF clause tests', () {
    test('basic if-else flow', () {
      // This test demonstrates the basic if-else pattern
      // if (x > 0) { ... } else { ... }
      final result = ASG.IF(
        condition: 'x > 0',
        then: ASG.fromLines(['return "positive";']),
        elseIfs: [],
        elseClause: ASG.fromLines(['return "non-positive";']),
      );

      expect(
        result.source,
        equals(
          'if (x > 0) {\n'
          '  return "positive";\n'
          '}\n'
          'else {\n'
          '  return "non-positive";\n'
          '}\n',
        ),
      );
    });

    test('nested if-else flow', () {
      // This test demonstrates nested if-else patterns
      // if (x > 0) { if (y > 0) { ... } else { ... } } else { ... }
      final nestedIf = ASG.IF(
        condition: 'y > 0',
        then: ASG.fromLines(['return "both positive";']),
        elseClause: ASG.fromLines(['return "x positive, y non-positive";']),
      );

      final result = ASG.IF(
        condition: 'x > 0',
        then: nestedIf,
        elseClause: ASG.fromLines(['return "x non-positive";']),
      );

      expect(
        result.source,
        equals(
          'if (x > 0) {\n'
          '  if (y > 0) {\n'
          '    return "both positive";\n'
          '  }\n'
          '  else {\n'
          '    return "x positive, y non-positive";\n'
          '  }\n'
          '}\n'
          'else {\n'
          '  return "x non-positive";\n'
          '}\n',
        ),
      );
    });

    test('if-elseif-else flow', () {
      // This test demonstrates a complete if-elseif-else flow
      // if (x > 0) { ... } else if (x < 0) { ... } else if (x == 0) { ... } else { ... }
      final result = ASG.IF(
        condition: 'x > 0',
        then: ASG.fromLines(['return "positive";']),
        elseIfs: [
          ASG.fromLines(['x < 0', 'return "negative";']),
          ASG.fromLines(['x == 0', 'return "zero";']),
        ],
        elseClause: ASG.fromLines(['return "not a number";']),
      );

      expect(
        result.source,
        equals(
          'if (x > 0) {\n'
          '  return "positive";\n'
          '}\n'
          'else if (x < 0) {\n'
          '  return "negative";\n'
          '}\n'
          'else if (x == 0) {\n'
          '  return "zero";\n'
          '}\n'
          'else {\n'
          '  return "not a number";\n'
          '}\n',
        ),
      );
    });

    test('complex validation flow', () {
      // This test demonstrates a more complex validation flow
      // if (isValid) { if (hasPermission) { ... } else { ... } } else { ... }
      final permissionCheck = ASG.IF(
        condition: 'hasPermission',
        then: ASG.fromLines([
          'if (isAdmin) {',
          '  return "admin access";',
          '}',
          'return "user access";',
        ]),
        elseClause: ASG.fromLines(['return "access denied";']),
      );

      final result = ASG.IF(
        condition: 'isValid',
        then: permissionCheck,
        elseIfs: [],
        elseClause: ASG.fromLines(['return "invalid input";']),
      );

      expect(
        result.source,
        equals(
          'if (isValid) {\n'
          '  if (hasPermission) {\n'
          '    if (isAdmin) {\n'
          '      return "admin access";\n'
          '    }\n'
          '    return "user access";\n'
          '  }\n'
          '  else {\n'
          '    return "access denied";\n'
          '  }\n'
          '}\n'
          'else {\n'
          '  return "invalid input";\n'
          '}\n',
        ),
      );
    });

    test('empty flow', () {
      // This test demonstrates handling of empty conditions
      final result = ASG.IF(condition: 'x > 0');
      expect(result.source, equals('if (x > 0) {\n}\n'));
    });
  });
}
