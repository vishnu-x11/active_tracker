import 'gps_fix.dart';

class RawFix {
  const RawFix(this.fix, {required this.at});

  final GpsFix fix;
  final int at;
}
