# Cubit test guidelines

This document outlines the structure, scenarios, and best practices for writing tests for all our Cubits. Please follow these guidelines to ensure consistent, high-quality tests across the project.

---

## Test structure

- **File organization:**
  - Each Cubit should have its own test file (e.g., `example_cubit_test.dart`).
  - Group tests by method or functionality using `group` blocks for clarity.

- **Naming convention:**
  - Test descriptions should follow the pattern:
    ```
    [TAG] - GIVEN <initial condition>, WHEN <action is performed>, THEN <expected outcome>
    ```
  - Use scenario tags at the beginning of the description to quickly indicate the type of scenario being tested. The recommended tags are:
    - **[HAPPY PATH]**: For tests validating correct and expected behavior.
    - **[ERROR PATH]**: For tests that validate error handling when exceptions occur.
    - **[STATE UPDATE]**: For tests that verify methods which update the state without external calls.
    - **[RESET ACTION]**: For tests that verify reset or clear actions on the state.
    - **[EDGE CASE]**: For tests covering boundary conditions or unexpected input scenarios.
    
  - **Examples:**
    - `[HAPPY PATH] - GIVEN valid data from the repository, WHEN fetchData is called, THEN should emit [loading, data]`
    - `[ERROR PATH] - GIVEN an exception is thrown, WHEN fetchData is called, THEN should emit [loading, error]`

- **Dummy data & mocks:**
  - Create a dedicated section at the top of your test file (e.g., marked with `// MARK: - DUMMY DATA`) to define any dummy data, helper classes, or mocks.
  - Use `mocktail` to create mocks for external dependencies (e.g., repositories or services).

- **Test cases:**
  - Create another clearly marked section for your tests (e.g., `// MARK: - TEST CASES`).
  - This section will include all the grouped test cases that cover the various scenarios.

---

## Template reference

Below is a sample structure you can use as a template when writing tests for any Cubit:

```dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_app/src/presentation/cubit/example_cubit.dart';
import 'package:your_app/src/data/my_repository.dart';


// MARK: - DUMMY DATA 

class MockMyRepository extends Mock implements MyRepository {}
class MockErrorRepository extends Mock implements ErrorRepository {}
class FakeException extends Fake implements Exception {}


final dummyModel = DummyModel(...)

// MARK: - TEST CASES

void main() {
  late MockMyRepository mockRepository;
  late ExampleCubit exampleCubit;

  setUp(() {
    mockRepository = MockMyRepository();
    exampleCubit = ExampleCubit(mockRepository);
  });

  setUpAll(() {

    registerFallbackValue(FakeException());
  });

  tearDown(() {
    exampleCubit.close();
  });

  group('ExampleCubit.methodName', () {
    blocTest<ExampleCubit, ExampleState>(
      '[HAPPY PATH] - GIVEN valid data, WHEN methodName is called, THEN should emit [loading, data]',
      build: () {
        // Arrange: Set up mock behavior and dummy data.
        when(() => mockRepository.getData()).thenReturn(dummyModel);
        return exampleCubit;
      },
      act: (cubit) => cubit.methodName(),
      expect: () => [
        // Expected state sequence (e.g., initial loading, then data received)
      ],
      verify: (_) {
        // Verify interactions with the mock if needed.
      },
    );

    blocTest<ExampleCubit, ExampleCubitState>(
      // [ERROR PATH] GIVEN an exception is thrown, WHEN methodName is called, THEN should emit [loading, error]
      'GIVEN an exception is thrown, WHEN methodName is called, THEN should emit [loading, error]',
      build: () {
        when(() => mockRepository.getData()).thenThrow(Exception('Data error'));
        return exampleCubit;
      },
      act: (cubit) => cubit.methodName(),
      expect: () => [
        // Expected state sequence with error state
      ],
      verify: (_) {
        verify(() => mockRepository.getData()).called(1);
      },
    );
  });
}

```

## Objectives of the tests

The main goals of our cubit tests are as follows:

- **Business logic coverage:**  
  Validate that each function of the Cubit performs as expected in terms of state updates.

- **Management of intermediate states:**  
  Ensure that loading states (e.g., `isLoading`) are emitted appropriately, which helps in detecting issues in the UI or in the management of asynchronous processes.

- **Robustness in error conditions:**  
  Confirm that, under non-ideal conditions (such as repository failures), the application responds in a controlled and predictable manner.

- **Isolation and predictability:**  
  By testing each method in isolation and using mocks for external dependencies (like repositories), we guarantee that the Cubit's logic remains predictable and easy to maintain.

- **Validation of immutability:**  
  Using `copyWith` correctly is crucial in reactive architectures. Our tests ensure that data is not lost or incorrectly overwritten, maintaining the integrity of the state.
