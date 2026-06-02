import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/translation_service.dart';

class PilihAlamatScreen extends StatefulWidget {
  const PilihAlamatScreen({super.key});

  @override
  State<PilihAlamatScreen> createState() => _PilihAlamatScreenState();
}

class _PilihAlamatScreenState extends State<PilihAlamatScreen> {
  final Color _navyColor = const Color(0xFF0C4B8E);
  final Color _cyanColor = const Color(0xFF42C6D4);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  // Default to Monas if no location
  LatLng _currentPosition = const LatLng(-6.1753924, 106.8271528);
  bool _isLoadingMap = true;
  String _currentAddress = '';
  
  // Search & Autocomplete State
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  Timer? _searchDebounceTimer;

  // Suggested Nearby Locations State
  List<Map<String, dynamic>> _nearbyLocations = [];
  bool _isLoadingNearby = false;

  // State to track if map is actively being dragged
  bool _isDraggingMap = false;

  @override
  void initState() {
    super.initState();
    _currentAddress = _getTxt('finding_location', 'Mencari lokasi...');
    _getUserLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Translation Helper checking active code from TranslationService
  String _getTxt(String key, String fallback) {
    // If key is present in standard TranslationService dictionary, use it
    final translated = TranslationService.translate(key);
    if (translated != key) {
      return translated;
    }
    
    // Otherwise fallback to local dual-language mapper
    final isEn = TranslationService.currentLang == 'en';
    switch (key) {
      case 'choose_via_map':
        return isEn ? 'Choose Address via Map' : 'Pilih Alamat via Peta';
      case 'search_hint':
        return isEn ? 'Search street name, building, or area...' : 'Cari nama jalan, gedung, atau area...';
      case 'deliver_here':
        return isEn ? 'Deliver here' : 'Antar ke sini';
      case 'drag_subtitle':
        return isEn ? 'Drag map to change location' : 'Geser peta untuk mengubah lokasi';
      case 'selected_location':
        return isEn ? 'Selected Location / Map Pin' : 'Lokasi Terpilih / Pin Peta';
      case 'suggested_nearby':
        return isEn ? 'Suggested Nearby Places' : 'Rekomendasi Tempat Terdekat';
      case 'confirm_location_btn':
        return isEn ? 'Confirm Map Location' : 'Konfirmasi Lokasi Peta';
      case 'location_disabled':
        return isEn ? 'Location services are disabled.' : 'Layanan lokasi tidak aktif.';
      case 'permission_denied':
        return isEn ? 'Location permission denied.' : 'Izin lokasi ditolak.';
      case 'permission_permanently_denied':
        return isEn ? 'Location permission permanently denied.' : 'Izin lokasi ditolak permanen.';
      case 'failed_load_address':
        return isEn ? 'Failed to load address.' : 'Gagal memuat alamat.';
      case 'gps_failed':
        return isEn ? 'Failed to get your GPS location.' : 'Gagal mengambil lokasi GPS Anda.';
      case 'gps_out_of_range':
        return isEn ? 'Your GPS location is outside Indonesia\'s operational range.' : 'Lokasi GPS Anda berada di luar jangkauan operasional Indonesia.';
      case 'emulator_redirect':
        return isEn ? 'GPS location detected outside Indonesia (Emulator). Redirected to Jakarta.' : 'Lokasi GPS terdeteksi di luar Indonesia (Emulator). Dialihkan ke Jakarta.';
      case 'nearby_building_fallback':
        return isEn ? 'Nearby Building / Landmark' : 'Gedung / Landskap Terdekat';
      case 'nearby_building_sub':
        return isEn ? 'Around main active pin location' : 'Sekitar area lokasi pin aktif utama';
      case 'nearby_street_fallback':
        return isEn ? 'Nearby Main Street Access' : 'Akses Jalan Utama Terdekat';
      case 'nearby_street_sub':
        return isEn ? 'Around nearest residential area' : 'Sekitar area pemukiman aktif terdekat';
      default:
        return fallback;
    }
  }

  bool _isWithinIndonesia(double lat, double lon) {
    return lat >= -11.0 && lat <= 6.0 && lon >= 95.0 && lon <= 141.0;
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingMap = false;
        _currentAddress = _getTxt('location_disabled', 'Layanan lokasi tidak aktif.');
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingMap = false;
          _currentAddress = _getTxt('permission_denied', 'Izin lokasi ditolak.');
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingMap = false;
        _currentAddress = _getTxt('permission_permanently_denied', 'Izin lokasi ditolak permanen.');
      });
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      LatLng target = LatLng(position.latitude, position.longitude);
      
