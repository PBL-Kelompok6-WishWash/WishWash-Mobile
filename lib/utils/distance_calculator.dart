import 'dart:math';

class DistanceCalculator {
  static const double outletLat = -7.0499;
  static const double outletLng = 110.4381;
  static const double ratePerMeter = 2.0; // Rp 2.000 / km = Rp 2 / meter

  static double calculateDistance(double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - outletLat) * p) / 2 +
        cos(outletLat * p) * cos(lat2 * p) *
        (1 - cos((lon2 - outletLng) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Returns distance in meters
  }

  static double getFee(double lat, double lng) {
    final distanceInMeters = calculateDistance(lat, lng);
    return (distanceInMeters * ratePerMeter).roundToDouble();
  }
}
