import 'track_point.dart';

class GpsFix {
  const GpsFix(this.point, {this.accuracy = 0, this.speed = 0, this.heading});

  final TrackPoint point;
  final double accuracy;
  final double speed;
  final double? heading;
}
