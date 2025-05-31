# Dartantic Project Brief

## Project Overview
Dartantic is a Dart library that aims to simplify data class creation and validation, inspired by Python's Pydantic library. It uses source code generation to automatically create data classes and validation functions.

## Core Requirements

### 1. Abstract Syntax Generator (ASG)
- High-level declarative syntax for code generation
- Support for generating Dart classes, methods, and validation logic
- Clean and maintainable code generation approach

### 2. Model Generation
- Source code generation for data classes
- Automatic validation code generation
- Support for recursive validation
- Annotation-based model definition

### 3. Validation System
- Type validation
- Custom validation rules
- Error handling with descriptive messages
- Support for nested model validation

## Technical Goals
1. Create a robust ASG system for code generation
2. Implement model parsing and analysis
3. Generate efficient validation code
4. Provide clear error messages
5. Support common validation patterns
6. Enable custom validation rules

## Success Criteria
1. Easy-to-use annotation system
2. Efficient code generation
3. Comprehensive validation coverage
4. Clear error messages
5. Good documentation
6. High test coverage

## Constraints
1. Must work with Dart's build system
2. Must support Flutter projects
3. Must be compatible with existing Dart/Flutter tooling
4. Must maintain good performance for large models 