import 'package:test/test.dart';
import 'package:dartantic/dartantic.dart';

part 'chain_model_test.dartantic.g.dart';

// Validation functions
bool validateEmailFormat(dynamic value) {
  if (value is! String) return false;
  return value.contains('@') && value.contains('.');
}

// Chain model test classes for deep nesting validation
@dttModel
class Address {
  @DttvNotNull()
  @DttvMinLength(5)
  final String street;

  @DttvNotNull()
  @DttvMinLength(2)
  final String city;

  @DttvNotNull()
  @DttvMinLength(2)
  final String country;

  final String? postalCode;

  Address({
    required this.street,
    required this.city,
    required this.country,
    this.postalCode,
  });

  static String _dttpreprocess_street(String street) {
    return street.trim();
  }

  static bool _dttvalidate_postalCode(String? postalCode) {
    if (postalCode == null) return true;
    return postalCode.length >= 4 && postalCode.length <= 10;
  }
}

@dttModel
class ContactInfo {
  @DttvNotNull()
  @DttValidateMethod(validateEmailFormat)
  final String email;

  @DttvMinLength(10)
  final String? phone;

  final Address address;

  ContactInfo({required this.email, this.phone, required this.address});

  static String _dttpreprocess_phone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static bool _dttvalidate_phone(String? phone) {
    if (phone == null) return true;
    return phone.length >= 10 && phone.contains(RegExp(r'^\+?[0-9]+$'));
  }

  static String _dttpreprocess_email(String email) {
    return email.trim().toLowerCase();
  }
}

@dttModel
class Employee {
  @DttvNotNull()
  @DttvMinLength(2)
  final String name;

  @DttvNotNull()
  final int employeeId;

  final ContactInfo contact;

  final Employee? manager; // Self-referential nested model

  Employee({
    required this.name,
    required this.employeeId,
    required this.contact,
    this.manager,
  });

  static String _dttpreprocess_name(String name) {
    return name.trim();
  }

  static bool _dttvalidate_employeeId(int id) {
    return id > 0 && id < 1000000;
  }
}

