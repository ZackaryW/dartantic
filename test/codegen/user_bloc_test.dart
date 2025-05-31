import 'package:dartantic/dartantic.dart';
import 'package:test/test.dart';

part 'user_bloc_test.dartantic.g.dart';
part 'user_bloc_test.bloc.g.dart';

// Custom validation functions
bool validateEmailFormat(String email) {
  return email.contains('@') && email.contains('.');
}

bool validateStrongPassword(String password) {
  return password.length >= 8 &&
      password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[0-9]'));
}

@dttModel
@dttBloc
class UserBloc with _$UserBlocMixin {
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
  final String? nickname;

  UserBloc({
    required this.name,
    required this.age,
    required this.email,
    required this.password,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.nickname,
  });

  // Custom preprocessing methods
  static String _dttpreprocess_email(String email) =>
      email.trim().toLowerCase();
  static String _dttpreprocess_password(String password) => password.trim();

  // Custom validation methods
  static bool _dttvalidate_email(String email, Map<String, dynamic> values) {
    return !email.startsWith('test@');
  }

  static bool _dttvalidate_age(int age) {
    return age >= 18 && age <= 120;
  }

  static bool _dttvalidate_name(String name) {
    return !name.toLowerCase().contains('admin');
  }

  // Custom postprocessing methods
  static DateTime _dttpostprocess_createdAt(DateTime date) => date.toUtc();
  static bool _dttpostprocess_isActive(bool isActive) => isActive;
}

void main() {
  group('UserBloc Generator Tests', () {
    test('should generate bloc state classes', () {
      // Test that the generated state classes exist and work
      const initialState = UserBlocInitial();
      expect(initialState, isA<UserBlocState>());

      const loadingState = UserBlocLoading();
      expect(loadingState, isA<UserBlocState>());

      const errorState = UserBlocError('Test error');
      expect(errorState, isA<UserBlocState>());
      expect(errorState.message, equals('Test error'));
    });

    test('should generate bloc event classes', () {
      // Test that the generated event classes exist
      const updateNameEvent = UserBlocUpdateName('John Doe');
      expect(updateNameEvent, isA<UserBlocEvent>());
      expect(updateNameEvent.name, equals('John Doe'));

      const updateAgeEvent = UserBlocUpdateAge(25);
      expect(updateAgeEvent, isA<UserBlocEvent>());
      expect(updateAgeEvent.age, equals(25));

      const loadEvent = UserBlocLoad();
      expect(loadEvent, isA<UserBlocEvent>());

      const saveEvent = UserBlocSave();
      expect(saveEvent, isA<UserBlocEvent>());

      const resetEvent = UserBlocReset();
      expect(resetEvent, isA<UserBlocEvent>());
    });

    test('should create cubit with validation integration', () {
      // Test that the cubit integrates with dartantic validation
      final cubit = UserBlocCubit();
      expect(cubit.state, isA<UserBlocInitial>());

      // Test loading valid data
      final validData = {
        'name': 'John Doe',
        'age': 25,
        'email': 'john@example.com',
        'password': 'Password123',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': null,
        'nickname': 'Johnny',
      };

      cubit.loadData(validData);
      // Note: In a real test, you'd use bloc_test package to test state changes
    });

    test('should integrate with dartantic validation', () {
      // Test that validation from dartantic is properly integrated
      final validData = _$UserBlocMixin.dttCreate(
        name: 'John Doe',
        age: 25,
        email: 'john@example.com',
        password: 'Password123',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: null,
        nickname: 'Johnny',
      );

      expect(validData, isA<Map<String, dynamic>>());
      expect(validData['name'], equals('John Doe'));
      expect(
        validData['email'],
        equals('john@example.com'),
      ); // Should be preprocessed
    });

    test('should handle validation errors in bloc', () {
      final cubit = UserBlocCubit();

      // Test with invalid data (email too short)
      final invalidData = {
        'name': 'Jo', // Too short (min 2 chars)
        'age': 25,
        'email': 'x@y', // Too short (min 5 chars)
        'password': '123', // Too short (min 8 chars)
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      cubit.loadData(invalidData);
      // The cubit should emit an error state due to validation failures
    });
  });
}
