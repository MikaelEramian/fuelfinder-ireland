import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import '../models/station.dart';
import '../providers/fuel_preference_provider.dart';
import '../providers/location_provider.dart';
import '../providers/stations_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/price_repository.dart';
import '../utils/constants.dart';
import '../widgets/station_marker.dart';
import '../widgets/station_bottom_sheet.dart';
import '../widgets/price_report_form.dart';
import '../widgets/ad_banner_placeholder.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _mapReady = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final service = ref.read(locationServiceProvider);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _handleLocationDenied();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final pos = await service.getCurrentPosition();
      if (mounted && pos != null) {
        setState(() => _userPosition = pos);
        _recenterOnUser();
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _handleLocationDenied();
      return;
    }

    // Show friendly explanation before requesting permission
    if (mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_on, color: kPrimaryGreen),
              SizedBox(width: 8),
              Text('Location Access'),
            ],
          ),
          content: const Text(
            'FuelFinder needs your location to find fuel stations near you.\n\nYour location is never stored or shared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        final pos = await service.getCurrentPosition();
        if (mounted) {
          if (pos != null) {
            setState(() => _userPosition = pos);
            _recenterOnUser();
          } else {
            _handleLocationDenied();
          }
        }
      } else {
        _handleLocationDenied();
      }
    }
  }

  void _handleLocationDenied() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enable location in settings to find stations near you'),
        duration: Duration(seconds: 4),
      ),
    );
    _animateToLocation(
      const LatLng(kIrelandCenterLat, kIrelandCenterLng),
      kIrelandFallbackZoom,
    );
  }

  void _onMapEvent(MapCamera camera, bool hasGesture) {
    if (!_mapReady) return;

    final irelandBounds = LatLngBounds(
      const LatLng(kIrelandSWLat, kIrelandSWLng),
      const LatLng(kIrelandNELat, kIrelandNELng),
    );

    // Manual camera clamping
    double clampedLat = camera.center.latitude;
    double clampedLng = camera.center.longitude;
    bool needsClamping = false;

    if (camera.center.latitude < irelandBounds.south) {
      clampedLat = irelandBounds.south;
      needsClamping = true;
    } else if (camera.center.latitude > irelandBounds.north) {
      clampedLat = irelandBounds.north;
      needsClamping = true;
    }

    if (camera.center.longitude < irelandBounds.west) {
      clampedLng = irelandBounds.west;
      needsClamping = true;
    } else if (camera.center.longitude > irelandBounds.east) {
      clampedLng = irelandBounds.east;
      needsClamping = true;
    }

    if (needsClamping) {
      _mapController.move(LatLng(clampedLat, clampedLng), camera.zoom);
      return; // Prevent firing bounds change on the clamped, unrendered state
    }

    final bounds = camera.visibleBounds;
    ref.read(stationsProvider.notifier).onBoundsChanged(
          MapBounds(
            minLat: bounds.south,
            maxLat: bounds.north,
            minLng: bounds.west,
            maxLng: bounds.east,
          ),
        );
  }
  void _animateToLocation(LatLng target, double zoom) {
    final irelandBounds = LatLngBounds(
      const LatLng(kIrelandSWLat, kIrelandSWLng),
      const LatLng(kIrelandNELat, kIrelandNELng),
    );

    final clampedLat =
        target.latitude.clamp(irelandBounds.south, irelandBounds.north);
    final clampedLng =
        target.longitude.clamp(irelandBounds.west, irelandBounds.east);
    final clampedTarget = LatLng(clampedLat, clampedLng);

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: clampedTarget.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: clampedTarget.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoom.clamp(kMinMapZoom, kMaxMapZoom),
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });

    controller.forward();
  }

  void _recenterOnUser() {
    if (_userPosition != null) {
      final userLatLng =
          LatLng(_userPosition!.latitude, _userPosition!.longitude);
      final irelandBounds = LatLngBounds(
        const LatLng(kIrelandSWLat, kIrelandSWLng),
        const LatLng(kIrelandNELat, kIrelandNELng),
      );

      if (irelandBounds.contains(userLatLng)) {
        _animateToLocation(userLatLng, kInitialUserZoom);
      } else {
        // If abroad, they can see Ireland center
        _animateToLocation(
          const LatLng(kIrelandCenterLat, kIrelandCenterLng),
          kIrelandFallbackZoom,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your location is outside Ireland'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _openBottomSheet(Station station, Color? dynamicColor) {
    final fuelType = ref.read(fuelPreferenceProvider);
    final distanceUnit = ref.read(distanceUnitProvider);
    final nationalAvgs = ref.read(nationalAverageProvider).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: Theme.of(context).bottomSheetTheme.shape,
      builder: (ctx) => StationBottomSheet(
        station: station,
        selectedFuelType: fuelType,
        distanceUnit: distanceUnit,
        userLat: _userPosition?.latitude,
        userLng: _userPosition?.longitude,
        dynamicColor: dynamicColor,
        nationalAvgs: nationalAvgs,
        onReportPrice: () {
          Navigator.pop(ctx);
          _openPriceReport(station);
        },
      ),
    );
  }

  void _openPriceReport(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: Theme.of(context).bottomSheetTheme.shape,
      builder: (ctx) => PriceReportForm(
        stationName: station.name,
        onSubmit: (fuelType, price) async {
          final repo = PriceRepository(ref.read(supabaseServiceProvider));
          await repo.reportPrice(
            stationId: station.id,
            fuelType: fuelType,
            price: price,
            locationLat: _userPosition?.latitude,
            locationLng: _userPosition?.longitude,
          );
          // Immediately update the marker
          ref
              .read(stationsProvider.notifier)
              .updateStationPrice(station.id, fuelType, price);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Price reported successfully! 🎉'),
                backgroundColor: kPrimaryGreen,
              ),
            );
          }
        },
      ),
    );
  }

  List<Station> _filteredStations(List<Station> stations) {
    if (_searchQuery.isEmpty) return stations;
    final q = _searchQuery.toLowerCase();
    return stations.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.brand?.toLowerCase().contains(q) ?? false) ||
          s.address.toLowerCase().contains(q);
    }).toList();
  }

  double? _getDisplayPrice(Station station) {
    final fuelType = ref.read(fuelPreferenceProvider);
    switch (fuelType) {
      case FuelType.petrol:
        return station.petrolPrice;
      case FuelType.diesel:
        return station.dieselPrice;
      case FuelType.both:
        return station.petrolPrice ?? station.dieselPrice;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsState = ref.watch(stationsProvider);
    final fuelType = ref.watch(fuelPreferenceProvider);
    final markerDataMap = ref.watch(stationMarkerDataProvider);

    // Listen for position updates
    ref.listen(positionStreamProvider, (_, next) {
      next.whenData((pos) {
        setState(() => _userPosition = pos);
      });
    });

    final displayedStations = _filteredStations(stationsState.stations);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(kIrelandCenterLat, kIrelandCenterLng),
            initialZoom: kIrelandFallbackZoom,
            minZoom: kMinMapZoom,
            maxZoom: kMaxMapZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (camera, hasGesture) =>
                _onMapEvent(camera, hasGesture),
            onMapReady: () {
              setState(() {
                _mapReady = true;
              });
              _onMapEvent(_mapController.camera, false);
              _recenterOnUser();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ie.fuelfinder.app',
            ),

            if (_userPosition != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                    ),
                    radius: 8,
                    color: Colors.blue.withValues(alpha: 0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                  CircleMarker(
                    point: LatLng(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                    ),
                    radius: 4,
                    color: Colors.blue,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 80,
                disableClusteringAtZoom: 16,
                size: const Size(44, 44),
                markers: displayedStations.map((station) {
                  final mData = markerDataMap[station.id];
                  return Marker(
                    key: ValueKey(station.id),
                    point: LatLng(station.latitude, station.longitude),
                    width: 80,
                    height: 60,
                    child: StationMarkerWidget(
                      price: _getDisplayPrice(station),
                      fuelType: fuelType,
                      color: mData?.color ?? kPrimaryGreen,
                      scale: mData?.scale ?? 1.0,
                      hasPrice: mData?.hasPrice ?? true,
                      onTap: () => _openBottomSheet(station, mData?.color),
                    ),
                  );
                }).toList(),
                builder: (context, markers) {
                  final stationMarkers = markers
                      .map((m) => m.child)
                      .whereType<StationMarkerWidget>();
                  
                  Color clusterColor = const Color(0xFF9E9E9E); // Default grey
                  
                  final colorPriority = [
                    const Color(0xFF00C853), // Cheapest
                    const Color(0xFFFFD600), // Mid/Amber
                    const Color(0xFFFF9100), // Orange
                    const Color(0xFFFF1744), // Most expensive
                  ];

                  int highestPriority = 999;

                  for (final widget in stationMarkers) {
                    if (widget.hasPrice) {
                      final priority = colorPriority.indexOf(widget.color);
                      if (priority != -1 && priority < highestPriority) {
                        highestPriority = priority;
                        clusterColor = widget.color;
                      }
                    }
                  }

                  return ClusterMarkerWidget(
                    key: ValueKey('cluster_${markers.length}'),
                    count: markers.length,
                    color: clusterColor,
                  );
                },
              ),
            ),
          ],
        ),

        if (stationsState.loadState == LoadState.loading &&
            stationsState.stations.isEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade600,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_gas_station,
                          size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(
                        width: 160,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (stationsState.loadState == LoadState.offline)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Offline — showing cached stations',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search stations or brands...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 64,
          left: 16,
          child: GestureDetector(
            onTap: () => _showFuelTypeQuickSwitch(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kPrimaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_gas_station,
                          size: 14, color: kPrimaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Showing: ${fuelType.name[0].toUpperCase()}${fuelType.name.substring(1)}',
                        style: const TextStyle(
                          color: kPrimaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: kPrimaryGreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        if (stationsState.loadState == LoadState.error)
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Failed to load stations',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final bounds = ref.read(mapBoundsProvider);
                      if (bounds != null) {
                        ref.read(stationsProvider.notifier).refresh(bounds);
                      }
                    },
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: 70,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: kPrimaryGreen,
            onPressed: _recenterOnUser,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),

        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AdBannerPlaceholder(),
        ),
      ],
    );
  }

  void _showFuelTypeQuickSwitch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: Theme.of(context).bottomSheetTheme.shape,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Show prices for',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 12),
            ...FuelType.values.map((type) {
              final isSelected = ref.read(fuelPreferenceProvider) == type;
              return ListTile(
                leading: Icon(
                  type == FuelType.both
                      ? Icons.compare_arrows
                      : Icons.water_drop,
                  color: isSelected ? kPrimaryGreen : Colors.grey,
                ),
                title: Text(
                  type.name[0].toUpperCase() + type.name.substring(1),
                ),
                trailing:
                    isSelected ? const Icon(Icons.check, color: kPrimaryGreen) : null,
                onTap: () {
                  ref
                      .read(fuelPreferenceProvider.notifier)
                      .setFuelType(type);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
