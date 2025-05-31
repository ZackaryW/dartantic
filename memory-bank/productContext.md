# Product Context

## Why Dartantic Exists

### Problem Statement
Dart developers lack a comprehensive data validation and serialization library similar to Python's Pydantic. Current solutions are either too basic or require extensive boilerplate code, making data model creation tedious and error-prone.

### Problems Solved
1. **Boilerplate Reduction**: Eliminates repetitive validation code writing
2. **Type Safety**: Compile-time validation code generation with full type safety
3. **Nested Models**: Automatic handling of complex nested data structures
4. **Custom Validation**: Seamless integration of custom validation logic
5. **Serialization**: Built-in JSON/Map serialization and deserialization
6. **Developer Experience**: Clean annotation-based API similar to Pydantic

## How It Should Work

### Core User Experience
```dart
@dttModel
class User with _$UserMixin {
  @DttValidateMethod(validateEmailFormat)
  @DttvMinLength(5)
  @DttvMaxLength(50)
  final String email;

  @DttvNotNull()
  final int age;

  User({required this.email, required this.age});

  // Custom preprocessing
  static String _dttpreprocess_email(String email) => email.trim().toLowerCase();
  
  // Custom validation
  static bool _dttvalidate_age(int age) => age >= 0 && age <= 150;
  
  // Custom postprocessing
  static DateTime _dttpostprocess_createdAt(DateTime date) => /* logic */;
}
```

### Generated Capabilities
```dart
// Validation with preprocessing/postprocessing pipeline
final userData = _$UserMixin.dttCreate(
  email: '  JOHN@EXAMPLE.COM  ', // → preprocessed to 'john@example.com'
  age: 25,
);

// Automatic nested serialization
final userMap = _$UserMixin.dttToMap(userInstance);
// Result: {'email': 'john@example.com', 'age': 25, ...}

// Automatic nested deserialization with validation
final userData = _$UserMixin.dttFromMap({
  'email': '  JOHN@EXAMPLE.COM  ',
  'age': 25,
  'profile': {'bio': 'Developer', 'user': {...}} // Recursively processed
});
```

## User Experience Goals

### Primary Goals
1. **Familiar API**: Python Pydantic developers feel at home
2. **Zero Runtime Dependencies**: Generated code is standalone
3. **Compile-Time Safety**: All validation logic generated at build time
4. **Rich Validation**: Support for complex validation scenarios
5. **Nested Models**: Seamless handling of object relationships
6. **Custom Logic**: Easy integration of custom validation/processing

### Secondary Goals
1. **Performance**: Generated code is optimized for speed
2. **Debugging**: Clear error messages with field-specific details
3. **IDE Support**: Good autocomplete and error highlighting
4. **Documentation**: Comprehensive examples and guides
5. **Ecosystem**: Works well with existing Dart/Flutter tooling

## Target Users

### Primary Users
1. **Flutter Developers**: Building mobile apps with complex data models
2. **Dart Backend Developers**: Creating APIs with robust data validation
3. **Full-Stack Dart Developers**: Need consistent validation across client/server

### Use Cases
1. **API Data Models**: Validating JSON from REST APIs
2. **Form Validation**: Client-side form data validation
3. **Configuration Models**: Application settings with validation
4. **Database Models**: Data models with constraints
5. **Nested Structures**: Complex object hierarchies with validation

## Success Metrics

### Technical Success
1. **Zero Breaking Changes**: Stable API across versions
2. **Performance**: Generated code performs as well as hand-written
3. **Coverage**: Handles 95%+ of common validation scenarios
4. **Reliability**: High test coverage and production stability

### Adoption Success
1. **Developer Satisfaction**: Positive feedback on ease of use
2. **Community Growth**: Active community contributions
3. **Real-World Usage**: Adoption in production applications
4. **Documentation Quality**: Comprehensive and up-to-date docs

## Key Differentiators

### vs Manual Validation
- **80% Less Code**: Automatic generation eliminates boilerplate
- **Consistency**: Standardized patterns across all models
- **Maintainability**: Changes in annotations update all related code

### vs Other Dart Validation Libraries
- **Pydantic-like API**: Familiar to Python developers
- **Nested Models**: Automatic recursive validation/serialization
- **Build-Time Generation**: No runtime performance penalty
- **Flexible Processing**: Custom preprocessing/postprocessing pipeline

### vs JSON Serialization Libraries
- **Validation Included**: Not just serialization, full data validation
- **Type Safety**: Compile-time validation code generation
- **Custom Logic**: Seamless integration of business logic
- **Error Handling**: Rich, field-specific error messages 