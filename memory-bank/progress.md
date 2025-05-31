# Progress

## What Works
1. Model Generation
   - Basic model class generation
   - Field metadata generation
   - Validation and preprocessing
   - Serialization methods

2. Bloc Generation
   - Basic bloc structure generation
   - State management with Cubit
   - Field update methods
   - Validation integration
   - Proper naming convention (DttBloc prefix)
   - Test coverage for basic operations

## What's Left
1. Model Features
   - Complex validation rules
   - Nested model support
   - Custom field types
   - Documentation generation

2. Bloc Features
   - Custom event handling
   - Complex state transitions
   - Async operation support
   - Error handling improvements
   - Documentation for generated code

## Current Status
- Basic model and bloc generation is functional
- Test suite covers core functionality
- Naming conventions are established
- Code organization is clean and maintainable

## Known Issues
- None currently identified

## Evolution of Decisions
1. Bloc Generator
   - Started with AST parsing, switched to regex for simplicity
   - Changed naming from `Att` to `DttBloc` prefix for consistency
   - Moved to part file organization for better code access
   - Simplified metadata extraction process

2. Code Organization
   - Separated model and bloc generation
   - Maintained validation in model class
   - Used part files for generated code
   - Established clear naming conventions 