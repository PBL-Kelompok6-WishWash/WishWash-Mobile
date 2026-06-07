import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/pelanggan/chat/roomchat_detail.dart';
import 'package:mobile/services/order_service.dart';

class PelangganTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const PelangganTrackingScreen({super.key, required this.order});

  @override
  State<PelangganTrackingScreen> createState() => _PelangganTrackingScreenState();
}

class _PelangganTrackingScreenState extends State<PelangganTrackingScreen> with TickerProviderStateMixin {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color softTeal = const Color(0xFFBCEFF2);
  final Color bgGrey = const Color(0xFFF8FBFC);

  bool _isRouteActive = true;
  List<LatLng> _routePoints = [];
  List<LatLng> _storeRoutePoints = [];
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  bool _isLoadingRoute = false;
  final MapController _mapController = MapController();
  Timer? _updateTimer;
  late Map<String, dynamic> _currentOrder;
  LatLng? _courierGpsPos;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentOrder = Map<String, dynamic>.from(widget.order);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchRoutePoints();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRoutePoints();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoutePoints() async {
    final bool isFirstLoad = _routePoints.isEmpty;

    try {
      final updated = await OrderService.getOrderById(_currentOrder['id_order'] ?? widget.order['id_order']);
      if (mounted) {
        setState(() {
          _currentOrder = Map<String, dynamic>.from(updated);
        });
      }
    } catch (e) {
      debugPrint('Error updating order on tracking screen: $e');
    }

    final status = _getOrderStatus(_currentOrder).toLowerCase();
    final bool isPickup = status.contains('jemput') || status.contains('diterima');
    final alamatAmbil = _currentOrder['AlamatPengambilan'] ?? {};
    final alamatKirim = _currentOrder['AlamatPenyerahan'] ?? {};
    final targetAddrObj = isPickup ? alamatAmbil : alamatKirim;

    final double storeLat = -7.0499;
    final double storeLon = 110.4381;

    double customerLat = -7.0499;
    double customerLon = 110.4381;
    bool hasCoords = false;

    if (targetAddrObj != null && targetAddrObj['latitude'] != null && targetAddrObj['longitude'] != null) {
      final double? parsedLat = double.tryParse(targetAddrObj['latitude'].toString());
      final double? parsedLon = double.tryParse(targetAddrObj['longitude'].toString());
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

    // Parse Courier Live GPS Coordinates if they exist
    LatLng? courierGps;
    if (_currentOrder['courier_latitude'] != null && _currentOrder['courier_longitude'] != null) {
      final double? cLat = double.tryParse(_currentOrder['courier_latitude'].toString());
      final double? cLon = double.tryParse(_currentOrder['courier_longitude'].toString());
      if (cLat != null && cLon != null && cLat != 0.0 && cLon != 0.0) {
        courierGps = LatLng(cLat, cLon);
      }
    }

    final double startLat = courierGps != null ? courierGps.latitude : storeLat;
    final double startLon = courierGps != null ? courierGps.longitude : storeLon;

    final distanceCalculator = const Distance();
    final double fallbackDistance = distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(startLat, startLon),
      LatLng(customerLat, customerLon),
    );
    final double fallbackDuration = (fallbackDistance / 8.33) * 1.45; // motorcycle speed scaled by 1.45x

    final List<LatLng> fallbackPath = [
      LatLng(startLat, startLon),
      LatLng(customerLat, customerLon),
    ];

    if (isFirstLoad) {
      setState(() {
        _isLoadingRoute = true;
        _routePoints = fallbackPath;
        _routeDistance = fallbackDistance;
        _routeDuration = fallbackDuration;
        _courierGpsPos = courierGps;
      });
    } else {
      if (mounted) {
        setState(() {
          _courierGpsPos = courierGps;
        });
      }
    }

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
    }

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$customerLon,$customerLat?overview=full&geometries=geojson',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map;
          double routeDistance = 0.0;
          double routeDuration = 0.0;

