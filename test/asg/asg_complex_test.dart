import 'package:test/test.dart';
import 'package:dartantic/asg/asg.dart';

void main() {
  group('ASG Complex Class Generation', () {
    test('generates class with multiple constructors and initializers', () {
      final result = ASG.CLASS(
        name: 'Point',
        fields: [
          ASG.FIELD(name: 'x', type: 'double', isFinal: true),
          ASG.FIELD(name: 'y', type: 'double', isFinal: true),
        ],
        constructors: [
          ASG.CONSTRUCTOR(name: 'Point', parameters: ['this.x', 'this.y']),
          ASG.CONSTRUCTOR(
            name: 'Point.origin',
            isConst: true,
            initializers: ['x = 0', 'y = 0'],
          ),
          ASG.CONSTRUCTOR(
            name: 'Point.fromJson',
            parameters: ['Map<String, dynamic> json'],
            initializers: ['x = json[\'x\']', 'y = json[\'y\']'],
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Point {\n'
          '  final double x;\n'
          '  final double y;\n'
          '\n'
          '  Point(this.x, this.y) {\n'
          '  }\n'
          '\n'
          '  const Point.origin() : x = 0, y = 0 {\n'
          '  }\n'
          '\n'
          '  Point.fromJson(Map<String, dynamic> json) : x = json[\'x\'], y = json[\'y\'] {\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with getters and setters', () {
      final result = ASG.CLASS(
        name: 'Rectangle',
        fields: [
          ASG.FIELD(name: '_width', type: 'double'),
          ASG.FIELD(name: '_height', type: 'double'),
        ],
        methods: [
          ASG.METHOD(
            name: 'width',
            returnType: 'double',
            isOverride: true,
            body: ASG.fromLines(['return _width;']),
          ),
          ASG.METHOD(
            name: 'width=',
            returnType: 'void',
            parameters: ['double value'],
            body: ASG.fromLines(['_width = value;']),
          ),
          ASG.METHOD(
            name: 'height',
            returnType: 'double',
            isOverride: true,
            body: ASG.fromLines(['return _height;']),
          ),
          ASG.METHOD(
            name: 'height=',
            returnType: 'void',
            parameters: ['double value'],
            body: ASG.fromLines(['_height = value;']),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Rectangle {\n'
          '  double _width;\n'
          '  double _height;\n'
          '\n'
          '  @override\n'
          '  double width() {\n'
          '    return _width;\n'
          '  }\n'
          '  void width=(double value) {\n'
          '    _width = value;\n'
          '  }\n'
          '  @override\n'
          '  double height() {\n'
          '    return _height;\n'
          '  }\n'
          '  void height=(double value) {\n'
          '    _height = value;\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with operator overloading', () {
      final result = ASG.CLASS(
        name: 'Vector',
        fields: [
          ASG.FIELD(name: 'x', type: 'double', isFinal: true),
          ASG.FIELD(name: 'y', type: 'double', isFinal: true),
        ],
        constructors: [
          ASG.CONSTRUCTOR(name: 'Vector', parameters: ['this.x', 'this.y']),
        ],
        methods: [
          ASG.METHOD(
            name: '+',
            returnType: 'Vector',
            parameters: ['Vector other'],
            body: ASG.fromLines(['return Vector(x + other.x, y + other.y);']),
          ),
          ASG.METHOD(
            name: '*',
            returnType: 'Vector',
            parameters: ['double scalar'],
            body: ASG.fromLines(['return Vector(x * scalar, y * scalar);']),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Vector {\n'
          '  final double x;\n'
          '  final double y;\n'
          '\n'
          '  Vector(this.x, this.y) {\n'
          '  }\n'
          '\n'
          '  Vector +(Vector other) {\n'
          '    return Vector(x + other.x, y + other.y);\n'
          '  }\n'
          '  Vector *(double scalar) {\n'
          '    return Vector(x * scalar, y * scalar);\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with abstract methods and interfaces', () {
      final result = ASG.CLASS(
        name: 'Shape',
        methods: [
          ASG.METHOD(
            name: 'area',
            returnType: 'double',
            body: ASG.fromLines(['throw UnimplementedError();']),
          ),
          ASG.METHOD(
            name: 'perimeter',
            returnType: 'double',
            body: ASG.fromLines(['throw UnimplementedError();']),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Shape {\n'
          '  double area() {\n'
          '    throw UnimplementedError();\n'
          '  }\n'
          '  double perimeter() {\n'
          '    throw UnimplementedError();\n'
          '  }\n'
          '}\n',
        ),
      );
    });

    test('generates class with mixins and multiple interfaces', () {
      final result = ASG.CLASS(
        name: 'Logger',
        implementsList: ['Writer', 'Reader'],
        mixinsList: ['Timestamps', 'Formatting'],
        fields: [
          ASG.FIELD(
            name: '_buffer',
            type: 'StringBuffer',
            initializer: 'StringBuffer()',
            isFinal: true,
          ),
        ],
        methods: [
          ASG.METHOD(
            name: 'log',
            returnType: 'void',
            parameters: ['String message'],
            body: ASG.fromLines([
              '_buffer.write(formatMessage(message));',
              '_buffer.write(getTimestamp());',
            ]),
          ),
        ],
      );

      expect(
        result.source,
        equals(
          'class Logger implements Writer, Reader with Timestamps, Formatting {\n'
          '  final StringBuffer _buffer = StringBuffer();\n'
          '\n'
          '  void log(String message) {\n'
          '    _buffer.write(formatMessage(message));\n'
          '    _buffer.write(getTimestamp());\n'
          '  }\n'
          '}\n',
        ),
      );
    });
  });
}
