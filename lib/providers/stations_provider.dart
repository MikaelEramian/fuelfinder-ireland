import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../repositories/station_repository.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';
import '../providers/fuel_preference_provider.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(ref.watch(supabaseServiceProvider));
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Holds the current map bounds for querying.
final mapBoundsProvider =
    NotifierProvider<MapBoundsNotifier, MapBounds?>(
  MapBoundsNotifier.new,
);

class MapBoundsNotifier extends Notifier<MapBounds?> {
  @override
  MapBounds? build() => null;

  void setBounds(MapBounds? bounds) => state = bounds;
}

/// Main stations provider — reacts to bounds changes with debounce.
final stationsProvider =
    NotifierProvider<StationsNotifier, StationsState>(
  StationsNotifier.new,
);

final nationalAverageProvider = AsyncNotifierProvider<NationalAverageNotifier, Map<String, double>>(
  NationalAverageNotifier.new,
);

class NationalAverageNotifier extends AsyncNotifier<Map<String, double>> {
  Timer? _timer;

  @override
  Future<Map<String, double>> build() async {
    ref.onDispose(() => _timer?.cancel());
    
    // Refresh every 30 minutes
    _timer = Timer.periodic(const Duration(minutes: 30), (_) {
      ref.invalidateSelf();
    });

    final supabase = ref.read(supabaseServiceProvider);
    return await supabase.getNationalAverage();
  }
}

class MapBounds {
  final double minLat, maxLat, minLng, maxLng;
  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}

class StationsState {
  final List<Station> stations;
  final LoadState loadState;
  final String? errorMessage;

  const StationsState({
    this.stations = const [],
    this.loadState = LoadState.loading,
    this.errorMessage,
  });

  StationsState copyWith({
    List<Station>? stations,
    LoadState? loadState,
    String? errorMessage,
  }) {
    return StationsState(
      stations: stations ?? this.stations,
      loadState: loadState ?? this.loadState,
      errorMessage: errorMessage,
    );
  }
}

class StationsNotifier extends Notifier<StationsState> {
  Timer? _debounceTimer;

  @override
  StationsState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    _loadCached();
    return const StationsState();
  }

  Future<void> _loadCached() async {
    final repo = ref.read(stationRepositoryProvider);
    final cached = await repo.getCachedStations();
    if (cached.isNotEmpty) {
      state = StationsState(stations: cached, loadState: LoadState.loaded);
    }
  }

  /// Called when map bounds change. Debounces the query.
  void onBoundsChanged(MapBounds bounds) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kMapQueryDebounce, () => _fetchStations(bounds));
  }

  Future<void> _fetchStations(MapBounds bounds) async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    if (isOffline) {
      state = state.copyWith(loadState: LoadState.offline);
      return;
    }

    if (state.loadState != LoadState.loaded) {
      state = state.copyWith(loadState: LoadState.loading);
    }

    try {
      final repo = ref.read(stationRepositoryProvider);
      final stations = await repo.getStationsInBounds(
        minLat: bounds.minLat,
        maxLat: bounds.maxLat,
        minLng: bounds.minLng,
        maxLng: bounds.maxLng,
      );
      state = StationsState(stations: stations, loadState: LoadState.loaded);
    } catch (e) {
      state = state.copyWith(
        loadState: LoadState.error,
        errorMessage: 'Failed to load stations. Please try again.',
      );
    }
  }

  /// Update a single station's price in the current list (after report).
  void updateStationPrice(
    String stationId,
    String fuelType,
    double newPrice,
  ) {
    final updated = state.stations.map((s) {
      if (s.id != stationId) return s;
      if (fuelType == 'petrol') {
        return s.copyWith(
          petrolPrice: newPrice,
          petrolUpdatedAt: DateTime.now(),
        );
      } else {
        return s.copyWith(
          dieselPrice: newPrice,
          dieselUpdatedAt: DateTime.now(),
        );
      }
    }).toList();
    state = state.copyWith(stations: updated);
  }

  /// Force refresh from network.
  Future<void> refresh(MapBounds bounds) async {
    state = state.copyWith(loadState: LoadState.loading);
    await _fetchStations(bounds);
  }
}

class StationMarkerData {
  final Color color;
  final double scale;
  final bool hasPrice;

  const StationMarkerData({
    required this.color,
    required this.scale,
    required this.hasPrice,
  });
}

final stationMarkerDataProvider = Provider<Map<String, StationMarkerData>>((ref) {
  final stationsState = ref.watch(stationsProvider);
  final fuelType = ref.watch(fuelPreferenceProvider);
  final nationalAvgsAsync = ref.watch(nationalAverageProvider);

  final List<Station> stations = stationsState.stations;
  if (stations.isEmpty) return {};

  final nationalAvgs = nationalAvgsAsync.value;

  final Map<String, StationMarkerData> result = {};

  for (final station in stations) {
    double? price;
    double? avgPrice;

    if (fuelType == FuelType.petrol) {
      price = station.petrolPrice;
      avgPrice = nationalAvgs?['petrol'];
    } else if (fuelType == FuelType.diesel) {
      price = station.dieselPrice;
      avgPrice = nationalAvgs?['diesel'];
    } else {
      if (station.petrolPrice != null && station.dieselPrice != null) {
        price = (station.petrolPrice! + station.dieselPrice!) / 2;
        if (nationalAvgs != null && nationalAvgs['petrol'] != null && nationalAvgs['diesel'] != null) {
           avgPrice = (nationalAvgs['petrol']! + nationalAvgs['diesel']!) / 2;
        }
      } else {
        price = station.petrolPrice ?? station.dieselPrice;
        if (nationalAvgs != null) {
          avgPrice = station.petrolPrice != null ? nationalAvgs['petrol'] : nationalAvgs['diesel'];
        }
      }
    }

    if (price == null || avgPrice == null || avgPrice == 0.0) {
      result[station.id] = const StationMarkerData(
        color: Color(0xFF9E9E9E), // grey
        scale: 1.0,
        hasPrice: false,
      );
      continue;
    }

    Color color;
    double scale = 1.0;

    final diff = price - avgPrice;

    if (diff < -0.08) {
      color = const Color(0xFF00C853);
      scale = 1.2;
    } else if (diff < 0.00) {
      color = const Color(0xFFFFD600);
    } else if (diff <= 0.08) {
      color = const Color(0xFFFF9100);
    } else {
      color = const Color(0xFFFF1744);
      scale = 0.85;
    }

    result[station.id] = StationMarkerData(
      color: color,
      scale: scale,
      hasPrice: true,
    );
  }

  return result;
});

