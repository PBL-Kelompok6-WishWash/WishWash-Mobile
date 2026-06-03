import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/utils/constants.dart';

class PelangganTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const PelangganTrackingScreen({super.key, required this.order});

  @override
  State<PelangganTrackingScreen> createState() => _PelangganTrackingScreenState();
}

class _PelangganTrackingScreenState extends State<PelangganTrackingScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color softTeal = const Color(0xFFBCEFF2);
  final Color bgGrey = const Color(0xFFF8FBFC);

  bool _isRouteActive = true;
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  bool _isLoadingRoute = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchRoutePoints();
  }

  Future<void> _fetchRoutePoints() async {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status.contains('jemput') || status.contains('diterima');
    final alamatAmbil = widget.order['AlamatPengambilan'] ?? {};
    final alamatKirim = widget.order['AlamatPenyerahan'] ?? {};
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

    final distanceCalculator = const Distance();
    final double fallbackDistance = distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(storeLat, storeLon),
      LatLng(customerLat, customerLon),
    );
    final double fallbackDuration = fallbackDistance / 8.33; // motorcycle speed ~30 km/h in m/s

    final List<LatLng> fallbackPath = [
      LatLng(storeLat, storeLon),
      LatLng(customerLat, customerLon),
    ];

    setState(() {
      _isLoadingRoute = true;
      _routePoints = fallbackPath;
      _routeDistance = fallbackDistance;
      _routeDuration = fallbackDuration;
    });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$storeLon,$storeLat;$customerLon,$customerLat?overview=full&geometries=geojson',
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
            routeDuration = (firstRoute['duration'] as num).toDouble();
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
                });
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
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status.contains('jemput') || status.contains('diterima');
    final bool isEn = TranslationService.currentLang == 'en';

    // Alamat tujuan
    final alamatAmbil = widget.order['AlamatPengambilan'] ?? {};
    final alamatKirim = widget.order['AlamatPenyerahan'] ?? {};
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
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF1E88E5),
                      strokeWidth: 4.5,
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
                    // Customer marker
                    Marker(
                      point: LatLng(customerLat, customerLon),
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
                        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
                      ),
                    ),
                    // Courier current position marker (simulated live position along route points)
                    if (_routePoints.isNotEmpty)
                      Marker(
                        point: _routePoints[(_routePoints.length * 0.4).floor()],
                        width: 36,
                        height: 36,
                        child: Container(
                          padding: const EdgeInsets.all(4),
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
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 16),
                          ),
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
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
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
                  child: Text(
                    titleText,
                    style: GoogleFonts.poppins(
                      color: navyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildGlassIconButton(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    if (_routePoints.isNotEmpty) {
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(_routePoints),
                          padding: const EdgeInsets.all(50),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // 3. DRAGGABLE COURIER HUD ACTION PANEL
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
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
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ETA & Jarak
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF8FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 14, color: navyColor),
                                        const SizedBox(width: 4),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.navigation_outlined, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
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

                              // Timeline Info Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bgGrey,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: navyColor.withOpacity(0.08), width: 1.5),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(1),
                                              ),
                                            ),
                                          ),
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
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
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
                                            const SizedBox(height: 16),
                                            Column(
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
                                                ),
                                                if (detailAlamat.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${isEn ? 'Detail' : 'Catatan'}: $detailAlamat',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
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
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
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
}
