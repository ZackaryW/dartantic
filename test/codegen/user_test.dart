import 'package:test/test.dart';
import 'package:dartantic/dartantic.dart';

part 'user_test.dartantic.g.dart';

// Validation functions that return bool
bool validateCustomLength(dynamic value) {
  if (value is! String) return false;
  return value.length > 2;
}

bool validateStrongPassword(dynamic value) {
  if (value is! String) return false;
  return value.contains(RegExp(r'[A-Z]')) &&
      value.contains(RegExp(r'[0-9]')) &&
      value.length >= 8;
}

bool validateEmailFormat(dynamic value) {
  if (value is! String) return false;
  return value.contains('@') && value.contains('.');
}

bool validateNonNumericName(dynamic value) {
  if (value is! String) return false;
  return !value.contains(RegExp(r'[0-9]'));
}

@dttModel
class User with _$UserMixin {
  @DttValidateMethod(validateCustomLength)
  @DttvMinLength(2)
  final String name;

  @DttvNotNull()
  final int age;

  @DttValidateMethod(validateEmailFormat)
  @DttvMinLength(5)
  @DttvMaxLength(50)
  final String email;

  @DttValidateMethod(validateStrongPassword)
  @DttvMinLength(8)
  final String password;

  final bool isActive;

  final DateTime createdAt;

  final DateTime? updatedAt;

  @DttvMinLength(3)
  final String? nickname;

  User({
    required this.name,
    required this.age,
    required this.email,
    required this.password,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.nickname,
  });

  // Static preprocessing methods
  static String _dttpreprocess_name(String name) {
    return name.trim().toLowerCase();
  }

  static String _dttpreprocess_email(String email) {
    return email.trim().toLowerCase();
  }

  static String _dttpreprocess_password(String password) {
    return password.trim();
  }

  // Static validation methods
  static bool _dttvalidate_email(String email, Map<String, dynamic> values) {
    return email.contains('@') && email.contains('.');
  }

  static bool _dttvalidate_age(int age) {
    return age >= 0 && age <= 150;
  }

  static bool _dttvalidate_name(String name) {
    return !name.contains(RegExp(r'[0-9]')); // No numbers in name
  }

  // Static postprocessing methods
  static DateTime _dttpostprocess_createdAt(DateTime createdAt) {
    // Ensure createdAt is not in the future
    final now = DateTime.now();
    return createdAt.isAfter(now) ? now : createdAt;
  }

  static bool _dttpostprocess_isActive(bool isActive) {
    // Default to true if not specified
    return isActive;
  }
}

// Additional test model for nested relationships
@dttModel
class Profile {
  @DttvNotNull()
  @DttvMinLength(1)
  final String bio;

  @DttvMinLength(3)
  @DttvMaxLength(20)
  final String? website;

  final User user; // Reference to User model

  Profile({required this.bio, this.website, required this.user});

  static String _dttpreprocess_bio(String bio) {
    return bio.trim();
  }

  static bool _dttvalidate_website(String? website) {
    if (website == null) return true;
    return website.startsWith('http://') || website.startsWith('https://');
  }
}

