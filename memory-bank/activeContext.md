# Active Context (Updated)

## Current State - MAJOR MILESTONE ACHIEVED ✅

### FULLY COMPLETED FEATURES
1. **Complete Annotation-Based Validation System**
   - `@DttValidateMethod(function)` - Custom function validation ✅
   - `@DttvMinLength(n)` - Minimum length validation ✅
   - `@DttvMaxLength(n)` - Maximum length validation ✅
   - `@DttvNotNull()` - Null check validation ✅
   - All annotations generate proper validation code ✅

2. **Static Method Processing Pipeline**
   - `_dttpreprocess_{field}` - Data preprocessing ✅
   - `_dttvalidate_{field}` - Custom validation logic ✅
   - `_dttpostprocess_{field}` - Data postprocessing ✅
   - Field existence validation against metadata ✅

3. **Automatic Nested Model Handling**
   - Nested serialization via `dttToMap` ✅
   - Nested deserialization via `dttFromMap` ✅
   - Recursive processing of nested models ✅
   - Support for optional nested models ✅

4. **Generated Methods with dtt Prefix**
   - `dttCreate` - Create with full validation pipeline ✅
   - `dttPreprocess` - Apply preprocessing ✅
   - `dttValidate` - Apply all validations ✅
   - `dttPostprocess` - Apply postprocessing ✅
   - `dttFromMap` - Deserialize from Map with validation ✅
   - `dttToMap` - Serialize to Map with nested support ✅

5. **Model Metadata System**
   - `DttModelMeta` - Field metadata generation ✅
   - `DttFieldMeta` - Individual field information ✅
   - `subModel` detection for nested models ✅
   - Type information with nullability ✅

6. **Modular Architecture (JUST COMPLETED)**
   - Completely refactored from 16KB monolith to modular structure ✅
   - Separated concerns into focused generators ✅
   - Utility classes for common patterns ✅
   - Clean orchestration in main.dart ✅

## Current Work Focus
- Deep nested model validation (using dttFromMap) in test/codegen/chain_model_test.dart.
- Ensuring that preprocessing (e.g. _dttpreprocess_email) and custom validations (e.g. validateEmailFormat) are applied correctly.

