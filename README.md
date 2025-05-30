# dartantic

dartantic is a library trying to make data classes and validation easy.

It tries to mirror the functions of the [python pydantic library](https://docs.pydantic.dev/latest/).

This library uses source generation to create the data classes and validation functions.

## Features
### 0. `asg` Abstract Syntax Generator
- instead of directly writing source via `buffer.write` we use a `asg` to enable a more high level declarative syntax
### 1. Recursive validation
