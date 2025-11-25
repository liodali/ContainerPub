import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:test/test.dart';

void main() {
  test('test basic field multipart', () {
    final fieldPart = "form-data; name=name;";
    expect(fieldPart.retrieveFieldName(), "name");
    expect(fieldPart.isFileField(), false);
  });
  test('test field multipart', () {
    final fieldPart = "form-data; name=archive; filename=\"data_processor.tar.gz\"";
    expect(fieldPart.retrieveFieldName(), "archive");
    expect(fieldPart.isFileField(), true);
  });
}