import 'package:test/test.dart';
import 'package:dartantic/asg/asg.dart';

void main() {
  group('ASG Class Generation', () {
    test('generates basic class', () {
      final result = ASG.CLASS(
        name: 'Person',
        fields: [
          ASG.FIELD(name: 'name', type: 'String', isFinal: true),
          ASG.FIELD(name: 'age', type: 'int', isFinal: true),
        ],
        constructors: [
          ASG.CONSTRUCTOR(
            name: 'Person',
            parameters: ['this.name', 'this.age'],
          ),
        ],
        methods: [
          ASG.METHOD(
            name: 'toString',
            returnType: 'String',
            isOverride: true,
            body: ASG.fromLines(['return "Person(name: \$name, age: \$age)";']),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Person {\n'
          '  final String name;\n'
          '  final int age;\n'
          '\n'
          '  Person(this.name, this.age) {\n'
          '  }\n'
          '\n'
          '  @override\n'
          '  String toString() {\n'
          '    return "Person(name: \$name, age: \$age)";\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with inheritance', () {
      final result = ASG.CLASS(
        name: 'Employee',
        extendsList: ['Person'],
        implementsList: ['Worker'],
        mixinsList: ['Loggable'],
        fields: [ASG.FIELD(name: 'salary', type: 'double', isFinal: true)],
        constructors: [
          ASG.CONSTRUCTOR(
            name: 'Employee',
            parameters: ['super.name', 'super.age', 'this.salary'],
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Employee extends Person implements Worker with Loggable {\n'
          '  final double salary;\n'
          '\n'
          '  Employee(super.name, super.age, this.salary) {\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with static members', () {
      final result = ASG.CLASS(
        name: 'MathUtils',
        fields: [
          ASG.FIELD(
            name: 'pi',
            type: 'double',
            initializer: '3.14159',
            isStatic: true,
            isFinal: true,
          ),
        ],
        methods: [
          ASG.METHOD(
            name: 'square',
            returnType: 'double',
            parameters: ['double x'],
            isStatic: true,
            body: ASG.fromLines(['return x * x;']),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class MathUtils {\n'
          '  static final double pi = 3.14159;\n'
          '\n'
          '  static double square(double x) {\n'
          '    return x * x;\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with async methods', () {
      final result = ASG.CLASS(
        name: 'DataService',
        methods: [
          ASG.METHOD(
            name: 'fetchData',
            returnType: 'Future<String>',
            isAsync: true,
            body: ASG.fromLines([
              'await Future.delayed(Duration(seconds: 1));',
              'return "data";',
            ]),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class DataService {\n'
          '  Future<String> fetchData() async {\n'
          '    await Future.delayed(Duration(seconds: 1));\n'
          '    return "data";\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with factory constructor', () {
      final result = ASG.CLASS(
        name: 'Singleton',
        fields: [
          ASG.FIELD(
            name: '_instance',
            type: 'Singleton',
            isStatic: true,
            isLate: true,
          ),
        ],
        constructors: [
          ASG.CONSTRUCTOR(name: 'Singleton._internal', isPrivate: true),
          ASG.CONSTRUCTOR(
            name: 'Singleton',
            isFactory: true,
            body: ASG.fromLines([
              'if (_instance == null) {',
              '  _instance = Singleton._internal();',
              '}',
              'return _instance!;',
            ]),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Singleton {\n'
          '  static late Singleton _instance;\n'
          '\n'
          '  _Singleton._internal() {\n'
          '  }\n'
          '\n'
          '  factory Singleton() {\n'
          '    if (_instance == null) {\n'
          '      _instance = Singleton._internal();\n'
          '    }\n'
          '    return _instance!;\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates singleton class with custom fields and methods', () {
      final result = ASG.SINGLETON(
        name: 'Database',
        implementsList: ['IDatabase'],
        fields: [
          ASG.FIELD(
            name: 'connection',
            type: 'Connection',
            isFinal: true,
            initializer: 'Connection()',
          ),
        ],
        methods: [
          ASG.METHOD(
            name: 'query',
            returnType: 'Future<Result>',
            parameters: ['String sql'],
            isAsync: true,
            body: ASG.fromLines(['return connection.execute(sql);']),
          ),
          ASG.METHOD(
            name: 'close',
            returnType: 'Future<void>',
            isAsync: true,
            body: ASG.fromLines(['await connection.dispose();']),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Database implements IDatabase {\n'
          '  static late Database _instance;\n'
          '  final Connection connection = Connection();\n'
          '\n'
          '  _Database._internal();\n'
          '\n'
          '  factory Database() {\n'
          '    if (_instance == null) {\n'
          '      _instance = Database._internal();\n'
          '    }\n'
          '    return _instance!;\n'
          '  }\n'
          '\n'
          '  Future<Result> query(String sql) async {\n'
          '    return connection.execute(sql);\n'
          '  }\n'
          '  Future<void> close() async {\n'
          '    await connection.dispose();\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates singleton class with custom instance name', () {
      final result = ASG.SINGLETON(
        name: 'Logger',
        instanceName: '_logger',
        mixinsList: ['Timestamps'],
        methods: [
          ASG.METHOD(
            name: 'log',
            returnType: 'void',
            parameters: ['String message'],
            body: ASG.fromLines([r'print("[${DateTime.now()}] $message");']),
          ),
        ],
      );

      expect(
        result.source,
        equals(r'''class Logger with Timestamps {
  static late Logger _logger;

  _Logger._internal();

  factory Logger() {
    if (_logger == null) {
      _logger = Logger._internal();
    }
    return _logger!;
  }

  void log(String message) {
    print("[${DateTime.now()}] $message");
  }
}
'''),
      );
    });
  });
}
