import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/utils/constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_detail.dart';

class KaryawanTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const KaryawanTrackingScreen({super.key, required this.order});

  @override
  State<KaryawanTrackingScreen> createState() => _KaryawanTrackingScreenState();
}

class _KaryawanTrackingScreenState extends State<KaryawanTrackingScreen>
    with TickerProviderStateMixin {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color softTeal = const Color(0xFFBCEFF2);
  final Color bgGrey = const Color(0xFFF8FBFC);

  static final Set<int> _activeTripOrderIds = {};
  bool _showStartAlert = false;
  bool _isUpdating = false;
  bool _isRouteActive = false;
  List<LatLng> _routePoints = [];
  List<LatLng> _storeRoutePoints = [];
  List<Map<String, dynamic>> _navigationSteps = [];
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  final MapController _mapController = MapController();

  // --- Live GPS ---
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentGpsPosition;
  double _currentBearing = 0.0; // degrees
  // ignore: prefer_final_fields
  List<LatLng> _traveledPoints = []; // already traveled sub-polyline
  bool _gpsPermissionGranted = false;
  bool _isNavigationMode = false; // when trip active, switch to nav mode
  bool _autoCenter = true;
  DateTime? _lastRouteFetchTime;
  DateTime? _lastLocationUploadTime;

  // --- Responsive sheet sizes (computed in build) ---
  double _miniSize = 0.22;
  double _expandedSize = 0.60;
  final ValueNotifier<double> _sheetSizeNotifier = ValueNotifier<double>(0.22);

  // --- Animation ---
  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;
  late AnimationController _routeAnimController;

  // --- DraggableSheet controller ---
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    final orderId = widget.order['id_order'] as int? ?? 0;
    _isRouteActive = _activeTripOrderIds.contains(orderId) ||
        (widget.order['is_courier_on_way'] == true);

    // Pulse animation for courier dot
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _initGps();
    _fetchRoutePoints();

    _sheetController.addListener(() {
      _sheetSizeNotifier.value = _sheetController.size;
    });

    if (_isRouteActive) {
      _isNavigationMode = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _collapseSheet();
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseAnimController.dispose();
    _routeAnimController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _collapseSheet() {
    try {
      _sheetController.animateTo(
        _miniSize,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  // ---------- GPS ----------
  Future<void> _initGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) return;

    if (mounted) {
      setState(() => _gpsPermissionGranted = true);
    }

    // Get initial position
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentGpsPosition = LatLng(pos.latitude, pos.longitude);
          _currentBearing = pos.heading;
        });
        if (_isRouteActive) {
          _centerOnCourier();
        }
        _fetchRoutePoints(force: true);
      }
    } catch (_) {}

    // Start streaming
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position pos) {
      if (!mounted) return;
      final newPos = LatLng(pos.latitude, pos.longitude);

      // Check if off route to trigger recalculation
      bool shouldReroute = false;
      if (_isNavigationMode && _routePoints.isNotEmpty) {
        double minDist = double.infinity;
        for (final pt in _routePoints) {
          final d = const Distance().as(LengthUnit.Meter, newPos, pt);
          if (d < minDist) minDist = d;
        }
        if (minDist > 50) {
          shouldReroute = true;
        }
      }

      setState(() {
        _currentGpsPosition = newPos;
        _currentBearing = pos.heading;
        if (_isNavigationMode) {
          _traveledPoints.add(newPos);
          if (_autoCenter) {
            _centerOnCourier();
          }
        }
      });

      if (shouldReroute) {
        _fetchRoutePoints();
      }

      // Send location update to backend at most once every 10 seconds
      final nowTime = DateTime.now();
      if (_lastLocationUploadTime == null || nowTime.difference(_lastLocationUploadTime!).inSeconds >= 10) {
        _lastLocationUploadTime = nowTime;
        _uploadLocationToBackend(pos.latitude, pos.longitude);
      }
    });
  }

  Future<void> _uploadLocationToBackend(double lat, double lng) async {
    try {
      await OrderService.updateOrder(
        widget.order['id_order'],
        {
          'courier_latitude': lat.toString(),
          'courier_longitude': lng.toString(),
        },
      );
    } catch (e) {
      debugPrint('Error uploading courier location: $e');
    }
  }

  void _animatedMapMoveAndRotate(LatLng destLocation, double destZoom, double destRotation) {
    try {
      final camera = _mapController.camera;
      final AnimationController cameraController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );

      final latTween = Tween<double>(
        begin: camera.center.latitude,
        end: destLocation.latitude,
      );
      final lngTween = Tween<double>(
        begin: camera.center.longitude,
        end: destLocation.longitude,
      );
      final zoomTween = Tween<double>(
        begin: camera.zoom,
        end: destZoom,
      );
      final rotationTween = Tween<double>(
        begin: camera.rotation,
        end: destRotation,
      );

      final Animation<double> animation = CurvedAnimation(
        parent: cameraController,
        curve: Curves.fastOutSlowIn,
      );

      cameraController.addListener(() {
        if (!mounted) return;
        try {
          _mapController.moveAndRotate(
            LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
            zoomTween.evaluate(animation),
            rotationTween.evaluate(animation),
          );
        } catch (_) {}
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          cameraController.dispose();
        }
      });

      cameraController.forward();
    } catch (_) {
      try {
        _mapController.moveAndRotate(destLocation, destZoom, destRotation);
      } catch (_) {}
    }
  }

  void _animatedMapFitBounds(LatLngBounds bounds, EdgeInsets padding) {
    try {
      final camera = _mapController.camera;
      final fitted = CameraFit.bounds(
        bounds: bounds,
        padding: padding,
      ).fit(camera);
      _animatedMapMoveAndRotate(fitted.center, fitted.zoom, 0.0);
    } catch (_) {
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: padding,
          ),
        );
        _mapController.rotate(0.0);
      } catch (_) {}
    }
  }

  void _centerOnCourier({bool animate = false}) {
    if (_currentGpsPosition == null) return;
    double heading = _currentBearing;
    final List<LatLng> remainingRoute = _isNavigationMode && _routePoints.isNotEmpty
        ? _getRemainingRoute(_currentGpsPosition!, _routePoints)
        : _routePoints;
    if (remainingRoute.length >= 2) {
      heading = _calculateBearing(remainingRoute[0], remainingRoute[1]);
    }
    final double targetRotation = _isNavigationMode ? -heading : 0.0;
    if (animate) {
      _animatedMapMoveAndRotate(_currentGpsPosition!, 17.5, targetRotation);
    } else {
      try {
        _mapController.moveAndRotate(
          _currentGpsPosition!,
          17.5,
          targetRotation,
        );
      } catch (_) {
        try {
          _mapController.move(_currentGpsPosition!, 17.5);
        } catch (_) {}
      }
    }
  }

  // ---------- Route ----------
  Future<void> _fetchRoutePoints({bool force = false}) async {
    if (!force && _lastRouteFetchTime != null &&
        DateTime.now().difference(_lastRouteFetchTime!) < const Duration(seconds: 8)) {
      return;
    }
    _lastRouteFetchTime = DateTime.now();

    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup =
        status == 'penjemputan' || status == 'pesanan diterima';
    final alamatAmbil = widget.order['AlamatPengambilan'] ?? {};
    final alamatKirim = widget.order['AlamatPenyerahan'] ?? {};
    final targetAddrObj = isPickup ? alamatAmbil : alamatKirim;

    final double storeLat = -7.0499;
    final double storeLon = 110.4381;

    final double startLat = _currentGpsPosition != null ? _currentGpsPosition!.latitude : storeLat;
    final double startLon = _currentGpsPosition != null ? _currentGpsPosition!.longitude : storeLon;

    double customerLat = -7.0499;
    double customerLon = 110.4381;
    bool hasCoords = false;

    if (targetAddrObj != null &&
        targetAddrObj['latitude'] != null &&
        targetAddrObj['longitude'] != null) {
      final double? parsedLat =
          double.tryParse(targetAddrObj['latitude'].toString());
      final double? parsedLon =
          double.tryParse(targetAddrObj['longitude'].toString());
      if (parsedLat != null && parsedLon != null) {
        customerLat = parsedLat;
        customerLon = parsedLon;
        hasCoords = true;
      }
    }

    if (!hasCoords) {
      customerLat = storeLat + 0.0055;
      customerLon = storeLon - 0.0065;
    }

    final distanceCalculator = const Distance();
    final double fallbackDistance = distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(startLat, startLon),
      LatLng(customerLat, customerLon),
    );
    final double fallbackDuration = (fallbackDistance / 8.33) * 1.45;

    // Fetch static store-to-customer route once
    if (_storeRoutePoints.isEmpty) {
      try {
        final storeUrl = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$storeLon,$storeLat;$customerLon,$customerLat?overview=full&geometries=geojson',
        );
        final response = await http.get(storeUrl);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final routes = data['routes'] as List?;
          if (routes != null && routes.isNotEmpty) {
            final firstRoute = routes.first as Map;
            final geometry = firstRoute['geometry'] as Map?;
            if (geometry != null) {
              final coordinates = geometry['coordinates'] as List?;
              if (coordinates != null) {
                final List<LatLng> points = coordinates.map((coord) {
                  final list = coord as List;
                  return LatLng(
                    (list[1] as num).toDouble(),
                    (list[0] as num).toDouble(),
                  );
                }).toList();
                if (mounted) {
                  setState(() {
                    _storeRoutePoints = points;
                  });
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching store route: $e');
      }
      if (_storeRoutePoints.isEmpty) {
        _storeRoutePoints = [
          LatLng(storeLat, storeLon),
          LatLng(customerLat, customerLon),
        ];
      }
    }

    setState(() {
      _routePoints = [
        LatLng(startLat, startLon),
        LatLng(customerLat, customerLon),
      ];
      _routeDistance = fallbackDistance;
      _routeDuration = fallbackDuration;
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$customerLon,$customerLat?overview=full&geometries=geojson&steps=true',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map;
          double routeDistance =
              (firstRoute['distance'] as num?)?.toDouble() ?? fallbackDistance;
          double routeDuration =
              ((firstRoute['duration'] as num?)?.toDouble() ?? fallbackDuration) * 1.45;
          if (routeDistance == 0.0) routeDistance = fallbackDistance;
          if (routeDuration == 0.0) routeDuration = fallbackDuration;

          final legs = firstRoute['legs'] as List?;
          List<Map<String, dynamic>> stepsList = [];
          if (legs != null && legs.isNotEmpty) {
            final firstLeg = legs.first as Map;
            final steps = firstLeg['steps'] as List?;
            if (steps != null) {
              for (final step in steps) {
                final stepMap = step as Map;
                final distance = (stepMap['distance'] as num?)?.toDouble() ?? 0.0;
                final name = (stepMap['name'] as String?) ?? '';
                final maneuver = stepMap['maneuver'] as Map?;
                String type = '';
                String modifier = '';
                LatLng stepPoint = LatLng(startLat, startLon);
                if (maneuver != null) {
                  type = (maneuver['type'] as String?) ?? '';
                  modifier = (maneuver['modifier'] as String?) ?? '';
                  final location = maneuver['location'] as List?;
                  if (location != null && location.length >= 2) {
                    stepPoint = LatLng(
                      (location[1] as num).toDouble(),
                      (location[0] as num).toDouble(),
                    );
                  }
                }
                stepsList.add({
                  'point': stepPoint,
                  'distance': distance,
                  'name': name,
                  'type': type,
                  'modifier': modifier,
                });
              }
            }
          }

          final geometry = firstRoute['geometry'] as Map?;
          if (geometry != null) {
            final coordinates = geometry['coordinates'] as List?;
            if (coordinates != null) {
              final List<LatLng> points = coordinates.map((coord) {
                final list = coord as List;
                return LatLng(
                  (list[1] as num).toDouble(),
                  (list[0] as num).toDouble(),
                );
              }).toList();

              if (mounted) {
                setState(() {
                  _routePoints = points;
                  _routeDistance = routeDistance;
                  _routeDuration = routeDuration;
                  _navigationSteps = stepsList;
                });
                if (_autoCenter) {
                  _centerOnCourier(animate: true);
                }
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route from OSRM: $e');
    }

    // Route fetch completed (fallback used)
  }



  void _showStartTripConfirmationDialog() {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup =
        status == 'penjemputan' || status == 'pesanan diterima';
    final bool isEn = TranslationService.currentLang == 'en';

    final String title = isPickup
        ? (isEn ? 'Start Pickup Journey?' : 'Mulai Perjalanan Jemput?')
        : (isEn ? 'Start Delivery Journey?' : 'Mulai Perjalanan Antar?');
    final String desc = isPickup
        ? (isEn
            ? 'Start your pickup trip to customer location now?'
            : 'Apakah Anda ingin memulai perjalanan menjemput cucian pelanggan sekarang?')
        : (isEn
            ? 'Start your delivery trip to customer location now?'
            : 'Apakah Anda ingin memulai perjalanan mengantar cucian ke pelanggan sekarang?');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigation icon with pulse ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: navyColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: navyColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: navyColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cyanColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: cyanColor.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed_rounded,
                          size: 13, color: navyColor.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        isEn
                            ? 'Live GPS tracking will be activated'
                            : 'Pelacakan GPS langsung akan aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: navyColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final orderId = widget.order['id_order'] as int? ?? 0;
                      _activeTripOrderIds.add(orderId);
                      setState(() {
                        _isRouteActive = true;
                        _isNavigationMode = true;
                        _showStartAlert = true;
                        _isUpdating = true;
                        _traveledPoints.clear();
                        if (_currentGpsPosition != null) {
                          _traveledPoints.add(_currentGpsPosition!);
                        }
                      });
                      _collapseSheet();

                      // Center on courier GPS
                      if (_currentGpsPosition != null) {
                        _centerOnCourier();
                      }

                      // Recalculate route starting from the courier's GPS position
                      _fetchRoutePoints(force: true);

                      try {
                        await OrderService.updateOrder(
                            orderId, {'is_courier_on_way': true, 'is_courier_arrived': false});
                      } catch (e) {
                        debugPrint("Error setting is_courier_on_way: $e");
                      } finally {
                        if (mounted) setState(() => _isUpdating = false);
                      }

                      Future.delayed(const Duration(seconds: 4), () {
                        if (mounted) setState(() => _showStartAlert = false);
                      });


                    },
                    child: Text(
                      isEn ? 'Yes, Start Now' : 'Ya, Mulai Sekarang',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEn ? 'Cancel' : 'Batal',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog() {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup =
        status == 'penjemputan' || status == 'pesanan diterima';
    final bool isEn = TranslationService.currentLang == 'en';

    final String title = isPickup
        ? (isEn
            ? 'Confirm Arrival at Pickup?'
            : 'Konfirmasi Sampai Lokasi Jemput?')
        : (isEn ? 'Confirm Delivery Completed?' : 'Konfirmasi Selesai Diantar?');
    final String desc = isPickup
        ? (isEn
            ? 'Are you sure you have arrived at the pickup location?'
            : 'Apakah Anda yakin telah sampai di lokasi penjemputan?')
        : (isEn
            ? 'Are you sure the laundry has been successfully handed over?'
            : 'Apakah Anda yakin cucian telah berhasil diserahkan ke pelanggan?');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: navyColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: navyColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPickup
                        ? Icons.local_shipping_rounded
                        : Icons.task_alt_rounded,
                    color: navyColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [navyColor, navyColor.withBlue(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: navyColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmArrival();
                    },
                    child: Text(
                      isPickup
                          ? (isEn ? 'Yes, Finished Pickup' : 'Ya, Selesai Jemput')
                          : (isEn
                              ? 'Yes, Finished Delivery'
                              : 'Ya, Selesai Antar'),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEn ? 'Cancel' : 'Batal',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmArrival() async {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isEn = TranslationService.currentLang == 'en';
    
    // Dynamic next status determination based on the service's reference statuses
    String nextStatus = 'proses timbang';
    final refStatuses = _getSortedReferenceStatuses(widget.order);
    int currentIdx = -1;
    for (int i = 0; i < refStatuses.length; i++) {
      final name = (refStatuses[i]['nama_status'] ?? '').toString().toLowerCase().trim();
      if (name == 'penjemputan' || name.contains('jemput')) {
        currentIdx = i;
        break;
      }
    }
    if (currentIdx != -1 && currentIdx < refStatuses.length - 1) {
      nextStatus = refStatuses[currentIdx + 1]['nama_status'];
    }

    String successMsg = isEn
        ? 'You have arrived at the pickup location!'
        : 'Anda telah sampai di lokasi penjemputan!';

    if (status == 'siap diantar') {
      nextStatus = 'siap diantar';
      successMsg = isEn
          ? 'You have arrived at the customer location!'
          : 'Anda telah sampai di lokasi pelanggan!';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('arrived_delivery_${widget.order['id_order']}', true);
    }

    setState(() => _isUpdating = true);

    try {
      final updatedOrder = await OrderService.updateOrder(
        widget.order['id_order'],
        {
          'status': nextStatus,
          'is_courier_on_way': false,
          'is_courier_arrived': true,
        },
      );
      if (mounted) {
        _activeTripOrderIds.remove(widget.order['id_order']);
        _positionStream?.cancel();
        setState(() {
          _isUpdating = false;
          _isNavigationMode = false;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: navyColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded, color: navyColor, size: 40),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    successMsg,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        Navigator.pop(context, updatedOrder);
                      },
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        showDialog(
          context: context,
          builder: (dialogCtx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 40),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isEn ? 'Failed: $e' : 'Gagal: $e',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  String _getOrderStatus(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      return 'Pesanan Diterima';
    }
    List<dynamic> sortedHistory = List.from(historyList);
    sortedHistory.sort((a, b) =>
        (a['id_riwayat_status_detail'] as num? ?? 0)
            .compareTo(b['id_riwayat_status_detail'] as num? ?? 0));
    final latestHistory = sortedHistory.last;
    final refStatus = latestHistory['ReferensiStatus'];
    if (refStatus != null && refStatus is Map) {
      return refStatus['nama_status'] ?? 'Pesanan Diterima';
    }
    return 'Pesanan Diterima';
  }

  List<Map<String, dynamic>> _getSortedReferenceStatuses(
    Map<String, dynamic> order,
  ) {
    final layanan = order['Layanan'];
    final List<dynamic>? refList = layanan != null
        ? (layanan['referensi_status'] ?? layanan['ReferensiStatus'])
        : null;

    List<Map<String, dynamic>> sortedList = [];
    if (refList == null || refList.isEmpty) {
      sortedList = [
        {'nama_status': 'Pesanan Diterima', 'urutan_tahap': 1},
        {'nama_status': 'Penjemputan', 'urutan_tahap': 2},
        {'nama_status': 'Proses Timbang', 'urutan_tahap': 3},
        {'nama_status': 'Proses Cuci', 'urutan_tahap': 4},
        {'nama_status': 'Proses Kering', 'urutan_tahap': 5},
        {'nama_status': 'Proses Lipat', 'urutan_tahap': 6},
        {'nama_status': 'Siap Diantar', 'urutan_tahap': 7},
        {'nama_status': 'Selesai', 'urutan_tahap': 8},
      ];
    } else {
      sortedList = List<Map<String, dynamic>>.from(
        refList.map((item) => Map<String, dynamic>.from(item)),
      );
      sortedList.sort((a, b) {
        final valA = a['urutan_tahap'] as num? ?? 0;
        final valB = b['urutan_tahap'] as num? ?? 0;
        return valA.compareTo(valB);
      });
    }
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final pelanggan = widget.order['Pelanggan'] ?? {};
    final customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final customerPhone = (pelanggan['no_telp'] ??
            pelanggan['no_hp'] ??
            pelanggan['NoTelp'] ??
            '-')
        .toString();

    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup =
        status == 'penjemputan' || status == 'pesanan diterima';

    final alamatAmbil = widget.order['AlamatPengambilan'] ?? {};
    final rawAlamatKirim = widget.order['AlamatPenyerahan'] ?? {};
    final alamatKirim = (rawAlamatKirim['alamat_lengkap'] != null &&
            rawAlamatKirim['alamat_lengkap'].toString().isNotEmpty)
        ? rawAlamatKirim
        : alamatAmbil;
    final targetAddrObj = isPickup ? alamatAmbil : alamatKirim;
    final String rawTargetAddress = isPickup
        ? (alamatAmbil['alamat_lengkap'] ?? 'Alamat Pelanggan')
        : (alamatKirim['alamat_lengkap'] ?? 'Alamat Pelanggan');
    String targetAddress = rawTargetAddress;
    if (targetAddress.contains('(') && targetAddress.endsWith(')')) {
      final idx = targetAddress.indexOf('(');
      targetAddress = targetAddress.substring(0, idx).trim();
    }

    final String titleText =
        isPickup ? 'Navigasi Penjemputan' : 'Navigasi Pengantaran';
    final String actionButtonText = _isRouteActive
        ? (isPickup
            ? 'Konfirmasi Selesai Penjemputan'
            : 'Konfirmasi Sampai di Lokasi')
        : (isPickup ? 'Mulai Penjemputan' : 'Mulai Pengantaran');

    // Store coords
    final double storeLat = -7.0499;
    final double storeLon = 110.4381;

    double customerLat = -7.0499;
    double customerLon = 110.4381;
    bool hasCoords = false;

    if (targetAddrObj != null &&
        targetAddrObj['latitude'] != null &&
        targetAddrObj['longitude'] != null) {
      final double? parsedLat =
          double.tryParse(targetAddrObj['latitude'].toString());
      final double? parsedLon =
          double.tryParse(targetAddrObj['longitude'].toString());
      if (parsedLat != null && parsedLon != null) {
        customerLat = parsedLat;
        customerLon = parsedLon;
        hasCoords = true;
      }
    }

    if (!hasCoords) {
      customerLat = storeLat + 0.0055;
      customerLon = storeLon - 0.0065;
    }

    final double maxLatDiff = (storeLat - customerLat).abs();
    final double maxLonDiff = (storeLon - customerLon).abs();
    final double maxDiff =
        maxLatDiff > maxLonDiff ? maxLatDiff : maxLonDiff;

    double initialZoom = 14.0;
    if (maxDiff > 0) {
      if (maxDiff < 0.002) {
        initialZoom = 16.5;
      } else if (maxDiff < 0.005) {
        initialZoom = 16.0;
      } else if (maxDiff < 0.01) {
        initialZoom = 15.0;
      } else if (maxDiff < 0.02) {
        initialZoom = 14.0;
      } else if (maxDiff < 0.04) {
        initialZoom = 13.0;
      } else if (maxDiff < 0.08) {
        initialZoom = 12.0;
      } else {
        initialZoom = 11.0;
      }
    }

    // Determine courier display position
    final LatLng courierPos = _currentGpsPosition ??
        (_routePoints.isNotEmpty
            ? _routePoints.first
            : LatLng(storeLat, storeLon));

    // Split route into traveled vs remaining
    final List<LatLng> remainingRoute = _isNavigationMode && _routePoints.isNotEmpty
        ? _getRemainingRoute(courierPos, _routePoints)
        : _routePoints;

    // ETA remaining
    final double etaSeconds = _isNavigationMode && _traveledPoints.length > 1
        ? _estimateRemainingEta(courierPos)
        : _routeDuration;

    // ---- RESPONSIVE SHEET SIZES ----
    // Hitung berdasarkan tinggi layar & safe area agar tidak overflow di HP apapun
    final double screenH = MediaQuery.of(context).size.height;
    // viewPadding.bottom = safe area fisik (home indicator), lebih reliable di dalam Scaffold
    final double safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final double topPad = MediaQuery.of(context).padding.top;

    // Ukuran presisi tiap elemen di mini state:
    // Ukuran presisi tiap elemen di mini state:
    //   drag handle  : top margin 12 + height 5 + bottom margin 8 = 25
    //   status row   : (jika navigation mode) padding(4+8) + text height ~18 = 30
    //   stats row    : padding(4+12) + chip height ~32 = 48
    //   button area  : padding top 8 + button 52 + padding bottom (16+safeBottom) = 76+safeBottom
    final double statusRowH = _isNavigationMode ? 30.0 : 0.0;
    final double miniPx = 25 + statusRowH + 48 + 76 + safeBottom;
    final double miniSize = (miniPx / screenH).clamp(0.15, 0.35);

    // Expanded mode: mini + routeCard(210) + customerCard(80) + gap(16)
    final double expandedPx = miniPx + 210 + 80 + 16;
    final double expandedSize = (expandedPx / screenH).clamp(miniSize + 0.05, 0.78);

    // Normal (non-nav) initial: same as expanded
    final double normalInitialSize = expandedSize;

    // HUD top offset (navigation card agar tidak ketutup status bar)
    final double hudTopOffset = topPad + 70;

    // Simpan ke fields agar _collapseSheet/_expandSheet bisa pakai nilai responsif
    _miniSize = miniSize;
    _expandedSize = expandedSize;

    // Set initial notifier value if not already updated by listener
    if (_sheetSizeNotifier.value == 0.22) {
      _sheetSizeNotifier.value = _isNavigationMode ? miniSize : expandedSize;
    }


    return AnnotatedRegion<SystemUiOverlayStyle>(

      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // ==================== 1. MAP LAYER ====================
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                key: ValueKey(
                    'tracking_map_${customerLat}_${customerLon}'),
                options: MapOptions(
                  initialCenter: LatLng(
                    (storeLat + customerLat) / 2,
                    (storeLon + customerLon) / 2,
                  ),
                  initialZoom: initialZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && _autoCenter) {
                      setState(() {
                        _autoCenter = false;
                      });
                    }
                  },
                ),
                children: [
                  // Map tiles
                  TileLayer(
                    urlTemplate: _isNavigationMode
                        ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),

                  // Store to customer route (faded blue background path)
                  if (_storeRoutePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _storeRoutePoints,
                          color: const Color(0xFF1E88E5).withOpacity(0.35),
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),

                  // Traveled route (gray/dim) - shows path already covered
                  if (_isNavigationMode && _traveledPoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _traveledPoints,
                          color: Colors.grey.shade400,
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),

                  // Main route (remaining)
                  if (remainingRoute.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: remainingRoute,
                          color: _isNavigationMode
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF1E88E5),
                          strokeWidth: _isNavigationMode ? 6.0 : 4.5,
                          borderColor: _isNavigationMode
                              ? Colors.white.withOpacity(0.6)
                              : Colors.transparent,
                          borderStrokeWidth: _isNavigationMode ? 2.0 : 0,
                        ),
                      ],
                    ),

                  // Markers
                  MarkerLayer(
                    markers: [
                      // Store marker
                      Marker(
                        point: LatLng(storeLat, storeLon),
                        width: 40,
                        height: 40,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: Icon(Icons.storefront_rounded,
                              color: navyColor, size: 20),
                        ),
                      ),

                      // Customer/destination marker
                      Marker(
                        point: LatLng(customerLat, customerLon),
                        width: 44,
                        height: 56,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                              ),
                              child: const Icon(Icons.location_on,
                                  color: Colors.white, size: 18),
                            ),
                            Container(
                              width: 2,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Live courier GPS marker (only when route active or GPS location is available)
                      if (_isRouteActive || _currentGpsPosition != null)
                        Marker(
                          point: courierPos,
                          width: 56,
                          height: 56,
                          rotate: false,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              double markerAngle = _currentBearing;
                              if (remainingRoute.length >= 2) {
                                markerAngle = _calculateBearing(remainingRoute[0], remainingRoute[1]);
                              }
                              final double finalAngle = markerAngle + _mapController.camera.rotation;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulse ring
                                  Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1E88E5)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  // Bearing arrow (rotates with heading or points straight up if map rotates)
                                  // Subtract 45 degrees since Icons.navigation_rounded is naturally tilted 45 deg clockwise
                                  Transform.rotate(
                                    angle: (finalAngle - 45) * math.pi / 180.0,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1565C0),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1565C0)
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================== 2. TOP APP BAR OVERLAY ====================
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _buildGlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: navyColor.withOpacity(0.1), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (_isNavigationMode) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _isNavigationMode
                                  ? (isPickup
                                      ? (TranslationService.currentLang == 'en'
                                          ? "Picking Up Customer's Laundry"
                                          : 'Menjemput Cucian Pelanggan')
                                      : (TranslationService.currentLang == 'en'
                                          ? "Delivering Customer's Laundry"
                                          : 'Mengantar Cucian Pelanggan'))
                                  : titleText,
                              style: GoogleFonts.poppins(
                                color: navyColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fit route bounds button
                  if (_routePoints.isNotEmpty) ...[
                    _buildGlassIconButton(
                      icon: Icons.zoom_out_map_rounded,
                      onTap: () {
                        setState(() {
                          _autoCenter = false;
                        });
                        _animatedMapFitBounds(
                          LatLngBounds.fromPoints(_routePoints),
                          const EdgeInsets.only(
                            top: 180,
                            bottom: 240,
                            left: 50,
                            right: 50,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // ==================== 3. NAVIGATION HUD (shown in nav mode) ====================
            if (_isNavigationMode)
              Positioned(
                top: hudTopOffset,
                left: 16,
                right: 16,
                child: _buildNavigationHUD(etaSeconds, targetAddress, isPickup),
              ),

            // ==================== 4. GPS STATUS BADGE ====================
            if (!_isNavigationMode)
              Positioned(
                top: hudTopOffset,
                right: 16,
                child: _buildGpsStatusBadge(),
              ),

            // ==================== 5. START ALERT TOAST ====================
            if (_showStartAlert)
              Positioned(
                top: MediaQuery.of(context).padding.top + (_isNavigationMode ? 160 : 70),
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _showStartAlert ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: navyColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: navyColor.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationService.currentLang == 'en'
                                    ? 'Navigation Started!'
                                    : 'Navigasi Dimulai!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                TranslationService.currentLang == 'en'
                                    ? 'Live GPS tracking is now active'
                                    : 'Pelacakan GPS langsung aktif',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gps_fixed,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Floating Re-center Pill Button (shown above bottom sheet when autoCenter is false and sheet is collapsed)
            ValueListenableBuilder<double>(
              valueListenable: _sheetSizeNotifier,
              builder: (context, sheetSize, child) {
                if (_autoCenter || sheetSize > 0.35) return const SizedBox.shrink();
                return Positioned(
                  bottom: sheetSize * MediaQuery.of(context).size.height + 16,
                  left: 16,
                  child: child!,
                );
              },
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _autoCenter = true;
                  });
                  if (_isNavigationMode && _currentGpsPosition != null) {
                    _centerOnCourier(animate: true);
                  } else if (_routePoints.isNotEmpty) {
                    _animatedMapFitBounds(
                      LatLngBounds.fromPoints(_routePoints),
                      const EdgeInsets.all(60),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: navyColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: navyColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: -45 * math.pi / 180.0,
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Re-enter',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==================== 6. DRAGGABLE HUD PANEL ====================
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _isNavigationMode ? miniSize : normalInitialSize,
              minChildSize: miniSize * 0.9,
              maxChildSize: expandedSize,
              snap: true,
              snapSizes: [miniSize, expandedSize],
              builder: (context, scrollController) {
                final double bottomPadding = MediaQuery.of(context).viewPadding.bottom + 16;
                final double buttonAreaHeight = 52 + 8 + bottomPadding;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Scrollable content takes full height of the sheet
                      Positioned.fill(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Drag handle
                              Center(
                                child: Container(
                                  width: 45,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),

                              // Navigation mode status row
                              if (_isNavigationMode)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          TranslationService.currentLang == 'en'
                                              ? 'Live GPS Active — Swipe up for details'
                                              : 'GPS Aktif — Geser ke atas untuk detail',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_up_rounded,
                                          color: Colors.grey.shade400, size: 18),
                                    ],
                                  ),
                                ),

                              // Stats row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                                child: Row(
                                  children: [
                                    _buildStatChip(
                                      icon: Icons.timer_outlined,
                                      label: _formatDuration(etaSeconds),
                                      color: navyColor,
                                      bg: const Color(0xFFEBF8FF),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatChip(
                                      icon: Icons.navigation_outlined,
                                      label: _routeDistance >= 1000
                                          ? '${(_routeDistance / 1000).toStringAsFixed(1)} km'
                                          : '${_routeDistance.round()} m',
                                      color: Colors.grey.shade700,
                                      bg: const Color(0xFFF7FAFC),
                                    ),
                                    if (_isNavigationMode &&
                                        _currentGpsPosition != null) ...[
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        icon: Icons.gps_fixed_rounded,
                                        label: 'Live',
                                        color: Colors.green.shade700,
                                        bg: Colors.green.shade50,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Route card & Customer card
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRouteCard(
                                      isPickup: isPickup,
                                      targetAddress: targetAddress,
                                      addrObj: targetAddrObj ?? {},
                                      pelanggan: pelanggan,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildCustomerCard(
                                        customerName, customerPhone, pelanggan),
                                  ],
                                ),
                              ),
                              // Spacer to ensure content doesn't get covered by the sticky button at the bottom
                              SizedBox(height: buttonAreaHeight),
                            ],
                          ),
                        ),
                      ),

                      // Sticky action button at the bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.white.withOpacity(0.95), // Slight glass effect to look premium
                          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRouteActive
                                    ? Colors.green.shade700
                                    : navyColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: (_isRouteActive
                                        ? Colors.green.shade700
                                        : navyColor)
                                    .withOpacity(0.3),
                              ),
                              onPressed: _isUpdating
                                  ? null
                                  : () {
                                      if (!_isRouteActive) {
                                        _showStartTripConfirmationDialog();
                                      } else {
                                        _showConfirmationDialog();
                                      }
                                    },
                              child: _isUpdating
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isRouteActive
                                              ? Icons.check_circle_outline_rounded
                                              : Icons.navigation_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          actionButtonText,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Map<String, dynamic>? _getCurrentManeuver() {
    if (_navigationSteps.isEmpty) return null;
    if (_currentGpsPosition == null) {
      final firstStep = _navigationSteps.first;
      final String name = firstStep['name'] ?? '';
      final String streetSuffix = name.isNotEmpty ? ' ke $name' : '';
      return {
        'instruction': 'Mulai perjalanan$streetSuffix',
        'icon': Icons.trip_origin_rounded,
        'distance': (firstStep['distance'] as num?)?.toDouble() ?? 0.0,
      };
    }

    // Find the next step ahead of the courier.
    double minDist = double.infinity;
    int closestIdx = 0;
    for (int i = 0; i < _navigationSteps.length; i++) {
      final stepPt = _navigationSteps[i]['point'] as LatLng;
      final d = const Distance().as(LengthUnit.Meter, _currentGpsPosition!, stepPt);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }

    int targetIdx = closestIdx;
    if (closestIdx < _navigationSteps.length - 1) {
      final closestPt = _navigationSteps[closestIdx]['point'] as LatLng;
      final distToClosest = const Distance().as(LengthUnit.Meter, _currentGpsPosition!, closestPt);
      if (distToClosest < 20) {
        targetIdx = closestIdx + 1;
      }
    }

    final targetStep = _navigationSteps[targetIdx];
    final targetPt = targetStep['point'] as LatLng;
    final double distanceToManeuver = const Distance().as(LengthUnit.Meter, _currentGpsPosition!, targetPt);

    String instruction = 'Lurus Terus';
    IconData icon = Icons.arrow_upward_rounded;
    final String type = targetStep['type'] ?? '';
    final String modifier = targetStep['modifier'] ?? '';
    final String streetName = targetStep['name'] ?? '';
    final String streetSuffix = streetName.isNotEmpty ? ' ke $streetName' : '';

    if (type == 'arrive') {
      instruction = 'Sampai di lokasi tujuan';
      icon = Icons.location_on_rounded;
    } else if (type == 'depart') {
      instruction = 'Mulai perjalanan';
      icon = Icons.trip_origin_rounded;
    } else {
      if (modifier.contains('left')) {
        instruction = 'Belok Kiri$streetSuffix';
        icon = Icons.turn_left_rounded;
      } else if (modifier.contains('right')) {
        instruction = 'Belok Kanan$streetSuffix';
        icon = Icons.turn_right_rounded;
      } else if (modifier.contains('uturn')) {
        instruction = 'Putar Balik$streetSuffix';
        icon = Icons.u_turn_left_rounded;
      } else {
        instruction = 'Lurus Terus$streetSuffix';
        icon = Icons.arrow_upward_rounded;
      }
    }

    return {
      'instruction': instruction,
      'icon': icon,
      'distance': distanceToManeuver,
    };
  }

  Widget _buildNavigationHUD(
      double etaSeconds, String address, bool isPickup) {
    final maneuver = _getCurrentManeuver();
    final String instruction = maneuver != null ? maneuver['instruction'] : (isPickup ? 'Menuju lokasi penjemputan' : 'Menuju lokasi antar');
    final IconData maneuverIcon = maneuver != null ? maneuver['icon'] : Icons.navigation_rounded;
    final double maneuverDist = maneuver != null ? (maneuver['distance'] as num).toDouble() : 0.0;
    
    String distanceStr = '';
    if (maneuver != null) {
      distanceStr = maneuverDist >= 1000
          ? '${(maneuverDist / 1000).toStringAsFixed(1)} km'
          : '${maneuverDist.round()} m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B873F), // Premium GMaps Green
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B873F).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Maneuver Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              maneuverIcon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Maneuver Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (distanceStr.isNotEmpty)
                  Text(
                    distanceStr,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                Text(
                  instruction,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ETA Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDurationShort(etaSeconds).replaceAll('\n', ' '),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'ETA',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _gpsPermissionGranted && _currentGpsPosition != null
                ? Icons.gps_fixed_rounded
                : Icons.gps_not_fixed_rounded,
            size: 13,
            color: _gpsPermissionGranted && _currentGpsPosition != null
                ? Colors.green.shade600
                : Colors.grey.shade500,
          ),
          const SizedBox(width: 5),
          Text(
            _gpsPermissionGranted && _currentGpsPosition != null
                ? 'GPS Aktif'
                : 'GPS...',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _gpsPermissionGranted && _currentGpsPosition != null
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      {required IconData icon,
      required String label,
      required Color color,
      required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard({
    required bool isPickup,
    required String targetAddress,
    required Map addrObj,
    required Map pelanggan,
  }) {
    final String recipientName = (addrObj['nama_penerima'] ?? '').toString();
    final String recipientPhone = (addrObj['nohp_penerima'] ??
            addrObj['no_telp_penerima'] ??
            addrObj['no_hp_penerima'] ??
            addrObj['no_telp'] ??
            addrObj['no_hp'] ??
            pelanggan['no_telp'] ??
            pelanggan['no_hp'] ??
            pelanggan['NoTelp'] ??
            '')
        .toString();
    String detailAlamat =
        (addrObj['detail_alamat'] ?? addrObj['detail'] ?? '').toString();
    if (detailAlamat.isEmpty) {
      final String full = (addrObj['alamat_lengkap'] ?? '').toString();
      if (full.contains('(') && full.endsWith(')')) {
        final idx = full.indexOf('(');
        detailAlamat = full.substring(idx + 1, full.length - 1).trim();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: navyColor.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Origin Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cyanColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: cyanColor.withOpacity(0.3)),
                ),
                child: Icon(Icons.storefront_rounded, color: navyColor, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOKASI ASAL',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'WishWash Laundry Outlet',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 2. Connecting Line Row
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 28,
                child: Center(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          
          // 3. Destination Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.redAccent, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPickup ? 'ALAMAT PENJEMPUTAN' : 'ALAMAT PENGANTARAN',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      targetAddress,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: navyColor,
                        height: 1.3,
                      ),
                    ),
                    if (detailAlamat.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.info_outline_rounded,
                                size: 11, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Detail: $detailAlamat',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (recipientName.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            recipientName,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                    if (recipientPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            recipientPhone,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCustomerCard(
      String customerName, String customerPhone, Map pelanggan) {
    final String rawFoto =
        (pelanggan['foto_pelanggan'] ?? '').toString();
    final String staticHost =
        Constants.baseUrl.replaceAll('/api/v1', '');
    String fotoUrl = '';
    if (rawFoto.isNotEmpty) {
      if (rawFoto.startsWith('http://') || rawFoto.startsWith('https://')) {
        fotoUrl = rawFoto;
      } else if (rawFoto.startsWith('/')) {
        fotoUrl = '$staticHost$rawFoto';
      } else {
        fotoUrl = '$staticHost/$rawFoto';
      }
    }
    final bool hasFoto = fotoUrl.isNotEmpty;
    final List<String> nameParts = customerName.trim().split(' ');
    final String initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0].toUpperCase()
            : '?');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF42C6D4).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C4B8E), Color(0xFF42C6D4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C4B8E).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: hasFoto
                ? ClipOval(
                    child: Image.network(
                      fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: navyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerPhone,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Chat button linked to in-app room chat
          GestureDetector(
            onTap: () => _openCustomerChat(customerName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C4B8E), Color(0xFF42C6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C4B8E).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: navyColor, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Future<void> _openCustomerChat(String name) async {
    final bool isEn = TranslationService.currentLang == 'en';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/chat/room/order/${widget.order['id_order']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final int roomChatID = resData['data']['id_room_chat'];
        
        final pelanggan = widget.order['Pelanggan'] ?? {};
        final String rawFoto = (pelanggan['foto_pelanggan'] ?? '').toString();
        final String customerPhone = (pelanggan['no_telp'] ?? pelanggan['no_hp'] ?? '').toString();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomChatDetailScreen(
                roomChatID: roomChatID,
                targetName: name,
                targetPhoto: rawFoto,
                subtitle: customerPhone,
                orderToTrack: widget.order,
              ),
            ),
          );
        }
      } else {
        _showErrorDialog(
          isEn ? 'Failed to connect to chat room' : 'Gagal terhubung ke ruang chat',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== UTILS ====================

  List<LatLng> _getRemainingRoute(LatLng courierPos, List<LatLng> route) {
    if (route.isEmpty) return route;
    // Find the closest point on route to courier
    double minDist = double.infinity;
    int closestIdx = 0;
    for (int i = 0; i < route.length; i++) {
      final d = const Distance().as(
          LengthUnit.Meter, courierPos, route[i]);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }
    // Return from closest point to end
    if (closestIdx >= route.length - 1) return [route.last];
    return [courierPos, ...route.sublist(closestIdx)];
  }

  double _estimateRemainingEta(LatLng courierPos) {
    if (_routePoints.isEmpty) return _routeDuration;
    // Find remaining distance on route from courier position
    double minDist = double.infinity;
    int closestIdx = 0;
    for (int i = 0; i < _routePoints.length; i++) {
      final d = const Distance()
          .as(LengthUnit.Meter, courierPos, _routePoints[i]);
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }
    // Sum remaining distance from closest point
    double remaining = 0.0;
    for (int i = closestIdx; i < _routePoints.length - 1; i++) {
      remaining += const Distance()
          .as(LengthUnit.Meter, _routePoints[i], _routePoints[i + 1]);
    }
    // Dynamically calculate speed based on OSRM total distance/duration
    // to match actual driving speeds (e.g. including toll roads).
    double speed = 8.33; // default 30 km/h average
    if (_routeDistance > 0 && _routeDuration > 0) {
      speed = _routeDistance / _routeDuration;
    }
    return remaining / speed;
  }



  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180.0;
    final double lon1 = start.longitude * math.pi / 180.0;
    final double lat2 = end.latitude * math.pi / 180.0;
    final double lon2 = end.longitude * math.pi / 180.0;

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    final double degrees = radians * 180.0 / math.pi;
    return (degrees + 360.0) % 360.0;
  }

  String _formatDuration(double seconds) {
    final bool isEn = TranslationService.currentLang == 'en';
    final int minutes = (seconds / 60).round();
    final String hrStr = isEn ? 'Hr' : 'Jam';
    final String minStr = isEn ? 'Min' : 'Mnt';
    if (minutes > 60) {
      final int hours = minutes ~/ 60;
      final int remaining = minutes % 60;
      return remaining > 0
          ? '$hours $hrStr $remaining $minStr'
          : '$hours $hrStr';
    }
    return '${minutes < 1 ? 1 : minutes} $minStr';
  }

  String _formatDurationShort(double seconds) {
    final int minutes = (seconds / 60).round();
    if (minutes > 60) {
      final int hours = minutes ~/ 60;
      final int remaining = minutes % 60;
      return '${hours}j\n${remaining}m';
    }
    return '${minutes < 1 ? 1 : minutes}\nmnt';
  }
}