      // Bounding box filter to check if GPS is outside Indonesia (e.g. California default mock coordinates)
      if (!_isWithinIndonesia(position.latitude, position.longitude)) {
        target = const LatLng(-6.1753924, 106.8271528); // Monas, Jakarta
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getTxt('emulator_redirect', 'Lokasi GPS terdeteksi di luar Indonesia (Emulator). Dialihkan ke Jakarta.'),
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              backgroundColor: _navyColor,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }

      setState(() {
        _currentPosition = target;
        _isLoadingMap = false;
      });
      _getAddressFromLatLng(_currentPosition);
    } catch (_) {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  // Combines full descriptive details of placemark beautifully to make the address fully comprehensive
  String _buildFullAddress(Placemark place) {
    final List<String> addressParts = [];
    if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
    if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!); // Kelurahan
    if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!); // Kecamatan
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) addressParts.add(place.subAdministrativeArea!); // Kota/Kabupaten
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!); // Provinsi
    if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
    
    return addressParts.isEmpty 
        ? 'Lokasi tanpa nama' 
        : addressParts.join(', ');
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = _buildFullAddress(place);
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = _getTxt('failed_load_address', 'Gagal memuat alamat.');
      });
    }

    // Automatically scan hyper-local suggested nearby recommendations
    _fetchNearbyLocations(position);
  }

  // Get contextual premium visual icons based on keywords in location name
  IconData _getContextualIcon(String name, String address) {
    final cleanName = name.toLowerCase();
    final cleanAddr = address.toLowerCase();

    if (cleanName.contains('masjid') || cleanName.contains('musholla') || cleanName.contains('mosque') ||
        cleanAddr.contains('masjid') || cleanAddr.contains('musholla')) {
      return Icons.mosque_rounded;
    }
    if (cleanName.contains('gereja') || cleanName.contains('church') || cleanAddr.contains('gereja')) {
      return Icons.church_rounded;
    }
    if (cleanName.contains('sekolah') || cleanName.contains('school') || cleanName.contains('universitas') ||
        cleanName.contains('kampus') || cleanName.contains('sd') || cleanName.contains('smp') || cleanName.contains('sma')) {
      return Icons.school_rounded;
    }
    if (cleanName.contains('rumah sakit') || cleanName.contains('rs') || cleanName.contains('hospital') ||
        cleanName.contains('klinik') || cleanName.contains('puskesmas') || cleanName.contains('apotek')) {
      return Icons.local_hospital_rounded;
    }
    if (cleanName.contains('pasar') || cleanName.contains('market') || cleanName.contains('mall') ||
        cleanName.contains('plaza') || cleanName.contains('mart') || cleanName.contains('indomaret') ||
        cleanName.contains('alfamart') || cleanName.contains('supermarket')) {
      return Icons.local_mall_rounded;
    }
    if (cleanName.contains('taman') || cleanName.contains('park') || cleanName.contains('hutan')) {
      return Icons.park_rounded;
    }
    if (cleanName.contains('stasiun') || cleanName.contains('station') || cleanName.contains('bandara') ||
        cleanName.contains('airport') || cleanName.contains('terminal')) {
      return Icons.directions_transit_rounded;
    }
    if (cleanName.contains('restoran') || cleanName.contains('rumah makan') || cleanName.contains('warung') ||
        cleanName.contains('resto') || cleanName.contains('cafe') || cleanName.contains('kopi') ||
        cleanName.contains('bakso') || cleanName.contains('soto') || cleanName.contains('kedai')) {
      return Icons.restaurant_rounded;
    }
    if (cleanName.contains('bank') || cleanName.contains('atm') || cleanName.contains('koperasi')) {
      return Icons.local_atm_rounded;
    }
    if (cleanName.contains('jalan') || cleanName.contains('jl') || cleanName.contains('gang') || cleanName.contains('gg')) {
      return Icons.edit_road_rounded;
    }
    
    return Icons.home_work_rounded;
  }

  String _formatDistance(dynamic dist) {
    if (dist == null) return '';
    final double d = dist is double ? dist : double.parse(dist.toString());
    if (d < 1000) {
      return '${d.toStringAsFixed(0)} m';
    } else {
      return '${(d / 1000).toStringAsFixed(1)} km';
    }
  }

  // Fetch hyper-local nearby suggestions around the center coordinate
  Future<void> _fetchNearbyLocations(LatLng center) async {
    setState(() {
      _isLoadingNearby = true;
    });

    final List<Map<String, dynamic>> places = [];
    final Set<String> uniqueNames = {};

    final double lat = center.latitude;
    final double lon = center.longitude;
    final double delta = 0.012; // approx 1.2km viewbox
    final double minLat = lat - delta;
    final double maxLat = lat + delta;
    final double minLon = lon - delta;
    final double maxLon = lon + delta;

    // Fetch multiple recognizable categories in parallel to get rich POIs
    final List<String> categories = ['masjid', 'restoran', 'cafe', 'mart', 'apotek', 'sekolah'];
    final List<Future<http.Response>> requests = categories.map((cat) {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(cat)}&viewbox=$minLon,$maxLat,$maxLon,$minLat&bounded=1&limit=6&accept-language=id',
      );
      return http.get(
        url,
        headers: {'User-Agent': 'WishWash-App/1.0'},
      ).timeout(const Duration(seconds: 4));
    }).toList();

    try {
      final responses = await Future.wait(requests);
      for (var response in responses) {
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          for (var item in data) {
            final String name = item['name'] ?? item['display_name']?.split(',').first ?? '';
            final String address = item['display_name'] ?? '';
            if (name.isNotEmpty && !uniqueNames.contains(name.toLowerCase())) {
              uniqueNames.add(name.toLowerCase());
              
              final double itemLat = double.tryParse(item['lat'].toString()) ?? lat;
              final double itemLon = double.tryParse(item['lon'].toString()) ?? lon;
              final double distance = Geolocator.distanceBetween(lat, lon, itemLat, itemLon);

              places.add({
                'name': name,
                'address': address,
                'position': LatLng(itemLat, itemLon),
                'distance': distance,
              });
            }
          }
        }
      }
    } catch (_) {}

    // Sort by proximity/distance
    places.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    // Fallback: If Nominatim API queries fail or return empty, fall back to our geocoding offsets
    if (places.isEmpty) {
      final List<LatLng> offsets = [
        LatLng(center.latitude + 0.0011, center.longitude + 0.0009), // Northeast
        LatLng(center.latitude - 0.0009, center.longitude - 0.0012), // Southwest
        LatLng(center.latitude + 0.0006, center.longitude - 0.0015), // Northwest
      ];

      for (int i = 0; i < offsets.length; i++) {
        try {
          final List<Placemark> placemarks = await placemarkFromCoordinates(
            offsets[i].latitude,
            offsets[i].longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            final String fullAddressString = _buildFullAddress(place);
            final String shortName = place.name ?? place.street ?? 'Jalan Sekitar';
            
            final double distance = Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              offsets[i].latitude,
              offsets[i].longitude,
            );

            places.add({
              'name': shortName,
              'address': fullAddressString,
              'position': offsets[i],
              'distance': distance,
            });
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _nearbyLocations = places.take(12).toList(); // Show up to 12 rich results
        _isLoadingNearby = false;
      });
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    setState(() {
      _currentPosition = camera.center;
      if (hasGesture) {
        _isDraggingMap = true; // Hide speech bubble card immediately on user drag
      }
      
      // Recalculate distance in real-time for all nearby locations based on the new live center
      for (int i = 0; i < _nearbyLocations.length; i++) {
        final LatLng? placePos = _nearbyLocations[i]['position'];
        if (placePos != null) {
          _nearbyLocations[i]['distance'] = Geolocator.distanceBetween(
            camera.center.latitude,
            camera.center.longitude,
            placePos.latitude,
            placePos.longitude,
          );
        }
      }
    });
    
    // Debounce reverse geocoding API to prevent excessive requests while panning map
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isDraggingMap = false; // Show speech bubble card again on pan stop
        });
      }
      _getAddressFromLatLng(_currentPosition);
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      LatLng target = LatLng(position.latitude, position.longitude);
      
      if (!_isWithinIndonesia(position.latitude, position.longitude)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getTxt('gps_out_of_range', 'Lokasi GPS Anda berada di luar jangkauan operasional Indonesia.'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }

      _mapController.move(target, 16.0);
      setState(() {
        _currentPosition = target;
      });
      _getAddressFromLatLng(target);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getTxt('gps_failed', 'Gagal mengambil lokasi GPS Anda.'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetch search recommendations from free Nominatim OpenStreetMap API
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&accept-language=id&countrycodes=id&limit=5',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'WishWash-App/1.0',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (_) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(value);
    });
  }

  void _selectSearchResult(dynamic result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final target = LatLng(lat, lon);
    
    _mapController.move(target, 16.0);
    
    setState(() {
      _currentPosition = target;
      _currentAddress = result['display_name'] ?? 'Alamat terpilih';
      _searchResults = [];
      _searchController.text = '';
    });
    
    FocusScope.of(context).unfocus();
  }

  void _selectNearbyLocation(Map<String, dynamic> place) {
    final target = place['position'] as LatLng;
    _mapController.move(target, 16.0);
    setState(() {
      _currentPosition = target;
      _currentAddress = place['address'] ?? '';
    });
    _getAddressFromLatLng(target);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSheetHeight = MediaQuery.of(context).size.height * 0.41;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // 1. OpenStreetMap Tile Engine (Offset to the visible area above the bottom sheet)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomSheetHeight,
            child: _isLoadingMap
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 16.0,
                      onPositionChanged: _onPositionChanged,
                    ),
                    children: [
                      // CartoDB Voyager premium tiles layer
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                    ],
                  ),
          ),

          // 2. Center Pin "Antar ke sini" (Centered perfectly inside the visible map area)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomSheetHeight,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0), 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: _isDraggingMap ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _cyanColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _cyanColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _getTxt('deliver_here', 'Antar ke sini'),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getTxt('drag_subtitle', 'Geser peta untuk mengubah lokasi'),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClipPath(
                            clipper: TriangleClipper(),
                            child: Container(width: 16, height: 12, color: _cyanColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.location_on, color: _cyanColor, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating App Bar + Autocomplete Search Widget
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _navyColor, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.poppins(fontSize: 14, color: _navyColor),
                          decoration: InputDecoration(
                            hintText: _getTxt('search_hint', 'Cari nama jalan, gedung, atau area...'),
                            hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.search, color: _navyColor, size: 20),
                            suffixIcon: _isSearching
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(_navyColor),
                                      ),
                                    ),
                                  )
                                : (_searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                          });
                                        },
                                      )
                                    : null),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Address Autocomplete Suggestions Dropdown List
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
                      ],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final displayName = result['display_name'] ?? '';
                        
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _cyanColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on_rounded, color: _cyanColor, size: 18),
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _navyColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. GPS Targeting Pin Button
          Positioned(
            bottom: bottomSheetHeight + 16,
            right: 16,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(Icons.my_location_rounded, color: _navyColor, size: 24),
              ),
            ),
          ),

          // 5. Expandable Premium Bottom Sheet with Suggested Nearby Places
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: bottomSheetHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle Bar Indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Primary Selected Address Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _cyanColor, width: 6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTxt('selected_location', 'Lokasi Terpilih / Pin Peta'),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _navyColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),

                  // Suggested Nearby Places Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: _cyanColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _getTxt('suggested_nearby', 'Rekomendasi Tempat Terdekat'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Suggested Nearby Places List
                  Expanded(
                    child: _isLoadingNearby
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            itemCount: _nearbyLocations.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final place = _nearbyLocations[index];
                              final placeName = place['name'] ?? '';
                              final placeAddr = place['address'] ?? '';
                              
                              return GestureDetector(
                                onTap: () => _selectNearbyLocation(place),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black12.withValues(alpha: 0.05), blurRadius: 4),
                                          ],
                                        ),
                                        child: Icon(
                                          _getContextualIcon(placeName, placeAddr),
                                          color: _cyanColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    placeName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: _navyColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (place['distance'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatDistance(place['distance']),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _cyanColor,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              placeAddr,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Confirmation Button
                  SafeArea(
                    top: false,
                    bottom: true,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'alamat': _currentAddress,
                            'latitude': _currentPosition.latitude.toString(),
                            'longitude': _currentPosition.longitude.toString(),
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navyColor,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _getTxt('confirm_location_btn', 'Konfirmasi Lokasi Peta'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}
