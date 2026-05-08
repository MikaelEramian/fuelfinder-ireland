import 'dart:math';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Haversine distance between two coordinates in kilometres.
double calculateDistanceKm(
  double lat1, double lng1,
  double lat2, double lng2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLng = _degreesToRadians(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) => degrees * pi / 180;

/// Format distance based on user preference.
String formatDistance(double distanceKm, DistanceUnit unit) {
  if (unit == DistanceUnit.miles) {
    final miles = distanceKm * 0.621371;
    return '${miles.toStringAsFixed(1)} mi';
  }
  return '${distanceKm.toStringAsFixed(1)} km';
}

/// Format price in euro (e.g. "€1.699").
String formatPrice(double? price) {
  if (price == null) return '—';
  return '€${price.toStringAsFixed(3)}';
}

/// Relative time string (e.g. "2 hours ago").
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  return DateFormat('d MMM yyyy').format(dateTime);
}

/// Exponential backoff delay for retry attempts (0-indexed attempt).
Duration retryDelay(int attempt) {
  return Duration(
    milliseconds: kRetryBaseDelay.inMilliseconds * pow(2, attempt).toInt(),
  );
}

/// Run an async function with exponential backoff retry.
Future<T> withRetry<T>(
  Future<T> Function() fn, {
  int maxRetries = kMaxRetries,
}) async {
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (e) {
      if (attempt == maxRetries) rethrow;
      await Future.delayed(retryDelay(attempt));
    }
  }
  throw Exception('Retry exhausted'); // unreachable
}