void main() {
  group('Chain Model Tests - Deep Nested Validation', () {
    test('Basic chain model structure', () {
      final address = Address(
        street: '123 Main St',
        city: 'Tech City',
        country: 'Dartland',
        postalCode: '12345',
      );

      final contact = ContactInfo(
        email: 'john@example.com',
        phone: '+1-555-123-4567',
        address: address,
      );

      final manager = Employee(
        name: 'Jane Manager',
        employeeId: 1001,
        contact: ContactInfo(
          email: 'jane@example.com',
          phone: '+1-555-987-6543',
          address: Address(
            street: '456 Boss Ave',
            city: 'Tech City',
            country: 'Dartland',
          ),
        ),
      );

      final employee = Employee(
        name: 'John Developer',
        employeeId: 2001,
        contact: contact,
        manager: manager,
      );

      expect(employee.name, equals('John Developer'));
      expect(employee.contact.email, equals('john@example.com'));
      expect(employee.contact.address.city, equals('Tech City'));
      expect(employee.manager?.name, equals('Jane Manager'));
    });

    test('Chain model validation - preprocessing', () {
      final employeeData = _$EmployeeMixin.dttFromMap({
        'name': '  John Developer  ',
        'employeeId': 2001,
        'contact': {
          'email': '  JOHN@EXAMPLE.COM  ',
          'phone': '  +1-555-123-4567  ',
          'address': {
            'street': '  123 Main St  ',
            'city': 'Tech City',
            'country': 'Dartland',
            'postalCode': '12345',
          },
        },
        'manager': {
          'name': '  Jane Manager  ',
          'employeeId': 1001,
          'contact': {
            'email': 'jane@example.com',
            'phone': '+1-555-987-6543',
            'address': {
              'street': '456 Boss Ave',
              'city': 'Tech City',
              'country': 'Dartland',
            },
          },
        },
      });

      // Verify preprocessing at all levels
      expect(employeeData['name'], equals('John Developer'));
      expect(employeeData['contact']['email'], equals('john@example.com'));
      expect(employeeData['contact']['phone'], equals('+15551234567'));
      expect(
        employeeData['contact']['address']['street'],
        equals('123 Main St'),
      );
      expect(employeeData['manager']['name'], equals('Jane Manager'));
    });

    test('Chain model validation - custom validation', () {
      // Test valid data
      expect(
        () => _$EmployeeMixin.dttFromMap({
          'name': 'John Developer',
          'employeeId': 2001,
          'contact': {
            'email': 'john@example.com',
            'phone': '+1-555-123-4567',
            'address': {
              'street': '123 Main St',
              'city': 'Tech City',
              'country': 'Dartland',
              'postalCode': '12345',
            },
          },
        }),
        returnsNormally,
      );

      // Test invalid employee ID
      expect(
        () => _$EmployeeMixin.dttFromMap({
          'name': 'John Developer',
          'employeeId': 0,
          'contact': {
            'email': 'john@example.com',
            'address': {
              'street': '123 Main St',
              'city': 'Tech City',
              'country': 'Dartland',
            },
          },
        }),
        throwsA(isA<DttValidationError>()),
      );

      // Test invalid phone number
      expect(
        () => _$EmployeeMixin.dttFromMap({
          'name': 'John Developer',
          'employeeId': 2001,
          'contact': {
            'email': 'john@example.com',
            'phone': '123',
            'address': {
              'street': '123 Main St',
              'city': 'Tech City',
              'country': 'Dartland',
            },
          },
        }),
        throwsA(isA<DttValidationError>()),
      );

      // Test invalid postal code
      expect(
        () => _$EmployeeMixin.dttFromMap({
          'name': 'John Developer',
          'employeeId': 2001,
          'contact': {
            'email': 'john@example.com',
            'address': {
              'street': '123 Main St',
              'city': 'Tech City',
              'country': 'Dartland',
              'postalCode': '123',
            },
          },
        }),
        throwsA(isA<DttValidationError>()),
      );
    });

    test('Chain model serialization/deserialization', () {
      // Create a complex nested structure
      final employee = Employee(
        name: 'John Developer',
        employeeId: 2001,
        contact: ContactInfo(
          email: 'john@example.com',
          phone: '+1-555-123-4567',
          address: Address(
            street: '123 Main St',
            city: 'Tech City',
            country: 'Dartland',
            postalCode: '12345',
          ),
        ),
        manager: Employee(
          name: 'Jane Manager',
          employeeId: 1001,
          contact: ContactInfo(
            email: 'jane@example.com',
            phone: '+1-555-987-6543',
            address: Address(
              street: '456 Boss Ave',
              city: 'Tech City',
              country: 'Dartland',
            ),
          ),
        ),
      );

      // Test serialization
      final employeeMap = _$EmployeeMixin.dttToMap(employee);

      // Verify all levels are properly serialized
      expect(employeeMap['name'], equals('John Developer'));
      expect(employeeMap['contact']['email'], equals('john@example.com'));
      expect(employeeMap['contact']['address']['city'], equals('Tech City'));
      expect(employeeMap['manager']['name'], equals('Jane Manager'));
      expect(
        employeeMap['manager']['contact']['address']['street'],
        equals('456 Boss Ave'),
      );

      // Test deserialization with preprocessing
      final deserializedData = _$EmployeeMixin.dttFromMap(<String, dynamic>{
        'name': '  John Developer  ',
        'employeeId': 2001,
        'contact': <String, dynamic>{
          'email': '  JOHN@EXAMPLE.COM  ',
          'phone': '  +1-555-123-4567  ',
          'address': <String, dynamic>{
            'street': '  123 Main St  ',
            'city': 'Tech City',
            'country': 'Dartland',
            'postalCode': '12345',
          },
        },
        'manager': <String, dynamic>{
          'name': '  Jane Manager  ',
          'employeeId': 1001,
          'contact': <String, dynamic>{
            'email': '  JANE@EXAMPLE.COM  ',
            'phone': '  +1-555-987-6543  ',
            'address': <String, dynamic>{
              'street': '  456 Boss Ave  ',
              'city': 'Tech City',
              'country': 'Dartland',
            },
          },
        },
      });

      // Verify preprocessing at all levels
      expect(deserializedData['name'], equals('John Developer'));
      expect(deserializedData['contact']['email'], equals('john@example.com'));
      expect(deserializedData['contact']['phone'], equals('+15551234567'));
      expect(
        deserializedData['contact']['address']['street'],
        equals('123 Main St'),
      );
      expect(deserializedData['manager']['name'], equals('Jane Manager'));
      expect(
        deserializedData['manager']['contact']['email'],
        equals('jane@example.com'),
      );
      expect(
        deserializedData['manager']['contact']['address']['street'],
        equals('456 Boss Ave'),
      );
    });

    test('Chain model metadata generation', () {
      // Test Address metadata
      expect(_dtt_Address_fieldMeta.fields.containsKey('street'), isTrue);
      expect(_dtt_Address_fieldMeta.fields['street']?.type, equals('String'));
      expect(
        _dtt_Address_fieldMeta.fields['postalCode']?.type,
        equals('String?'),
      );

      // Test ContactInfo metadata with nested Address
      expect(_dtt_ContactInfo_fieldMeta.fields.containsKey('address'), isTrue);
      expect(
        _dtt_ContactInfo_fieldMeta.fields['address']?.subModel,
        equals('Address'),
      );
      expect(
        _dtt_ContactInfo_fieldMeta.fields['address']?.type,
        equals('Address'),
      );

      // Test Employee metadata with nested ContactInfo and self-reference
      expect(_dtt_Employee_fieldMeta.fields.containsKey('contact'), isTrue);
      expect(
        _dtt_Employee_fieldMeta.fields['contact']?.subModel,
        equals('ContactInfo'),
      );
      expect(
        _dtt_Employee_fieldMeta.fields['manager']?.subModel,
        equals('Employee'),
      );
      expect(
        _dtt_Employee_fieldMeta.fields['manager']?.type,
        equals('Employee?'),
      );
    });
  });
}
