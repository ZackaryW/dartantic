import 'package:test/test.dart';
import 'package:dartantic/dartantic.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Test model with @dttBloc annotation
part 'bloc_test.dartantic.g.dart';
part 'bloc_test.bloc.g.dart';

@dttModel
@dttBloc
class TestUser with _$TestUserMixin {
  final String name;
  final int age;
  final String? email;

  const TestUser({required this.name, required this.age, this.email});

  // Custom validation
  static bool _dttvalidate_age(int age) => age >= 0 && age <= 150;

  // Custom preprocessing
  static String _dttpreprocess_name(String name) => name.trim();
}

void main() {
  group('Bloc Generation Tests', () {
    late DttBlocTestUserCubit cubit;

    setUp(() {
      cubit = DttBlocTestUserCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is correct', () {
      expect(cubit.state, isA<DttBlocTestUserInitial>());
    });

    test('Load data updates state correctly', () async {
      final testData = {
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      };

      await cubit.loadData(testData);
      expect(cubit.state, isA<DttBlocTestUserStateData>());

      final state = cubit.state as DttBlocTestUserStateData;
      expect(state.name, equals('John Doe'));
      expect(state.age, equals(30));
      expect(state.email, equals('john@example.com'));
    });

    test('Update methods work correctly', () {
      // First load some data
      cubit.loadData({
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      });

      // Test name update
      cubit.updateName('Jane Doe');
      expect(
        (cubit.state as DttBlocTestUserStateData).name,
        equals('Jane Doe'),
      );

      // Test age update
      cubit.updateAge(25);
      expect((cubit.state as DttBlocTestUserStateData).age, equals(25));

      // Test email update
      cubit.updateEmail('jane@example.com');
      expect(
        (cubit.state as DttBlocTestUserStateData).email,
        equals('jane@example.com'),
      );
    });

    test('Validation works correctly', () {
      // Load valid data
      cubit.loadData({
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      });
      expect(cubit.validate(), isTrue);

      // Load invalid age
      cubit.loadData({
        'name': 'John Doe',
        'age': 200, // Invalid age
        'email': 'john@example.com',
      });
      expect(cubit.validate(), isFalse);
    });

    test('Reset returns to initial state', () {
      // First load some data
      cubit.loadData({
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      });

      // Reset
      cubit.reset();
      expect(cubit.state, isA<DttBlocTestUserInitial>());
    });
  });
}
