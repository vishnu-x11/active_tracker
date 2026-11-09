class TrackPoint {
  const TrackPoint({required this.lat, required this.lng, required this.t, this.alt, this.segment = 0});

  final double lat;
  final double lng;
  final double? alt;
  final int t;
  final int segment;

  TrackPoint withSegment(int s) => TrackPoint(lat: lat, lng: lng, alt: alt, t: t, segment: s);

  @override
  bool operator ==(Object other) =>
      other is TrackPoint &&
      other.lat == lat &&
      other.lng == lng &&
      other.alt == alt &&
      other.t == t &&
      other.segment == segment;

  @override
  int get hashCode => Object.hash(lat, lng, alt, t, segment);
}

enum Effort {
  k1('1K', 1000),
  k5('5K', 5000),
  k10('10K', 10000),
  half('21K', 21097);

  const Effort(this.label, this.meters);
  final String label;
  final int meters;
}
