# Repository test guidelines

This document outlines the structure, scenarios, and best practices for writing tests for repository classes. These tests should go beyond mere coverage and focus on verifying key functionalities such as data fetching, transformation, caching, and error handling.

---

## Test structure

- **File organization:**
  - Each repository should have its own test file (e.g., `generic_repository_test.dart`).
  - Organize tests by method or functionality using `group` blocks for clarity.

- **Naming convention:**
  - Test descriptions should follow the pattern:
    ```
    [TAG] - GIVEN <initial condition>, WHEN <action is performed>, THEN <expected outcome>
    ```
  - Use scenario tags at the beginning of the description to quickly indicate the type of scenario being tested. The recommended tags are:
    - **[HAPPY PATH]**: Validates the correct and expected behavior.
    - **[ERROR PATH]**: Ensures proper handling when exceptions or errors occur.
    - **[EDGE CASE]**: Covers boundary conditions or unexpected input scenarios.

- **Dummy data & mocks:**
  - Define dummy data, fake API responses, and mocks at the top of your test file (e.g., using `// MARK: - DUMMY DATA`).
  - Use a mocking library (e.g., `mocktail`) to simulate external dependencies like APIs.
  - Register fallback values for exceptions if needed.

- **Test cases:**
  - Create another clearly marked section for your tests (e.g., `// MARK: - TEST CASES`).
  - This section will include all the grouped test cases that cover the various scenarios.

---

## Template reference

Below is a sample structure you can use as a template when writing tests for any repository:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_app/src/data/generic_repository.dart';
import 'package:your_app/src/data/generic_api.dart';
import 'package:your_app/src/domain/model/generic_model.dart';

// MARK: - DUMMY DATA & MOCKS

class MockGenericApi extends Mock implements GenericApi {}
class FakeException extends Fake implements Exception {}

// Dummy API response.
final dummyApiResponseDto = {
  'id': 1,
  'name': 'Test Name',
  // additional fields...
};

// Expected transformed domain model.
final expectedModel = GenericModel.fromApiResponse(dummyApiResponseDto);

// MARK: - TEST CASES

void main() {
  late MockGenericApi mockApi;
  late GenericRepository repository;

  setUp(() {
    mockApi = MockGenericApi();
    repository = GenericRepository(mockApi);
    registerFallbackValue(FakeException());
  });

  group('GenericRepository.fetchData', () {
    test(
      '[HAPPY PATH] - GIVEN a valid API response, WHEN fetchData is called, THEN should return a valid domain model',
      () async {
        // Arrange: Set up the API to return a valid response dto.
        when(() => mockApi.getData()).thenAnswer((_) async => dummyApiResponseDto);

        // Act: Fetch data via the repository.
        final result = await repository.fetchData();

        // Assert: Validate the result matches the expected model.
        expect(result, isA<GenericModel>());
        expect(result, equals(expectedModel));
      },
    );

    test(
      '[ERROR PATH] - GIVEN an API exception, WHEN fetchData is called, THEN should propagate the exception',
      () async {
        // Arrange: Configure the API to throw an exception.
        when(() => mockApi.getData()).thenThrow(Exception('API error'));

        // Act & Assert: Verify that the exception is thrown.
        expect(repository.fetchData(), throwsException);
      },
    );
  });
}
```

## Objectives of the tests

The main goals of our repository tests are as follows:


- **Validate data transformation:**  
  Ensure that raw API responses are correctly converted into domain models using the appropriate mapping functions.

- **Cover critical scenarios:**  
  Write tests for all key scenarios (happy path, error conditions, edge cases) to maintain high code quality and confidence in the repository's behavior.

- **Robust error handling:**  
  Confirm that errors from external services are properly managed and that exceptions are propagated or handled as expected.

- **Ensure caching works as intended:**  
  Verify that the repository returns valid cached data when available and only calls the API when the cache is outdated or a force update is requested.

- **Isolate business logic:**  
  Use mocks to isolate the repository logic from external dependencies, ensuring tests remain focused on verifying business rules and data integrity.