          if (firstRoute.containsKey('distance') && firstRoute['distance'] != null) {
            routeDistance = (firstRoute['distance'] as num).toDouble();
          }
          if (firstRoute.containsKey('duration') && firstRoute['duration'] != null) {
            routeDuration = (firstRoute['duration'] as num).toDouble() * 1.45;
          }

          if (routeDistance == 0.0) {
            routeDistance = fallbackDistance;
          }
          if (routeDuration == 0.0) {
            routeDuration = fallbackDuration;
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
                  _isLoadingRoute = false;
                  _courierGpsPos = courierGps;
                });
                if (isFirstLoad) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _animatedMapFitBounds(
                        LatLngBounds.fromPoints(_routePoints),
                        const EdgeInsets.only(
                          top: 110,
                          bottom: 380,
                          left: 55,
                          right: 55,
                        ),
                      );
                    }
                  });
                }
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
      });
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

  String _getOrderStatus(Map<String, dynamic> order) {
    final historyList = order['RiwayatStatusDetail'];
    if (historyList == null || historyList is! List || historyList.isEmpty) {
      return 'Pesanan Diterima';
    }
    List<dynamic> sortedHistory = List.from(historyList);
    sortedHistory.sort((a, b) => (a['id_riwayat_status_detail'] as num? ?? 0).compareTo(b['id_riwayat_status_detail'] as num? ?? 0));
    final latestHistory = sortedHistory.last;
    final refStatus = latestHistory['ReferensiStatus'];
    if (refStatus != null && refStatus is Map) {
      return refStatus['nama_status'] ?? 'Pesanan Diterima';
    }
    return 'Pesanan Diterima';
  }

  @override
  Widget build(BuildContext context) {
    final status = _getOrderStatus(_currentOrder).toLowerCase();
    final bool isPickup = status.contains('jemput') || status.contains('diterima');
    final bool isEn = TranslationService.currentLang == 'en';

    // Alamat tujuan
    final alamatAmbil = _currentOrder['AlamatPengambilan'] ?? {};
    final alamatKirim = _currentOrder['AlamatPenyerahan'] ?? {};
    final targetAddrObj = isPickup ? alamatAmbil : alamatKirim;
    final String rawTargetAddress = isPickup 
        ? (alamatAmbil['alamat_lengkap'] ?? 'Alamat Pelanggan')
        : (alamatKirim['alamat_lengkap'] ?? 'Alamat Pelanggan');
    String targetAddress = rawTargetAddress;
    if (targetAddress.contains('(') && targetAddress.endsWith(')')) {
      final idx = targetAddress.indexOf('(');
      targetAddress = targetAddress.substring(0, idx).trim();
    }

    String detailAlamat = (targetAddrObj['detail_alamat'] ?? targetAddrObj['detail'] ?? '').toString();
    if (detailAlamat.isEmpty) {
      final String full = (targetAddrObj['alamat_lengkap'] ?? '').toString();
      if (full.contains('(') && full.endsWith(')')) {
        final idx = full.indexOf('(');
        detailAlamat = full.substring(idx + 1, full.length - 1).trim();
      }
    }

    final pelanggan = _currentOrder['Pelanggan'] ?? {};
    final String recipientName = (targetAddrObj['nama_penerima'] ?? pelanggan['nama_lengkap'] ?? '').toString();
    final String recipientPhone = (targetAddrObj['nohp_penerima'] ??
            targetAddrObj['no_telp_penerima'] ??
            targetAddrObj['no_hp_penerima'] ??
            targetAddrObj['no_telp'] ??
            targetAddrObj['no_hp'] ??
            pelanggan['no_telp'] ??
            pelanggan['no_hp'] ??
            pelanggan['NoTelp'] ??
            '')
        .toString();

    final String titleText = isPickup 
        ? (isEn ? 'Tracking Pickup Courier' : 'Lacak Kurir Penjemputan')
        : (isEn ? 'Tracking Delivery Courier' : 'Lacak Kurir Pengantaran');

    // Coords parsing
    final double storeLat = -7.0499;
    final double storeLon = 110.4381;

    double customerLat = -7.0499;
    double customerLon = 110.4381;
    bool hasCoords = false;

    if (targetAddrObj != null && targetAddrObj['latitude'] != null && targetAddrObj['longitude'] != null) {
      final double? parsedLat = double.tryParse(targetAddrObj['latitude'].toString());
      final double? parsedLon = double.tryParse(targetAddrObj['longitude'].toString());
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
    final double maxDiff = maxLatDiff > maxLonDiff ? maxLatDiff : maxLonDiff;

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

    LatLng courierPos = _routePoints.isNotEmpty
        ? _routePoints[(_routePoints.length * 0.4).floor()]
        : LatLng(storeLat, storeLon);
    int courierIndex = _routePoints.isNotEmpty ? (_routePoints.length * 0.4).floor() : 0;

    if (_courierGpsPos != null) {
      courierPos = _courierGpsPos!;
      if (_routePoints.isNotEmpty) {
        double minDist = double.infinity;
        int minIdx = 0;
        for (int i = 0; i < _routePoints.length; i++) {
          final dist = const Distance().as(LengthUnit.Meter, _courierGpsPos!, _routePoints[i]);
          if (dist < minDist) {
            minDist = dist;
            minIdx = i;
          }
        }
        courierIndex = minIdx;
      }
    }

    final List<LatLng> traveledRoute = _routePoints.isNotEmpty ? _routePoints.sublist(0, courierIndex + 1) : [];
    final List<LatLng> remainingRoute = _routePoints.isNotEmpty ? _routePoints.sublist(courierIndex) : [];

    return Scaffold(
      body: Stack(
        children: [
          // 1. REAL INTERACTIVE OPENSTREETMAP PREVIEW
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              key: ValueKey('pelanggan_tracking_${customerLat}_${customerLon}'),
              options: MapOptions(
                initialCenter: LatLng(
                  (storeLat + customerLat) / 2,
                  (storeLon + customerLon) / 2,
                ),
                initialZoom: initialZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                // Original static route from store to customer (light blue transparent)
                if (_storeRoutePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _storeRoutePoints,
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.25),
                        strokeWidth: 5.5,
                      ),
                    ],
                  ),
                // Traveled route (gray/dim)
                if (traveledRoute.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: traveledRoute,
                        color: Colors.grey.shade400,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),

                // Remaining route (blue with white borders)
                if (remainingRoute.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: remainingRoute,
                        color: const Color(0xFF1E88E5),
                        strokeWidth: 6.0,
                        borderColor: Colors.white.withOpacity(0.6),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),

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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.storefront_rounded, color: navyColor, size: 20),
                      ),
                    ),
                    // Customer marker (premium pin matching employee screen)
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
                    // Courier current position marker (premium simulated live position with pulse ring)
                    if (_routePoints.isNotEmpty)
                      Marker(
                        point: courierPos,
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse rings (multiple rings for high-quality visual)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 34 + (40 * _pulseController.value),
                                      height: 34 + (40 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1E88E5).withOpacity(0.25 * (1.0 - _pulseController.value)),
                                      ),
                                    ),
                                    Container(
                                      width: 34 + (20 * _pulseController.value),
                                      height: 34 + (20 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1E88E5).withOpacity(0.15 * (1.0 - _pulseController.value)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Marker body
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: const Icon(
                                Icons.motorcycle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 2. PREMIUM APP BAR OVERLAY
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: navyColor.withOpacity(0.1), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      titleText,
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildGlassIconButton(
                  icon: Icons.zoom_out_map_rounded,
                  onTap: () {
                    if (_routePoints.isNotEmpty) {
                      _animatedMapFitBounds(
                        LatLngBounds.fromPoints(_routePoints),
                        const EdgeInsets.only(
                          top: 110,
                          bottom: 380,
                          left: 55,
                          right: 55,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // 3. STATIC COURIER INFO ACTION PANEL (NO SWIPE, MATCHES KARYAWAN THEME)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ETA & Jarak
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF8FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: navyColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: navyColor),
                            const SizedBox(width: 6),
                            Text(
                              _routeDuration > 60
                                  ? '${(_routeDuration / 60).round()} Mnt'
                                  : '1 Mnt',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: navyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.navigation_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              _routeDistance >= 1000
                                  ? '${(_routeDistance / 1000).toStringAsFixed(1)} km'
                                  : '${_routeDistance.round()} m',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Timeline Info Card (aligned perfectly)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgGrey,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: navyColor.withOpacity(0.08), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Outlet
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cyanColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: cyanColor.withOpacity(0.3), width: 1),
                              ),
                              child: Icon(Icons.storefront_rounded, color: navyColor, size: 16),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'OUTLET LOCATION' : 'LOKASI OUTLET',
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

                        // Connector line
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Container(
                            width: 2,
                            height: 16,
                            color: Colors.grey.shade300,
                          ),
                        ),

                        // Row 2: Customer Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPickup ? (isEn ? 'PICKUP ADDRESS' : 'ALAMAT JEMPUT') : (isEn ? 'DELIVERY ADDRESS' : 'ALAMAT ANTAR'),
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (detailAlamat.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isEn ? 'Detail' : 'Catatan'}: $detailAlamat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: 16),

                  // Employee / Courier details card (with vehicle brand and plate info, and chat button)
                  (() {
                    final karyawan = _currentOrder['Karyawan'];
                    if (karyawan == null) return const SizedBox.shrink();
                    final String name = (karyawan['nama_karyawan'] ?? '-').toString();
                    final String phone = (karyawan['no_telp'] ?? '-').toString();
                    final String vehicle = (karyawan['jenis_kendaraan'] ?? '').toString();
                    final String plate = (karyawan['plat_nomor'] ?? '').toString();
                    final String rawFoto = (karyawan['foto_karyawan'] ?? '').toString();

                    final String staticHost = Constants.baseUrl.replaceAll('/api/v1', '');
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
                    final List<String> nameParts = name.trim().split(' ');
                    final String initials = nameParts.length >= 2
                        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                        : (nameParts.isNotEmpty && nameParts[0].isNotEmpty
                              ? nameParts[0][0].toUpperCase()
                              : '?');

                    final bool hasVehicle = vehicle.isNotEmpty;
                    final bool hasPlate = plate.isNotEmpty;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF42C6D4).withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: navyColor.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar image
                          Container(
                            width: 46,
                            height: 46,
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
                                  color: const Color(0xFF0C4B8E).withOpacity(0.2),
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
                                            fontSize: 14,
                                          ),
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
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: navyColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (phone.isNotEmpty && phone != '-') ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    phone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF718096),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (hasVehicle || hasPlate) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.motorcycle_rounded,
                                        size: 13,
                                        color: Color(0xFF718096),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          [
                                            if (hasVehicle) vehicle,
                                            if (hasPlate) plate,
                                          ].join(' \u2022 '),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF4A5568),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Chat button
                          if (phone.isNotEmpty && phone != '-')
                            GestureDetector(
                              onTap: () async {
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('jwt_token');
                                  if (token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEn ? 'Please login first' : 'Silakan login terlebih dahulu',
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }

                                  // Show loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  final response = await http.get(
                                    Uri.parse('${Constants.baseUrl}/chat/room/order/${_currentOrder['id_order']}'),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json',
                                    },
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context); // close loading
                                  }

                                  if (response.statusCode == 200) {
                                    final resData = jsonDecode(response.body);
                                    final int roomChatID = resData['data']['id_room_chat'];

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RoomChatDetailScreen(
                                            roomChatID: roomChatID,
                                            targetName: name,
                                            targetPhoto: rawFoto,
                                            subtitle: [
                                              if (vehicle.isNotEmpty) vehicle,
                                              if (plate.isNotEmpty) plate,
                                            ].join(' \u2022 '),
                                            orderToTrack: _currentOrder,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEn ? 'Failed to connect to chat room' : 'Gagal terhubung ke ruang chat',
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // close loading
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
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
                                      color: const Color(0xFF0C4B8E).withOpacity(0.2),
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
                                      isEn ? 'Chat' : 'Chat',
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
                  })(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
}