## Recent Changes
- Updated test/codegen/chain_model_test.dart to use dttFromMap (instead of dttCreate) for deep nested validation.
- Added a preprocessing method (_dttpreprocess_email) in ContactInfo (and regenerated the .g.dart) so that email is trimmed and lowercased.
- (If applicable) Updated the test data (for example, added a valid phone for the manager's contact) so that all validations pass.

## Next Steps
- Verify that all tests (including "Chain model validation - preprocessing" and "Chain model serialization/deserialization") pass.
- (If needed) further refine or add additional test cases (e.g. for deeper nesting or edge cases).

## Active Decisions & Considerations
- Use dttFromMap (with nested maps) for deep nested validation (and preprocessing) tests.
- (If applicable) ensure that every nested model (e.g. ContactInfo) has the necessary preprocessing (and validation) methods (e.g. _dttpreprocess_email) so that the generated pipeline (dttFromMap) works as expected.

## Important Patterns & Preferences
- (If applicable) Always regenerate (via "dart run build_runner build --delete-conflicting-outputs") after adding or updating preprocessing (or validation) methods.
- (If applicable) Use "dart test --chain-stack-traces" for detailed error traces.

## Learnings & Project Insights
- (If applicable) Deep nested validation (using dttFromMap) requires that every nested model (e.g. ContactInfo) has its preprocessing (and validation) methods (e.g. _dttpreprocess_email) defined (and regenerated) so that the generated pipeline (dttFromMap) applies preprocessing (and validation) as intended.

## Active Decisions - PROVEN PATTERNS

### 1. Annotation-Based Validation ✅
- **Direct Code Generation**: Generate validation code from annotation metadata
- **No Validator Instantiation**: Process annotation constants directly
- **Type-Specific Logic**: Different handling per annotation type
- **Error Context**: Rich error messages with field names

### 2. Modular Code Generation ✅
- **Single Responsibility Generators**: One file per method type
- **Utility-Based Patterns**: Shared code generation helpers
- **Clean Orchestration**: Main generator just coordinates
- **Easy Extension**: Adding new methods requires only new generator

### 3. Nested Model Processing ✅
- **Recursive Validation**: Nested models use their own validation pipeline
- **Map-Based Communication**: Models communicate via processed maps
- **Type Safety**: Compile-time nested model detection
- **Optional Handling**: Proper null handling for optional nested models

## Learnings - PROVEN APPROACHES

### 1. Code Generation Success Patterns
- **ASG-First**: Use ASG for all code generation consistency
- **Utility Classes**: Extract common patterns to reduce duplication
- **Metadata-Driven**: Field metadata as single source of truth
- **Direct Generation**: Generate code directly from annotations, not instances

### 2. Validation Architecture
- **Pipeline Processing**: preprocess → validate → postprocess
- **Static Method Detection**: Regex-based field name extraction
- **Annotation Processing**: Direct constant value processing
- **Field Validation**: Always validate against model metadata

### 3. Modular Development
- **Clean Separation**: One generator per method type
- **Shared Utilities**: Common patterns in utility classes
- **Easy Testing**: Test individual generators independently
- **Simple Maintenance**: Changes isolated to specific generators

## Recent Changes - MAJOR REFACTORING COMPLETED

### Modular Architecture Implementation ✅
- **Reduced main.dart**: From 16KB/482 lines to 2.3KB/73 lines (85% reduction)
- **Created Generator Modules**: 7 focused generator files
- **Utility Classes**: 2 utility files with shared patterns
- **Zero Functional Changes**: All 19 tests still pass

### Structure Achieved:
```
lib/core/gen/
├── main.dart (2.3KB) - Clean orchestration
├── generators/ - Focused method generators
│   ├── create_method.dart
│   ├── preprocess_method.dart
│   ├── validate_method.dart
│   ├── postprocess_method.dart
│   ├── frommap_method.dart
│   ├── tomap_method.dart
│   └── metadata.dart
└── utils/ - Shared patterns
    ├── field_utils.dart
    └── code_utils.dart
```

## CRITICAL SUCCESS - CONSTRAINTS RESOLVED

### ✅ WORKING APPROACHES (KEEP THESE)
1. **Direct Annotation Processing**: Process constant values from annotations
2. **Field Metadata as Source of Truth**: Use generated fieldMetaDict for all operations
3. **Static Method Detection**: Regex extraction with metadata validation
4. **Modular Generators**: Single responsibility principle for maintainability

### ❌ FAILED APPROACHES (NEVER RETRY)
1. **Validator Instance Access**: `obj.getField('instance')` returns null
2. **Constructor Arguments**: Direct access to constructor params fails
3. **Field Reflection**: Iterating annotation object fields doesn't work
4. **Hardcoded Types**: Checking specific validator names breaks extensibility

## Current Status: PRODUCTION READY ✅

- **Feature Complete**: All planned features implemented and tested
- **Architecture Excellent**: Clean, modular, maintainable codebase
- **Test Coverage**: Comprehensive test suite with 19 passing tests
- **Performance Ready**: Generated code is efficient and type-safe
- **Developer Experience**: Clean API matching Python Pydantic patterns 

## Current Focus
- Bloc code generation for Dartantic models
- Implementing and testing bloc generation with proper naming conventions

## Recent Changes
1. Simplified bloc generator to use regex-based metadata extraction
2. Updated bloc class naming convention to use `DttBloc` prefix
   - Example: `TestUser` → `DttBlocTestUserCubit`, `DttBlocTestUserState`, etc.
3. Fixed class generation issues:
   - Properly closed state classes
   - Fixed nullable type handling in `copyWith` methods
   - Updated test file to use new naming convention

## Active Decisions
- Using `DttBloc` prefix for all bloc-related classes to maintain consistency with Dartantic's naming scheme
- Keeping model validation and preprocessing methods in the original model class
- Generated bloc code is part of the model file (using `part` directive)

## Next Steps
1. Test the updated bloc generator with more complex models
2. Consider adding support for custom bloc event handling
3. Document the bloc generation process and naming conventions

## Important Patterns
- Bloc classes follow the pattern: `DttBloc{ModelName}{Type}`
  - Types: `State`, `StateData`, `Event`, `Cubit`, etc.
- Model validation methods remain in original model class
- Generated code is placed in `.bloc.g.dart` files

## Learnings
- Simpler regex-based approach is more maintainable than AST parsing
- Consistent naming conventions are crucial for generated code
- Part files help keep generated code organized while maintaining access to model methods 