# ASG (Abstract Syntax Generator) Tests

This directory contains tests for the ASG library, which provides a fluent interface for generating Dart code.

## Test Groups

### Basic Operations
Tests for fundamental ASG operations like adding code, handling indentation, and creating from lines.

### Map Operations
Tests for map-related operations like accessing map values and handling default values.

### Exception Handling
Tests for generating exception-related code:
- Basic exception throwing
- Try-catch blocks
- Try-catch-finally blocks
- Custom exception types

### Variable Operations
Tests for variable-related operations:
- Variable assignment
- Final variables
- Null handling

### Loop Operations
Tests for generating various types of loops:
- Basic for loops
- For-in loops
- While loops
- Do-while loops
- Nested loops
- Partial loop parameters

### Class Generation
Tests for generating class definitions:
- Basic class with fields and methods
- Class with inheritance and interfaces
- Class with static members
- Class with async methods
- Class with factory constructor (Singleton pattern)

## Examples

### Basic Operations
```dart
final asg = ASG();
asg.add('inline code');
asg.addLine('new line');
asg.addLine('  indented line');
asg.add('back to normal');
```

### Map Operations
```dart
// Basic map access
ASG.mapValue('user', 'name')  // user['name']

// Map access with default value
ASG.mapValueWithDefault('config', 'timeout', '30')  // config['timeout'] ?? 30
```

### Exception Handling
```dart
// Basic exception
ASG.throwException('Something went wrong')
// Output: throw Exception("Something went wrong");

// Try-catch block
ASG.tryCatch(
  tryBlock: ASG.fromLines(['doSomething();']),
  catchBlock: ASG.fromLines(['handleError(e);']),
)
// Output:
// try {
//   doSomething();
// }
// catch (e) {
//   handleError(e);
// }
```

### Variable Operations
```dart
// Basic assignment
ASG.assignVar('name', 'John')  // name = John;

// Final variable
ASG.assignVar('count', '0', isFinal: true)  // final count = 0;

// Null assignment
ASG.assignVar('value', null)  // value = null;
```

### Loop Operations
```dart
// Basic for loop
ASG.FOR(
  initialization: 'int i = 0',
  condition: 'i < 10',
  increment: 'i++',
  body: ASG.fromLines(['print(i);']),
)
// Output:
// for (int i = 0; i < 10; i++) {
//   print(i);
// }

// For-in loop
ASG.FOR_IN(
  variable: 'item',
  iterable: 'items',
  body: ASG.fromLines(['print(item);']),
)
// Output:
// for (final item in items) {
//   print(item);
// }

// While loop
ASG.WHILE(
  condition: 'i < 10',
  body: ASG.fromLines([
    'print(i);',
    'i++;',
  ]),
)
// Output:
// while (i < 10) {
//   print(i);
//   i++;
// }

// Do-while loop
ASG.DO_WHILE(
  condition: 'i < 10',
  body: ASG.fromLines([
    'print(i);',
    'i++;',
  ]),
)
// Output:
// do {
//   print(i);
//   i++;
// }
// while (i < 10);

// Nested loops
ASG.FOR(
  initialization: 'int i = 0',
  condition: 'i < 3',
  increment: 'i++',
  body: ASG.FOR(
    initialization: 'int j = 0',
    condition: 'j < 5',
    increment: 'j++',
    body: ASG.fromLines(['print("\$i-\$j");']),
  ),
)
// Output:
// for (int i = 0; i < 3; i++) {
//   for (int j = 0; j < 5; j++) {
//     print("$i-$j");
//   }
// }
```

### Class Generation
```dart
// Basic class
ASG.CLASS(
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
)
// Output:
// class Person {
//   final String name;
//   final int age;
//
//   Person(this.name, this.age) {
//   }
//
//   @override
//   String toString() {
//     return "Person(name: $name, age: $age)";
//   }
// }

// Class with inheritance
ASG.CLASS(
  name: 'Employee',
  extendsClass: 'Person',
  implementsList: ['Worker'],
  mixinsList: ['Loggable'],
  fields: [
    ASG.FIELD(name: 'salary', type: 'double', isFinal: true),
  ],
  constructors: [
    ASG.CONSTRUCTOR(
      name: 'Employee',
      parameters: ['super.name', 'super.age', 'this.salary'],
    ),
  ],
)
// Output:
// class Employee extends Person implements Worker with Loggable {
//   final double salary;
//
//   Employee(super.name, super.age, this.salary) {
//   }
// }

// Class with static members
ASG.CLASS(
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
)
// Output:
// class MathUtils {
//   static final double pi = 3.14159;
//
//   static double square(double x) {
//     return x * x;
//   }
// }

// Class with async methods
ASG.CLASS(
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
)
// Output:
// class DataService {
//   Future<String> fetchData() async {
//     await Future.delayed(Duration(seconds: 1));
//     return "data";
//   }
// }

// Class with factory constructor (Singleton pattern)
ASG.CLASS(
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
    ASG.CONSTRUCTOR(
      name: 'Singleton._internal',
      isPrivate: true,
    ),
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
)
// Output:
// class Singleton {
//   static late Singleton _instance;
//
//   Singleton._internal() {
//   }
//
//   factory Singleton() {
//     if (_instance == null) {
//       _instance = Singleton._internal();
//     }
//     return _instance!;
//   }
// }