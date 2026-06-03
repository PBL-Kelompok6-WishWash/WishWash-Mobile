import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/utils/constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class KaryawanTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const KaryawanTrackingScreen({super.key, required this.order});

  @override
  State<KaryawanTrackingScreen> createState() => _KaryawanTrackingScreenState();
}

class _KaryawanTrackingScreenState extends State<KaryawanTrackingScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color softTeal = const Color(0xFFBCEFF2);
  final Color bgGrey = const Color(0xFFF8FBFC);

  static final Set<int> _activeTripOrderIds = {};
  bool _showStartAlert = false;
  bool _isUpdating = false;
  bool _isRouteActive = false;
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  bool _isLoadingRoute = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final orderId = widget.order['id_order'] as int? ?? 0;
    _isRouteActive = _activeTripOrderIds.contains(orderId);
    _fetchRoutePoints();
  }

  Future<void> _fetchRoutePoints() async {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status == 'penjemputan' || status == 'pesanan diterima';
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

    debugPrint('OSRM input coords: store($storeLat, $storeLon) -> customer($customerLat, $customerLon), hasCoords: $hasCoords');
    debugPrint('OSRM fallbackDistance: $fallbackDistance, fallbackDuration: $fallbackDuration');

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
          debugPrint('OSRM firstRoute keys: ${firstRoute.keys.toList()}');
          debugPrint('OSRM distance raw: ${firstRoute['distance']} (${firstRoute['distance'].runtimeType})');
          debugPrint('OSRM duration raw: ${firstRoute['duration']} (${firstRoute['duration'].runtimeType})');
          
          double routeDistance = 0.0;
          double routeDuration = 0.0;

          if (firstRoute.containsKey('distance') && firstRoute['distance'] != null) {
            routeDistance = (firstRoute['distance'] as num).toDouble();
          } else {
            final legs = firstRoute['legs'] as List?;
            if (legs != null && legs.isNotEmpty) {
              final firstLeg = legs.first as Map?;
              if (firstLeg != null && firstLeg.containsKey('distance')) {
                routeDistance = (firstLeg['distance'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }

          if (firstRoute.containsKey('duration') && firstRoute['duration'] != null) {
            routeDuration = (firstRoute['duration'] as num).toDouble();
          } else {
            final legs = firstRoute['legs'] as List?;
            if (legs != null && legs.isNotEmpty) {
              final firstLeg = legs.first as Map?;
              if (firstLeg != null && firstLeg.containsKey('duration')) {
                routeDuration = (firstLeg['duration'] as num?)?.toDouble() ?? 0.0;
              }
            }
          }

          if (routeDistance == 0.0) {
            routeDistance = fallbackDistance;
          }
          if (routeDuration == 0.0) {
            routeDuration = fallbackDuration;
          }
          
          debugPrint('OSRM distance parsed: $routeDistance, duration parsed: $routeDuration');
          
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
      debugPrint('Error fetching route from OSRM: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _launchGoogleMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final bool isEn = TranslationService.currentLang == 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Could not open Google Maps' : 'Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  void _showStartTripConfirmationDialog() {
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status == 'penjemputan' || status == 'pesanan diterima';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    Icons.navigation_rounded,
                    color: navyColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final orderId = widget.order['id_order'] as int? ?? 0;
                      _activeTripOrderIds.add(orderId);
                      setState(() {
                        _isRouteActive = true;
                        _showStartAlert = true;
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            _showStartAlert = false;
                          });
                        }
                      });
                      // Launch Maps
                      _launchGoogleMaps(isPickup 
                          ? (widget.order['AlamatPengambilan'] ?? {})['alamat_lengkap'] ?? 'Alamat Pelanggan'
                          : (widget.order['AlamatPenyerahan'] ?? {})['alamat_lengkap'] ?? 'Alamat Pelanggan');
                    },
                    child: Text(
                      isEn ? 'Yes, Start Now' : 'Ya, Mulai Sekarang',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEn ? 'Cancel' : 'Batal',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
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
    final bool isPickup = status == 'penjemputan' || status == 'pesanan diterima';
    final bool isEn = TranslationService.currentLang == 'en';
    
    final String title = isPickup 
        ? (isEn ? 'Confirm Pickup Completed?' : 'Konfirmasi Selesai Penjemputan?')
        : (isEn ? 'Confirm Delivery Completed?' : 'Konfirmasi Selesai Diantar?');
    final String desc = isPickup 
        ? (isEn 
            ? 'Are you sure you have completed picking up the laundry from this customer?'
            : 'Apakah Anda yakin telah menyelesaikan penjemputan cucian dari pelanggan ini?')
        : (isEn 
            ? 'Are you sure the laundry has been successfully handed over to the customer?'
            : 'Apakah Anda yakin cucian telah berhasil diserahkan ke pelanggan?');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    isPickup ? Icons.local_shipping_rounded : Icons.task_alt_rounded,
                    color: navyColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmArrival();
                    },
                    child: Text(
                      isPickup 
                          ? (isEn ? 'Yes, Finished Pickup' : 'Ya, Selesai Jemput') 
                          : (isEn ? 'Yes, Finished Delivery' : 'Ya, Selesai Antar'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEn ? 'Cancel' : 'Batal',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
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
    String nextStatus = 'proses timbang';
    String successMsg = isEn 
        ? 'You have arrived at the pickup location!' 
        : 'Anda telah sampai di lokasi penjemputan!';

    if (status == 'siap diantar') {
      nextStatus = 'selesai';
      successMsg = isEn 
          ? 'Laundry successfully delivered to customer!' 
          : 'Cucian berhasil diantarkan ke pelanggan!';
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedOrder = await OrderService.updateOrder(
        widget.order['id_order'],
        {'status': nextStatus},
      );
      if (mounted) {
        _activeTripOrderIds.remove(widget.order['id_order']);
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, updatedOrder);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Failed to update status: $e' : 'Gagal memperbarui status: $e'), 
            backgroundColor: Colors.red,
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
    final pelanggan = widget.order['Pelanggan'] ?? {};
    final customerName = pelanggan['nama_lengkap'] ?? 'Pelanggan';
    final customerPhone = (pelanggan['no_telp'] ?? pelanggan['no_hp'] ?? pelanggan['NoTelp'] ?? '-').toString();
    
    final status = _getOrderStatus(widget.order).toLowerCase();
    final bool isPickup = status == 'penjemputan' || status == 'pesanan diterima';

    // Alamat tujuan kurir
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

    final String titleText = isPickup ? 'Navigasi Penjemputan' : 'Navigasi Pengantaran';
    final String actionButtonText = _isRouteActive
        ? (isPickup ? 'Konfirmasi Selesai Penjemputan' : 'Konfirmasi Selesai Diantar')
        : (isPickup ? 'Mulai Penjemputan' : 'Mulai Pengantaran');
    final IconData actionButtonIcon = _isRouteActive
        ? Icons.check_circle_outline_rounded
        : Icons.navigation_rounded;

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
      // Mock offset for preview safety
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
              key: ValueKey('tracking_map_${customerLat}_${customerLon}'),
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
                    // Courier current position marker (only shown when route is active)
                    if (_isRouteActive)
                      Marker(
                        point: _routePoints.isNotEmpty
                            ? _routePoints.first
                            : LatLng(storeLat, storeLon),
                        width: 32,
                        height: 32,
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
                            child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 14),
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
                    } else {
                      _mapController.move(
                        LatLng(
                          (storeLat + customerLat) / 2,
                          (storeLon + customerLon) / 2,
                        ),
                        initialZoom,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // 4. FLOATING TOP TOAST ALERT
          if (_showStartAlert)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showStartAlert ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          TranslationService.currentLang == 'en'
                              ? 'Trip started! Safe travels!'
                              : 'Perjalanan dimulai! Hati-hati di jalan!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. DRAGGABLE COURIER HUD ACTION PANEL
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.15,
            maxChildSize: 0.85,
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
                    // Fixed drag handle indicator at the top
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

                    // Expanded Scrollable content area
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Travel stats (ETA & Distance)
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
                                          (() {
                                            final int minutes = (_routeDuration / 60).round();
                                            final bool isEn = TranslationService.currentLang == 'en';
                                            final String hrStr = isEn ? 'Hr' : 'Jam';
                                            final String minStr = isEn ? 'Min' : 'Mnt';
                                            if (minutes > 60) {
                                              final int hours = minutes ~/ 60;
                                              final int remainingMinutes = minutes % 60;
                                              if (remainingMinutes > 0) {
                                                return '$hours $hrStr $remainingMinutes $minStr';
                                              } else {
                                                return '$hours $hrStr';
                                              }
                                            } else {
                                              return '${minutes < 1 ? 1 : minutes} $minStr';
                                            }
                                          })(),
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
                              const SizedBox(height: 12),

                               // Route Card (Gojek / Grab POV style - Connected Vertical Timeline)
                               (() {
                                 final addrObj = isPickup ? alamatAmbil : alamatKirim;
                                 final String recipientName = (addrObj['nama_penerima'] ?? '').toString();
                                 final String recipientPhone = (addrObj['nohp_penerima'] ?? addrObj['no_telp_penerima'] ?? addrObj['no_hp_penerima'] ?? addrObj['no_telp'] ?? addrObj['no_hp'] ?? pelanggan['no_telp'] ?? pelanggan['no_hp'] ?? pelanggan['NoTelp'] ?? '').toString();
                                 String detailAlamat = (addrObj['detail_alamat'] ?? addrObj['detail'] ?? '').toString();
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
                                   child: IntrinsicHeight(
                                     child: Row(
                                       crossAxisAlignment: CrossAxisAlignment.stretch,
                                       children: [
                                         // Left timeline column: icon - line - icon
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
                                         // Right content column
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                             children: [
                                               // Start: Outlet
                                               Column(
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
                                               const SizedBox(height: 16),
                                               // End: Target Address
                                               Column(
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
                                                   if (detailAlamat.isNotEmpty) ...
                                                   [
                                                     const SizedBox(height: 4),
                                                     Row(
                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                       children: [
                                                         Padding(
                                                           padding: const EdgeInsets.only(top: 2),
                                                           child: Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey.shade500),
                                                         ),
                                                         const SizedBox(width: 4),
                                                         Expanded(
                                                           child: Text(
                                                             'Detail: $detailAlamat',
                                                             style: GoogleFonts.poppins(
                                                               fontSize: 11,
                                                               color: Colors.grey.shade600,
                                                               height: 1.3,
                                                             ),
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ],
                                                   if (recipientName.isNotEmpty) ...
                                                   [
                                                     const SizedBox(height: 6),
                                                     Row(
                                                       children: [
                                                         Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey.shade500),
                                                         const SizedBox(width: 4),
                                                         Text(
                                                           recipientName,
                                                           style: GoogleFonts.poppins(
                                                             fontSize: 11,
                                                             fontWeight: FontWeight.w600,
                                                             color: Colors.grey.shade700,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ],
                                                   if (recipientPhone.isNotEmpty) ...
                                                   [
                                                     const SizedBox(height: 2),
                                                     Row(
                                                       children: [
                                                         Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                                                         const SizedBox(width: 4),
                                                         Text(
                                                           recipientPhone,
                                                           style: GoogleFonts.poppins(
                                                             fontSize: 11,
                                                             color: Colors.grey.shade600,
                                                           ),
                                                         ),
                                                       ],
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
                                 );
                               })(),
                               const SizedBox(height: 12),

                               // Customer Quick Info Card
                              Row(
                                children: [
                                  // Dynamic Customer Avatar from Database
                                  (() {
                                    final String rawFoto = (pelanggan['foto_pelanggan'] ?? '').toString();
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

                                    // Determine avatar initials from name
                                    final List<String> nameParts = customerName.trim().split(' ');
                                    final String initials = nameParts.length >= 2
                                        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                                        : (nameParts.isNotEmpty && nameParts[0].isNotEmpty
                                            ? nameParts[0][0].toUpperCase()
                                            : '?');

                                    return Container(
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
                                                loadingBuilder: (ctx, child, progress) {
                                                  if (progress == null) return child;
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white.withOpacity(0.7),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (ctx, err, stack) => Center(
                                                  child: Text(
                                                    initials,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
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
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                    );
                                  })(),
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
                                  // Direct Chat/SMS Button
                                  GestureDetector(
                                    onTap: () async {
                                      final Uri launchUri = Uri(
                                        scheme: 'sms',
                                        path: customerPhone,
                                      );
                                      if (await canLaunchUrl(launchUri)) {
                                        await launchUrl(launchUri);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tidak dapat membuka aplikasi SMS')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cyanColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cyanColor.withOpacity(0.2), width: 1),
                                      ),
                                      child: Icon(Icons.chat_bubble_rounded, color: navyColor, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Sticky Primary Action Button fixed at the bottom of sheet
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (!_isRouteActive || isPickup) ? navyColor : Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: ((!_isRouteActive || isPickup) ? navyColor : Colors.green.shade700).withOpacity(0.3),
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
                              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(actionButtonIcon, size: 20),
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

  Widget _buildInteractiveMockMap() {
    return Container(
      color: const Color(0xFFF1F5F9), // Beautiful clean cool-slate background
      child: CustomPaint(
        painter: MapPainter(navyColor: navyColor, cyanColor: cyanColor),
      ),
    );
  }
}

// Custom Painter to draw a gorgeous, high-fidelity mock vector road and tracking path!
class MapPainter extends CustomPainter {
  final Color navyColor;
  final Color cyanColor;

  MapPainter({required this.navyColor, required this.cyanColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Parks (Green Spaces)
    final parkPaint = Paint()..color = const Color(0xFFDCF2E4);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.12, 110, 80), const Radius.circular(16)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.52, size.height * 0.52, 90, 110), const Radius.circular(16)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.72, 70, 70), const Radius.circular(12)), parkPaint);

    // 2. Draw River (Blue Winding line)
    final riverPaint = Paint()
      ..color = const Color(0xFFD0E1FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    Path river = Path();
    river.moveTo(0, size.height * 0.85);
    river.quadraticBezierTo(size.width * 0.4, size.height * 0.76, size.width * 0.7, size.height * 0.9);
    river.lineTo(size.width, size.height * 0.85);
    canvas.drawPath(river, riverPaint);

    // 3. Draw Buildings (light gray blocks)
    final bldgPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.48, 50, 40), const Radius.circular(6)), bldgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.75, size.height * 0.15, 60, 50), const Radius.circular(6)), bldgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.8, size.height * 0.65, 45, 60), const Radius.circular(6)), bldgPaint);

    // 4. Roads Styling & Painting
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF1E88E5) // Premium maps active blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw some structural mockup roads
    Path roads = Path();
    roads.moveTo(size.width * 0.15, size.height * 0.1);
    roads.lineTo(size.width * 0.15, size.height * 0.7);
    roads.lineTo(size.width * 0.65, size.height * 0.7);
    roads.lineTo(size.width * 0.65, size.height * 0.3);
    roads.lineTo(size.width * 0.9, size.height * 0.3);

    // Cross roads
    roads.moveTo(0, size.height * 0.45);
    roads.lineTo(size.width, size.height * 0.45);

    roads.moveTo(size.width * 0.4, 0);
    roads.lineTo(size.width * 0.4, size.height);

    canvas.drawPath(roads, roadBorderPaint);
    canvas.drawPath(roads, roadPaint);

    // Draw active driver navigation route
    Path activeRoute = Path();
    activeRoute.moveTo(size.width * 0.65, size.height * 0.65); // Starting near outlet
    activeRoute.lineTo(size.width * 0.65, size.height * 0.45);
    activeRoute.lineTo(size.width * 0.15, size.height * 0.45);
    activeRoute.lineTo(size.width * 0.15, size.height * 0.2); // Near customer destination

    canvas.drawPath(activeRoute, routePaint);

    // Draw destination pin (Red Pin)
    final pinPaint = Paint()..color = Colors.redAccent;
    final centerDest = Offset(size.width * 0.15, size.height * 0.2);
    canvas.drawCircle(centerDest, 10, pinPaint);
    canvas.drawCircle(centerDest, 4, Paint()..color = Colors.white);

    // Draw Courier current position (Blue Circle/Pill)
    final driverPaint = Paint()..color = const Color(0xFF1E88E5);
    final centerDriver = Offset(size.width * 0.45, size.height * 0.45);
    canvas.drawCircle(centerDriver, 12, driverPaint);
    canvas.drawCircle(centerDriver, 14, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(centerDriver, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