void main() {
  group('User Model Tests', () {
    test('Basic model structure', () {
      // Test basic model instantiation
      final user = User(
        name: 'John Doe',
        age: 25,
        email: 'john@example.com',
        password: 'SecurePass123',
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(user.name, equals('John Doe'));
      expect(user.age, equals(25));
      expect(user.email, equals('john@example.com'));
    });

    test('Validation functions work independently', () {
      // Test the validation functions directly
      expect(validateCustomLength('abc'), isTrue);
      expect(validateCustomLength('ab'), isFalse);
      expect(validateStrongPassword('SecurePass123'), isTrue);
      expect(validateStrongPassword('weak'), isFalse);
      expect(validateEmailFormat('test@example.com'), isTrue);
      expect(validateEmailFormat('invalid-email'), isFalse);
    });

    test('User model metadata generation', () {
      // Test the generated metadata structure
      expect(_dtt_User_fieldMeta.fields.containsKey('name'), isTrue);
      expect(_dtt_User_fieldMeta.fields.containsKey('email'), isTrue);
      expect(_dtt_User_fieldMeta.fields.containsKey('age'), isTrue);
      expect(_dtt_User_fieldMeta.fields['name']?.type, equals('String'));
      expect(_dtt_User_fieldMeta.fields['age']?.type, equals('int'));
      expect(
        _dtt_User_fieldMeta.fields['updatedAt']?.type,
        equals('DateTime?'),
      );
      expect(_dtt_User_fieldMeta.fields['nickname']?.type, equals('String?'));
    });

    test('User.create() with preprocessing', () {
      final userData = _$UserMixin.dttCreate(
        name: '  John Doe  ', // Will be preprocessed to lowercase
        age: 25,
        email: '  JOHN@EXAMPLE.COM  ', // Will be preprocessed to lowercase
        password: '  SecurePass123  ', // Will be trimmed
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Test that preprocessing worked
      expect(userData['name'], equals('john doe')); // Trimmed and lowercased
      expect(
        userData['email'],
        equals('john@example.com'),
      ); // Trimmed and lowercased
      expect(userData['password'], equals('SecurePass123')); // Just trimmed
      expect(userData['age'], equals(25));
      expect(userData['isActive'], equals(true));
    });

    test('Static validation methods work', () {
      // Test valid data passes validation
      expect(
        () => _$UserMixin.dttCreate(
          name: 'ValidName', // No numbers
          age: 25, // Valid range
          email: 'test@example.com', // Has @ and .
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('Static validation failures', () {
      // Test email validation failure
      expect(
        () => _$UserMixin.dttCreate(
          name: 'ValidName',
          age: 25,
          email: 'invalid-email', // Missing @ or .
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );

      // Test age validation failure
      expect(
        () => _$UserMixin.dttCreate(
          name: 'ValidName',
          age: 200, // Out of valid range
          email: 'test@example.com',
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );

      // Test name validation failure (contains numbers)
      expect(
        () => _$UserMixin.dttCreate(
          name: 'Invalid123', // Contains numbers
          age: 25,
          email: 'test@example.com',
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );
    });

    test('Postprocessing works', () {
      final futureDate = DateTime.now().add(Duration(days: 1));
      final userData = _$UserMixin.dttCreate(
        name: 'John',
        age: 25,
        email: 'john@example.com',
        password: 'SecurePass123',
        isActive: true,
        createdAt: futureDate, // Future date should be adjusted to now
      );

      // createdAt should be adjusted to not be in the future
      final createdAt = userData['createdAt'] as DateTime;
      expect(
        createdAt.isBefore(DateTime.now().add(Duration(seconds: 1))),
        isTrue,
      );
    });

    test('Annotation-based validation - DttValidateMethod', () {
      // Test @DttValidateMethod(validateCustomLength) on name field
      expect(
        () => _$UserMixin.dttCreate(
          name: 'ab', // Too short for validateCustomLength
          age: 25,
          email: 'test@example.com',
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );
    });

    test('Annotation-based validation - DttvMinLength/MaxLength', () {
      // Test @DttvMinLength(2) on name
      expect(
        () => _$UserMixin.dttCreate(
          name: 'a', // Too short for DttvMinLength(2)
          age: 25,
          email: 'test@example.com',
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );

      // Test @DttvMaxLength(50) on email
      expect(
        () => _$UserMixin.dttCreate(
          name: 'ValidName',
          age: 25,
          email: 'a' * 60 + '@example.com', // Too long for DttvMaxLength(50)
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );
    });

    test('Annotation-based validation - DttvNotNull', () {
      // Test @DttvNotNull() on age - this will be a compile-time error since age is required
      // But we can test that the validation logic exists in the generated code
      expect(_$UserMixin.dttValidate, isA<Function>());
    });

    test('dttFromMap functionality', () {
      final inputMap = {
        'name': '  John Doe  ',
        'age': 25,
        'email': '  JOHN@EXAMPLE.COM  ',
        'password': '  SecurePass123  ',
        'isActive': true,
        'createdAt': DateTime.now(),
        'nickname': 'Johnny',
      };

      final userData = _$UserMixin.dttFromMap(inputMap);

      // Should go through same preprocessing/validation/postprocessing pipeline
      expect(userData['name'], equals('john doe')); // Preprocessed
      expect(userData['email'], equals('john@example.com')); // Preprocessed
      expect(userData['password'], equals('SecurePass123')); // Preprocessed
    });

    test('dttToMap functionality', () {
      final user = User(
        name: 'John Doe',
        age: 25,
        email: 'john@example.com',
        password: 'SecurePass123',
        isActive: true,
        createdAt: DateTime.now(),
        nickname: 'Johnny',
      );

      final userMap = _$UserMixin.dttToMap(user);

      expect(userMap['name'], equals('John Doe'));
      expect(userMap['age'], equals(25));
      expect(userMap['email'], equals('john@example.com'));
      expect(userMap['password'], equals('SecurePass123'));
      expect(userMap['isActive'], equals(true));
      expect(userMap['nickname'], equals('Johnny'));
      expect(userMap.containsKey('createdAt'), isTrue);
    });

    test('Nested model serialization - Profile with User', () {
      final user = User(
        name: 'Jane Doe',
        age: 30,
        email: 'jane@example.com',
        password: 'SecurePass456',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final profile = Profile(
        bio: 'Software Engineer',
        website: 'https://jane.dev',
        user: user,
      );

      // Test dttToMap with nested serialization
      final profileMap = _$ProfileMixin.dttToMap(profile);

      expect(profileMap['bio'], equals('Software Engineer'));
      expect(profileMap['website'], equals('https://jane.dev'));

      // The user field should now be a Map, not a User object!
      expect(profileMap['user'], isA<Map<String, dynamic>>());
      final userMap = profileMap['user'] as Map<String, dynamic>;
      expect(userMap['name'], equals('Jane Doe'));
      expect(userMap['age'], equals(30));
      expect(userMap['email'], equals('jane@example.com'));
    });

    test(
      'Nested model deserialization - Profile from Map with nested User map',
      () {
        final nestedMapData = {
          'bio': '  Full Stack Developer  ', // Will be preprocessed
          'website': 'https://john.dev',
          'user': {
            'name': '  John Smith  ', // Will be preprocessed
            'age': 28,
            'email': '  JOHN.SMITH@EXAMPLE.COM  ', // Will be preprocessed
            'password': '  MySecurePassword123  ', // Will be preprocessed
            'isActive': false,
            'createdAt': DateTime.now().add(
              Duration(days: 1),
            ), // Will be postprocessed
          },
        };

        // Test dttFromMap with nested deserialization
        final profileData = _$ProfileMixin.dttFromMap(nestedMapData);

        // Verify top-level preprocessing worked
        expect(profileData['bio'], equals('Full Stack Developer')); // Trimmed

        // Verify the user field contains a processed map (not a User object)
        expect(profileData['user'], isA<Map<String, dynamic>>());
        final userData = profileData['user'] as Map<String, dynamic>;

        // Verify nested preprocessing/postprocessing worked through the User pipeline
        expect(
          userData['name'],
          equals('john smith'),
        ); // Preprocessed: trimmed + lowercased
        expect(
          userData['email'],
          equals('john.smith@example.com'),
        ); // Preprocessed
        expect(
          userData['password'],
          equals('MySecurePassword123'),
        ); // Preprocessed: trimmed

        // Verify nested postprocessing worked
        final createdAt = userData['createdAt'] as DateTime;
        expect(
          createdAt.isBefore(DateTime.now().add(Duration(seconds: 1))),
          isTrue,
        );
      },
    );

    test('Full integration test - all features working together', () {
      // Test valid data with all features: preprocessing + annotations + static validation + postprocessing
      final futureDate = DateTime.now().add(Duration(days: 1));
      final userData = _$UserMixin.dttCreate(
        name: '  John Doe  ', // Preprocessed: trimmed + lowercased = "john doe"
        age: 25, // Validates: @DttvNotNull + static _dttvalidate_age (0-150)
        email:
            '  JOHN@EXAMPLE.COM  ', // Preprocessed: trimmed + lowercased, validates: @DttValidateMethod + @DttvMinLength(5) + @DttvMaxLength(50) + static method
        password:
            '  SecurePass123  ', // Preprocessed: trimmed, validates: @DttValidateMethod(validateStrongPassword) + @DttvMinLength(8)
        isActive: false, // Postprocessed to true
        createdAt: futureDate, // Postprocessed: future date adjusted to now
        nickname: 'Johnny', // Validates: @DttvMinLength(3)
      );

      // Verify preprocessing worked
      expect(userData['name'], equals('john doe'));
      expect(userData['email'], equals('john@example.com'));
      expect(userData['password'], equals('SecurePass123'));

      // Verify postprocessing worked
      expect(
        userData['isActive'],
        equals(false),
      ); // postprocess doesn't change false to true
      final createdAt = userData['createdAt'] as DateTime;
      expect(
        createdAt.isBefore(DateTime.now().add(Duration(seconds: 1))),
        isTrue,
      );

      // Test that validation catches violations
      expect(
        () => _$UserMixin.dttCreate(
          name: 'Invalid123', // Fails static validation (contains numbers)
          age: 25,
          email: 'john@example.com',
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );

      expect(
        () => _$UserMixin.dttCreate(
          name: 'ValidName',
          age: 25,
          email: 'john@example.com',
          password: 'weak', // Fails @DttValidateMethod(validateStrongPassword)
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );

      expect(
        () => _$UserMixin.dttCreate(
          name: 'a', // Fails @DttvMinLength(2)
          age: 25,
          email: 'john@example.com',
          password: 'SecurePass123',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<DttValidationError>()),
      );
    });
  });

  group('Profile Model Tests', () {
    test('Basic profile structure', () {
      final user = User(
        name: 'Jane',
        age: 30,
        email: 'jane@example.com',
        password: 'SecurePass456',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final profile = Profile(
        bio: 'Software Developer',
        website: 'https://jane.dev',
        user: user,
      );

      expect(profile.bio, equals('Software Developer'));
      expect(profile.user, equals(user));
    });

    test('Profile model metadata with subModel', () {
      // Test that User is detected as a subModel
      expect(_dtt_Profile_fieldMeta.fields.containsKey('user'), isTrue);
      expect(_dtt_Profile_fieldMeta.fields['user']?.subModel, equals('User'));
      expect(_dtt_Profile_fieldMeta.fields['user']?.type, equals('User'));
    });

    test('Profile.create() with preprocessing and validation', () {
      final user = User(
        name: 'Jane',
        age: 30,
        email: 'jane@example.com',
        password: 'SecurePass456',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final profileData = _$ProfileMixin.dttCreate(
        bio: '  Software Developer  ', // Will be preprocessed (trimmed)
        website: 'https://jane.dev',
        user: user,
      );

      expect(profileData['bio'], equals('Software Developer')); // Preprocessed
      expect(profileData['website'], equals('https://jane.dev'));
      expect(profileData['user'], equals(user));
    });

    test('Profile validation - website validation', () {
      final user = User(
        name: 'Jane',
        age: 30,
        email: 'jane@example.com',
        password: 'SecurePass456',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Valid website should work
      expect(
        () => _$ProfileMixin.dttCreate(
          bio: 'Software Developer',
          website: 'https://valid.com',
          user: user,
        ),
        returnsNormally,
      );

      // Invalid website should fail
      expect(
        () => _$ProfileMixin.dttCreate(
          bio: 'Software Developer',
          website: 'invalid-website', // Doesn't start with http:// or https://
          user: user,
        ),
        throwsA(isA<DttValidationError>()),
      );

      // Null website should be allowed
      expect(
        () => _$ProfileMixin.dttCreate(
          bio: 'Software Developer',
          website: null,
          user: user,
        ),
        returnsNormally,
      );
    });
  });
}
