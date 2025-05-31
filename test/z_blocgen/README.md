# Dartantic Bloc Generator

A powerful code generation tool that automatically creates BLoC (Business Logic Component) code for Dartantic models. This generator follows the BLoC pattern using Cubits for state management, with full integration of Dartantic's validation system.

## Overview

The bloc generator creates a complete state management solution for your Dartantic models, including:
- State classes (Initial, Loading, Error, Data)
- Event classes for updates and actions
- A Cubit class with validation integration
- Full type safety and null safety support

## Quick Start

1. Add the `@dttBloc` annotation to your model:

```dart
@dttBloc
class User {
  final String name;
  final int age;
  final String email;

  const User({
    required this.name,
    required this.age,
    required this.email,
  });

  // Optional: Add validation methods
  static bool _dttvalidate_age(int age) => age >= 0;
  static String _dttpreprocess_name(String name) => name.trim();
}
```

2. Run the bloc generator:

```bash
dart run tool/generate_blocs.dart
```

3. Use the generated bloc in your code:

```dart
final cubit = DttBlocUserCubit();

// Update fields
cubit.updateName('John Doe');
cubit.updateAge(25);

// Load data
await cubit.loadData({
  'name': 'Jane Doe',
  'age': 30,
  'email': 'jane@example.com'
});

// Save data
await cubit.saveData();

// Reset state
cubit.reset();
```

## Generated Code Structure

For a model named `User`, the generator creates:

### State Classes
- `DttBlocUserState` (abstract base class)
- `DttBlocUserInitial` (initial state)
- `DttBlocUserLoading` (loading state)
- `DttBlocUserError` (error state with message)
- `DttBlocUserStateData` (data state with model fields)

### Event Classes
- `DttBlocUserEvent` (abstract base class)
- `DttBlocUserUpdate{Field}` (field update events)
- `DttBlocUserLoad` (load data event)
- `DttBlocUserSave` (save data event)
- `DttBlocUserReset` (reset state event)
- `DttBlocUserValidate` (validation event)

### Cubit Class
- `DttBlocUserCubit` with methods:
  - `update{Field}` methods for each field
  - `loadData(Map<String, dynamic>)` for loading data
  - `saveData()` for saving data
  - `reset()` for resetting state
  - `validate()` for validation

## Features

### 1. Automatic Field Updates
```dart
// Generated update methods with validation
cubit.updateName('John Doe');  // Uses _dttpreprocess_name if defined
cubit.updateAge(25);          // Uses _dttvalidate_age if defined
```

### 2. Validation Integration
- Automatically uses model's validation methods
- Preprocessing methods are applied during updates
- Validation errors are emitted as error states

### 3. Type Safety
- Full null safety support
- Proper type casting in generated code
- Compile-time type checking

### 4. State Management
- Clear state transitions
- Loading states for async operations
- Error handling with messages
- Immutable state objects

## File Organization

The generator creates a `.bloc.g.dart` file as a part file of your model:

```
your_model.dart
├── your_model.dartantic.g.dart (Dartantic metadata)
└── your_model.bloc.g.dart (Generated bloc code)
```

## Best Practices

1. **Validation Methods**
   - Define validation methods in your model class
   - Use `_dttvalidate_{field}` for validation
   - Use `_dttpreprocess_{field}` for preprocessing

2. **State Usage**
   - Check state type before accessing data
   - Handle loading and error states
   - Use the generated state factory methods

3. **Error Handling**
   - Implement proper error handling in your UI
   - Use the error state's message for user feedback
   - Validate data before saving

## Example

See `test/z_blocgen/bloc_test.dart` for a complete example:

```dart
@dttBloc
class TestUser {
  final String name;
  final int age;
  final String email;

  const TestUser({
    required this.name,
    required this.age,
    required this.email,
  });

  // Validation methods
  static bool _dttvalidate_age(int age) => age >= 0;
  static String _dttpreprocess_name(String name) => name.trim();
}
```

## Testing

The generator includes a test suite in `test/z_blocgen/bloc_test.dart` that demonstrates:
- Basic state transitions
- Field updates with validation
- Data loading and saving
- Error handling
- State immutability

## Limitations

1. Currently supports only basic field types
2. No support for nested models yet
3. Save logic needs to be implemented by the user
4. No custom event handling (planned for future)

## Contributing

Feel free to contribute by:
1. Reporting issues
2. Suggesting features
3. Submitting pull requests

## License

Part of the Dartantic project. See main project license. 