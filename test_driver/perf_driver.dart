import 'package:integration_test/integration_test_driver.dart';

// Writes the timeline summaries reported by integration_test/perf_test.dart to build/.
Future<void> main() => integrationDriver(responseDataCallback: writeResponseData);
