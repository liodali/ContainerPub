/// Annotation to mark a class as a cloud function
///
/// This annotation must be applied to classes that extend [CloudDartFunction].
/// Each function package must have exactly one class annotated with @cloudFunction.
///
/// Example:
/// ```dart
/// @cloudFunction
/// class MyFunction extends CloudDartFunction {
///   @override
///   Future<CloudResponse> handle({
///     required CloudRequest request,
///     Map<String, String>? env,
///   }) async {
///     return CloudResponse.json({'message': 'Hello World'});
///   }
/// }
/// ```
class CloudFunction {
  const CloudFunction();
}

/// Constant instance of [CloudFunction] annotation
const cloudFunction = CloudFunction();
