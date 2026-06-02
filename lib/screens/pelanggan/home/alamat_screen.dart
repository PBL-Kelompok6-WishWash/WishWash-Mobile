import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/pelanggan/home/tambah_alamat_screen.dart';
import 'package:mobile/screens/pelanggan/home/pilih_alamat_screen.dart';
import 'package:mobile/services/alamat_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:mobile/widgets/custom_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class AlamatScreen extends StatefulWidget {
  const AlamatScreen({super.key});

  @override
  State<AlamatScreen> createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);
  final Color bgColor = const Color(0xFFF8FBFC);

  List<dynamic> _alamatList = [];
  bool _isLoading = true;

  // Search & Autocomplete State
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;
  String _searchQuery = '';

  // Suggested Nearby Locations State
  List<Map<String, dynamic>> _suggestedNearby = [];
  bool _isLoadingSuggested = false;

  double? _mapLat;
  double? _mapLon;

  @override
  void initState() {
    super.initState();
    _fetchAlamat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlamat() async {
    setState(() => _isLoading = true);
    try {
      final alamats = await AlamatService.getAlamat();
      setState(() {
        _alamatList = alamats;
        _isLoading = false;
      });
      _loadSuggestedNearby();
    } catch (e) {
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: 'Error',
          message: e.toString(),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSuggestedNearby() async {
    if (!mounted) return;
    setState(() => _isLoadingSuggested = true);
    try {
      double? lat;
      double? lon;
      String referenceAddress = '';

      // 1. Try to get coordinates from primary address
      final primary = _alamatList.firstWhere((a) => a['is_primary'] == true, orElse: () => null);
      if (primary != null && primary['latitude'] != null && primary['longitude'] != null) {
        lat = double.tryParse(primary['latitude'].toString());
        lon = double.tryParse(primary['longitude'].toString());
        referenceAddress = primary['alamat_lengkap'] ?? '';
      }

      // 2. If no primary, fetch current GPS
      if (lat == null || lon == null) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
            lat = position.latitude;
            lon = position.longitude;
          }
        }
      }

      // 3. Fallback to Monas
      lat ??= -6.1753924;
      lon ??= 106.8271528;

      // Reverse geocode fallback if referenceAddress is still empty to populate realistic address parts
      if (referenceAddress.isEmpty) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            referenceAddress = _buildFullAddressHelper(placemarks[0]);
          }
        } catch (_) {}
      }

      final List<Map<String, dynamic>> places = [];
      final Set<String> uniqueNames = {};

      final double delta = 0.012; // approx 1.2km viewbox
      final double minLat = lat - delta;
      final double maxLat = lat + delta;
      final double minLon = lon - delta;
      final double maxLon = lon + delta;

      // Fetch high-quality POIs in a single Overpass API request (Rate-limit free & extremely fast)
      try {
        final overpassUrl = 'https://overpass-api.de/api/interpreter?data='
            '${Uri.encodeComponent('[out:json][timeout:5];(node["amenity"~"place_of_worship|restaurant|cafe|pharmacy|school|fast_food"](around:1200,$lat,$lon);node["shop"~"supermarket|convenience"](around:1200,$lat,$lon););out body 15;')}';
        final response = await http.get(
          Uri.parse(overpassUrl),
          headers: {'User-Agent': 'WishWash-App/1.0'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final Map<String, dynamic> decoded = jsonDecode(response.body);
          final List<dynamic> elements = decoded['elements'] ?? [];
          for (var element in elements) {
            final Map<String, dynamic> tags = element['tags'] ?? {};
            final String name = tags['name'] ?? '';
            if (name.isNotEmpty && !uniqueNames.contains(name.toLowerCase())) {
              uniqueNames.add(name.toLowerCase());
              final double itemLat = double.tryParse(element['lat'].toString()) ?? lat;
              final double itemLon = double.tryParse(element['lon'].toString()) ?? lon;
              final double distance = Geolocator.distanceBetween(lat, lon, itemLat, itemLon);

              // Construct premium GMaps style category display label in Indonesian
              String categoryLabel = '';
              if (tags['amenity'] != null) {
                final String am = tags['amenity'].toString().toLowerCase();
                if (am == 'place_of_worship') {
                  categoryLabel = 'Masjid/Rumah Ibadah';
                } else if (am == 'restaurant' || am == 'fast_food') {
                  categoryLabel = 'Restoran/Kuliner';
                } else if (am == 'cafe') {
                  categoryLabel = 'Kafe';
                } else if (am == 'pharmacy') {
                  categoryLabel = 'Apotek';
                } else if (am == 'school') {
                  categoryLabel = 'Sekolah/Universitas';
                } else {
                  categoryLabel = am;
                }
              } else if (tags['shop'] != null) {
                categoryLabel = 'Minimarket/Toko';
              } else {
                categoryLabel = 'Tempat Terdekat';
              }

              // Extract full address tags if available in OSM
              final String street = tags['addr:street'] ?? tags['road'] ?? '';
              final String housenumber = tags['addr:housenumber'] ?? '';
              final String suburb = tags['addr:suburb'] ?? tags['suburb'] ?? tags['addr:hamlet'] ?? '';
              final String city = tags['addr:city'] ?? tags['city'] ?? '';

              List<String> addrParts = [];
              if (street.isNotEmpty) {
                String streetStr = street.toLowerCase().startsWith('jl') ? street : 'Jl. $street';
                if (housenumber.isNotEmpty) {
                  streetStr += ' No. $housenumber';
                }
                addrParts.add(streetStr);
              }
              if (suburb.isNotEmpty) {
                addrParts.add(suburb);
              }
              if (city.isNotEmpty) {
                addrParts.add(city);
              }

              String displayAddress = '';
              if (addrParts.isNotEmpty) {
                displayAddress = addrParts.join(', ');
              } else {
                // Intelligent fallback: Parse reference address parts to construct a complete surrounding address
                if (referenceAddress.isNotEmpty && !referenceAddress.contains('Gagal memuat') && !referenceAddress.contains('Mencari lokasi')) {
                  final parts = referenceAddress.split(',');
                  if (parts.length >= 3) {
                    displayAddress = '${parts[0].trim()}, ${parts[1].trim()}, ${parts[2].trim()}';
                  } else if (parts.length >= 2) {
                    displayAddress = '${parts[0].trim()}, ${parts[1].trim()}';
                  } else {
                    displayAddress = referenceAddress;
                  }
                } else {
                  displayAddress = 'Sekitar area terpilih';
                }
              }

              places.add({
                'name': name,
                'alamat_lengkap': displayAddress,
                'latitude': itemLat.toString(),
                'longitude': itemLon.toString(),
                'distance': distance,
              });
            }
          }
        }
      } catch (_) {}

      // Fallback: If Overpass fails, use a sequential, spaced-out Nominatim query (to avoid rate-limiting)
      if (places.isEmpty) {
        final List<String> categories = ['masjid', 'restoran', 'cafe', 'mart', 'apotek', 'sekolah'];
        for (var cat in categories) {
          if (!mounted) break;
          try {
            final url = Uri.parse(
              'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(cat)}&viewbox=$minLon,$maxLat,$maxLon,$minLat&bounded=1&limit=4&accept-language=id',
            );
            final response = await http.get(
              url,
              headers: {'User-Agent': 'WishWash-App/1.0'},
            ).timeout(const Duration(seconds: 3));

            if (response.statusCode == 200) {
              final List<dynamic> data = jsonDecode(response.body);
              for (var item in data) {
                final String name = item['name'] ?? item['display_name']?.split(',').first ?? '';
                final String addressStr = item['display_name'] ?? '';
                if (name.isNotEmpty && !uniqueNames.contains(name.toLowerCase())) {
                  uniqueNames.add(name.toLowerCase());
                  
                  final double itemLat = double.tryParse(item['lat'].toString()) ?? lat;
                  final double itemLon = double.tryParse(item['lon'].toString()) ?? lon;
                  final double distance = Geolocator.distanceBetween(lat, lon, itemLat, itemLon);

                  places.add({
                    'name': name,
                    'alamat_lengkap': addressStr,
                    'latitude': itemLat.toString(),
                    'longitude': itemLon.toString(),
                    'distance': distance,
                  });
                }
              }
            }
          } catch (_) {}
          // Spacing of 300ms to guarantee no rate limiting on OSM Nominatim
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // Fallback 2: Reverse-geocoder on geographic offsets if web results are still empty
      if (places.isEmpty) {
        // Call OSM Nominatim reverse geocoder for hyper-local nearby places
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1&accept-language=id',
        );
        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'WishWash-App/1.0',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final String displayName = data['display_name'] ?? 'Lokasi Terdekat';
          final String name = data['name'] ?? data['address']?['road'] ?? 'Tempat Terdekat';

          places.add({
            'name': name,
            'alamat_lengkap': displayName,
            'latitude': lat.toString(),
            'longitude': lon.toString(),
            'distance': 0.0,
          });
        }

        // Add 2 neighborhood offsets to suggest places nearby
        final listOffsets = [
          {'lat': lat + 0.0011, 'lon': lon + 0.0009, 'name': 'Gedung / Landskap Terdekat', 'sub': 'Sekitar area lokasi utama'},
          {'lat': lat - 0.0009, 'lon': lon - 0.0012, 'name': 'Akses Jalan Utama Terdekat', 'sub': 'Sekitar area pemukiman'},
        ];

        for (var offset in listOffsets) {
          try {
            final resOffset = await http.get(
              Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${offset['lat']}&lon=${offset['lon']}&zoom=18&addressdetails=1&accept-language=id'),
              headers: {'User-Agent': 'WishWash-App/1.0'},
            ).timeout(const Duration(seconds: 3));
            
            if (resOffset.statusCode == 200) {
              final Map<String, dynamic> data = jsonDecode(resOffset.body);
              final String displayName = data['display_name'] ?? 'Lokasi Terdekat';
              final String name = data['name'] ?? data['address']?['road'] ?? offset['name'].toString();
              
              final double itemLat = double.tryParse(offset['lat'].toString()) ?? lat;
              final double itemLon = double.tryParse(offset['lon'].toString()) ?? lon;
              final double distance = Geolocator.distanceBetween(lat, lon, itemLat, itemLon);

              places.add({
                'name': name,
                'alamat_lengkap': displayName,
                'latitude': offset['lat'].toString(),
                'longitude': offset['lon'].toString(),
                'distance': distance,
              });
            }
          } catch (_) {}
        }
      }

      // Sort suggested places by proximity
      places.sort((a, b) {
        final double distA = a['distance'] != null ? double.parse(a['distance'].toString()) : 999999.0;
        final double distB = b['distance'] != null ? double.parse(b['distance'].toString()) : 999999.0;
        return distA.compareTo(distB);
      });

      if (mounted) {
        setState(() {
          _mapLat = lat;
          _mapLon = lon;
          _suggestedNearby = places.take(12).toList();
          _isLoadingSuggested = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSuggested = false);
      }
    }
  }

  String _buildFullAddressHelper(Placemark place) {
    final List<String> addressParts = [];
    if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
    if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!); // Kelurahan
    if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!); // Kecamatan
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) addressParts.add(place.subAdministrativeArea!); // Kota/Kabupaten
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!); // Provinsi
    if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
    return addressParts.isEmpty ? 'Lokasi tanpa nama' : addressParts.join(', ');
  }

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

    // 1. Try Native Device Geocoder (Incredibly fast, zero rate limit, uses Google/Apple system services)
    try {
      // Append ", Indonesia" to narrow down search to Indonesia regions only
      final String indonesianQuery = query.toLowerCase().contains("indonesia") ? query : "$query, Indonesia";
      final List<Location> locations = await locationFromAddress(indonesianQuery);
      if (locations.isNotEmpty) {
        final List<Map<String, dynamic>> results = [];
        for (var loc in locations.take(5)) {
          // Bounding box filter to ensure search coordinates are strictly within Indonesia
          if (loc.latitude < -11.0 || loc.latitude > 6.0 || loc.longitude < 95.0 || loc.longitude > 141.0) {
            continue;
          }
          try {
            final List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
            if (placemarks.isNotEmpty) {
              final place = placemarks[0];
              final String fullAddress = _buildFullAddressHelper(place);
              
              // Filter out cryptic Plus Codes (e.g. "WCWM+XRJ") to display beautiful human-readable names
              String shortName = place.name ?? '';
              if (shortName.contains('+') || shortName.length <= 4) {
                shortName = place.street ?? place.thoroughfare ?? place.locality ?? query;
              }
              if (shortName.trim().isEmpty) {
                shortName = query;
              }
              
              results.add({
                'name': shortName,
                'display_name': '$shortName, $fullAddress',
                'lat': loc.latitude.toString(),
                'lon': loc.longitude.toString(),
              });
            }
          } catch (_) {
            results.add({
              'name': query,
              'display_name': 'Koordinat GPS - ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
              'lat': loc.latitude.toString(),
              'lon': loc.longitude.toString(),
            });
          }
        }

        if (results.isNotEmpty) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Native Geocoder (AlamatScreen) failed: $e. Falling back to OSM...");
    }

    // 2. Fallback: HTTP OpenStreetMap Nominatim API
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&accept-language=id&countrycodes=id&limit=8',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'WishWashLaundryCustomerAppPBLSemarangProject-v1.0.2',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data;
          _isSearching = false;
        });
      } else {
        debugPrint("Nominatim API response status code (AlamatScreen): ${response.statusCode}");
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Nominatim Search Error (AlamatScreen): $e");
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _setPrimary(int idAlamat) async {
    try {
      final success = await AlamatService.setPrimaryAlamat(idAlamat);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: TranslationService.currentLang == 'en' ? 'Failed' : 'Gagal',
          message: TranslationService.currentLang == 'en'
              ? 'Failed to set primary address: $e'
              : 'Gagal mengatur alamat utama: $e',
        );
      }
    }
  }

  Future<void> _deleteAlamat(int idAlamat) async {
    final confirm = await CustomDialog.showConfirm(
      context: context,
      title: TranslationService.currentLang == 'en' ? 'Delete Address' : 'Hapus Alamat',
      message: TranslationService.currentLang == 'en'
          ? 'Are you sure you want to delete this address from the list?'
          : 'Apakah Anda yakin ingin menghapus alamat ini dari daftar?',
      confirmText: TranslationService.currentLang == 'en' ? 'Delete' : 'Hapus',
      cancelText: TranslationService.currentLang == 'en' ? 'Cancel' : 'Batal',
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await AlamatService.deleteAlamat(idAlamat);
      if (success && mounted) {
        CustomDialog.showSuccess(
          context: context,
          title: TranslationService.currentLang == 'en' ? 'Delete Success' : 'Hapus Berhasil',
          message: TranslationService.currentLang == 'en'
              ? 'Your address has been successfully deleted from the system.'
              : 'Alamat Anda telah berhasil dihapus dari sistem.',
        );
        _fetchAlamat();
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showError(
          context: context,
          title: TranslationService.currentLang == 'en' ? 'Failed to Delete' : 'Gagal Menghapus',
          message: e.toString(),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.0, // Ensures header stays pure white even when scrolling content underneath
            titleSpacing: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Container(
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20), // More professional capsule design
                border: Border.all(color: Colors.grey.shade200, width: 1.0),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center, // Centers input text vertically
                style: GoogleFonts.poppins(fontSize: 13, color: navyColor),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                  _searchDebounceTimer?.cancel();
                  _searchDebounceTimer = Timer(const Duration(milliseconds: 600), () {
                    _searchAddress(val);
                  });
                },
                decoration: InputDecoration(
                  isDense: true, // Optimizes vertical spacing
                  hintText: TranslationService.translate('search_location'),
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10), // Perfectly balanced padding
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.map_outlined, color: cyanColor, size: 26),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PilihAlamatScreen()),
                  );
                  if (result != null && result is Map) {
                    final Map<String, dynamic> mockAlamat = {
                      'alamat_lengkap': result['alamat'],
                      'latitude': result['latitude'],
                      'longitude': result['longitude'],
                      'tipe_alamat': 'Rumah',
                    };
                    if (mounted) {
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: mockAlamat)),
                      );
                      if (added == true) {
                        _fetchAlamat();
                      }
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: cyanColor))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchQuery.trim().isNotEmpty) ...[
                        _buildOnlineSearchResultsSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildMapPreviewCard(context),
                      const SizedBox(height: 12),
                      _buildMyAddressSection(context),
                      const SizedBox(height: 16),
                      _buildSuggestedLocationsSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOnlineSearchResultsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              TranslationService.currentLang == 'en' ? 'Online Search Results' : 'Hasil Pencarian Online',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navyColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: cyanColor)),
            )
          else if (_searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  TranslationService.currentLang == 'en' ? 'No locations found online' : 'Tidak ada lokasi ditemukan online',
                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (context, idx) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                final String name = item['name'] ?? 'Jalan / Area';
                final String address = item['display_name'] ?? '';

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cyanColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on, color: cyanColor, size: 20),
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    address,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    final Map<String, dynamic> mockAlamat = {
                      'alamat_lengkap': address,
                      'latitude': item['lat'] ?? '-6.1753924',
                      'longitude': item['lon'] ?? '106.8271528',
                      'tipe_alamat': 'Rumah',
                    };
                    final added = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: mockAlamat)),
                    );
                    if (added == true) {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _searchResults = [];
                      });
                      _fetchAlamat();
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMyAddressSection(BuildContext context) {
    // Filter local saved addresses by search query if present
    final filteredList = _searchQuery.trim().isEmpty
        ? _alamatList
        : _alamatList.where((alamat) {
            final addr = (alamat['alamat_lengkap'] ?? '').toString().toLowerCase();
            final tag = (alamat['tipe_alamat'] ?? '').toString().toLowerCase();
            final name = (alamat['nama_penerima'] ?? '').toString().toLowerCase();
            final q = _searchQuery.trim().toLowerCase();
            return addr.contains(q) || tag.contains(q) || name.contains(q);
          }).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationService.translate('my_address'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TambahAlamatScreen()),
                    );
                    if (result == true) {
                      _fetchAlamat(); // Refresh list jika berhasil nambah
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle, color: navyColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        TranslationService.translate('add_new_address'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
          if (filteredList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  _searchQuery.trim().isEmpty
                      ? TranslationService.translate('no_saved_addresses')
                      : (TranslationService.currentLang == 'en' ? 'No matching saved addresses' : 'Tidak ada alamat tersimpan yang cocok'),
                  style: GoogleFonts.poppins(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...filteredList.map((alamat) {
              final String tipe = alamat['tipe_alamat'] ?? 'Rumah';
              String displayLabel = tipe;
              if (tipe == 'Rumah') {
                displayLabel = TranslationService.translate('home_tag');
              } else if (tipe == 'Kantor') {
                displayLabel = TranslationService.translate('office_tag');
              } else if (tipe == 'Lainnya') {
                displayLabel = TranslationService.translate('other_tag');
              }

              return Column(
                children: [
                  _buildSavedAddressItem(
                    alamat: alamat,
                    icon: tipe == 'Kantor' 
                        ? Icons.business_outlined 
                        : (tipe == 'Rumah' ? Icons.home_outlined : Icons.bookmark_border_rounded),
                    label: displayLabel,
                    isPrimary: alamat['is_primary'] ?? false,
                    address: alamat['alamat_lengkap'] ?? '',
                    contact: '${alamat['nama_penerima'] ?? ''} | ${alamat['nohp_penerima'] ?? ''}',
                  ),
                  Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSavedAddressItem({
    required Map<String, dynamic> alamat,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required String address,
    required String contact,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPrimary(alamat['id_alamat']),
        splashColor: cyanColor.withOpacity(0.12),
        highlightColor: cyanColor.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Icon(icon, color: navyColor, size: 24),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Address Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: navyColor,
                          ),
                        ),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cyanColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: cyanColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              TranslationService.translate('last_used'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cyanColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Address details cleanly rendered
                    (() {
                      String mainAddr = address;
                      String noteAddr = '';
                      if (address.contains('(') && address.endsWith(')')) {
                        final int startIdx = address.indexOf('(');
                        mainAddr = address.substring(0, startIdx).trim();
                        noteAddr = address.substring(startIdx + 1, address.length - 1).trim();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mainAddr,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          if (noteAddr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.orange.shade700,
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    TranslationService.currentLang == 'en'
                                        ? 'Note: $noteAddr'
                                        : 'Catatan: $noteAddr',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    })(),
                    const SizedBox(height: 8),
                    // Contact row with person icon
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Colors.grey.shade500,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            alamat['nama_penerima'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Contact row with phone icon
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: Colors.grey.shade500,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            alamat['nohp_penerima'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFFFFC107), size: 20),
                      splashColor: cyanColor.withOpacity(0.2),
                      highlightColor: cyanColor.withOpacity(0.1),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: alamat)),
                        );
                        if (result == true) {
                          _fetchAlamat(); // Refresh list after edit
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      splashColor: Colors.redAccent.withOpacity(0.2),
                      highlightColor: Colors.redAccent.withOpacity(0.1),
                      onPressed: () => _deleteAlamat(alamat['id_alamat']),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedLocationsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              TranslationService.translate('suggested_locations'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: navyColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
          if (_isLoadingSuggested)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_suggestedNearby.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.location_disabled_rounded, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      TranslationService.translate('no_suggested_locations'),
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TranslationService.translate('suggested_locations_desc'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestedNearby.length,
              separatorBuilder: (context, idx) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final place = _suggestedNearby[index];
                final String name = place['name'] ?? 'Rekomendasi Tempat';
                final String address = place['alamat_lengkap'] ?? '';

                // Format distance beautifully
                final double distVal = place['distance'] != null ? double.tryParse(place['distance'].toString()) ?? 0.0 : 0.0;
                String distanceText = '';
                if (distVal > 0) {
                  if (distVal < 1000) {
                    distanceText = '${distVal.toStringAsFixed(0)} m';
                  } else {
                    distanceText = '${(distVal / 1000).toStringAsFixed(1)} km';
                  }
                }

                return ListTile(
                  leading: SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on, color: Colors.amber, size: 16),
                        ),
                        if (distanceText.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              distanceText,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    address,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    final Map<String, dynamic> mockAlamat = {
                      'alamat_lengkap': address,
                      'latitude': place['latitude'] ?? '-6.1753924',
                      'longitude': place['longitude'] ?? '106.8271528',
                      'tipe_alamat': 'Rumah',
                    };
                    final added = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: mockAlamat)),
                    );
                    if (added == true) {
                      _fetchAlamat();
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMapPreviewCard(BuildContext context) {
    if (_mapLat == null || _mapLon == null) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isEn = TranslationService.currentLang == 'en';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live OSM Map Preview Frame
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 140,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_mapLat!, _mapLon!),
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                    ],
                  ),
                  // Center Marker Pin sitting geographically centered
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Icon(Icons.location_on, color: cyanColor, size: 20),
                      ),
                    ),
                  ),
                  // Clickable gesture layer
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PilihAlamatScreen()),
                          );
                          if (result != null && result is Map) {
                            final Map<String, dynamic> mockAlamat = {
                              'alamat_lengkap': result['alamat'],
                              'latitude': result['latitude'],
                              'longitude': result['longitude'],
                              'tipe_alamat': 'Rumah',
                            };
                            if (context.mounted) {
                              final added = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TambahAlamatScreen(alamatToEdit: mockAlamat)),
                              );
                              if (added == true) {
                                _fetchAlamat();
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sleek card footer details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded, color: cyanColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn ? 'Your Map Area Preview' : 'Preview Area Peta Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: navyColor,
                    ),
                  ),
                ),
                Text(
                  isEn ? 'Adjust' : 'Sesuaikan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cyanColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, color: cyanColor, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
