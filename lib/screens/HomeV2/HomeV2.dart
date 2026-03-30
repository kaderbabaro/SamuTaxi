import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../Profil/Profil_edit.dart';
import '../Vues/Apropos.dart';
import '../Vues/Historique.dart';
import '../Vues/RecapitulatifCoursePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class HomeV2 extends StatefulWidget {
  final String userId;
  final String username;
  final String telephone;
  const HomeV2({super.key, required this.userId, required this.username, required this.telephone});

  @override
  State<HomeV2> createState() => _TaxiHomePageState();
}

enum RideType { city, airport }

class _TaxiHomePageState extends State<HomeV2> {
  late GoogleMapController _mapController;
  bool _isSelectingStart = true;   // sélection départ
  bool _isSelectingEnd = false;    // sélection destination
  bool _hasSelectedDest = false;   // vrai si l’utilisateur a choisi une suggestion destination

  final bool _isForSelf = true;
  bool _isPanelExpanded = false;
  bool _showingSuggestions = false;
  bool _isLoadingSuggestions = false;
  bool _panelLockedOpen = true;
  bool _isLoading = false;
  bool _locationDialogShown = false;
  bool _isSelectingPrice = false;

  final String _reservationPour = "Client";
  String? _selectedPayment;
  String? _selectedTaxi;

  Timer? _debounce;

  LatLng? _currentPosition;
  late Marker departMarker;
  late Marker destMarker;
  late Marker positionclient;

  List<Map<String, dynamic>> _startPredictions = [];
  List<Map<String, dynamic>> _destPredictions = [];

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final FocusNode _startFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();
  late PageController _pageController;
  StreamSubscription<ServiceStatus>? _locationServiceStream;
  double _similarityScore(String a, String b) {
    if (a.contains(b)) return 1.0;

    final aWords = a.split(' ');
    final bWords = b.split(' ');

    int matchCount = 0;

    for (final bw in bWords) {
      for (final aw in aWords) {
        if (aw.startsWith(bw)) {
          matchCount++;
          break;
        }
      }
    }

    return matchCount / bWords.length;
  }


  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  TextEditingController _priceController = TextEditingController();
  int _enteredPrice = 0;
  int _minPrice() => (_suggestedPrice() * 0.5).round();
  int _maxPrice() => (_suggestedPrice() * 1.5).round();


  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _determinePosition();
    _checkAndRequestLocation();

    _startFocus.addListener(() {
      if (_startFocus.hasFocus && _startController.text.isEmpty) {
        _fetchDefaultSuggestions(isStart: true);
      }
    });

    _destFocus.addListener(() {
      if (_destFocus.hasFocus && _destController.text.isEmpty) {
        _fetchDefaultSuggestions(isStart: false);
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _destController.dispose();
    _startFocus.dispose();
    _destFocus.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _suggestedPrice() {
    final distance = _calculateDistanceKm(); // distance en km
    double unit = 200 / 3; // tarif public par km

    double price;

    if (distance <= 3) {
      // tarif minimum pour moins de 3 km
      price = (_selectedTaxi == 'Privé') ? 600 : 200;
    } else {
      // tarif calculé selon le type
      price = distance * unit;
      if (_selectedTaxi == 'Privé') {
        price *= 3; // 3 fois le tarif public pour privé
      }
    }

    return price.round();
  }

  double _calculateDistanceKm() {
    try {
      final departMarker = _markers.firstWhere((m) => m.markerId.value == 'start');
      final destMarker = _markers.firstWhere((m) => m.markerId.value == 'dest');

      final distanceMeters = Geolocator.distanceBetween(
        departMarker.position.latitude,
        departMarker.position.longitude,
        destMarker.position.latitude,
        destMarker.position.longitude,
      );

      return distanceMeters / 1000; // convertir en km
    } catch (e) {
      return 0; // si les markers ne sont pas encore définis
    }
  }


  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _checkAndRequestLocation() async {
    // 1️⃣ Vérifie si le service de localisation est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled && !_locationDialogShown) {
      // 2️⃣ Marque qu’on a déjà montré le popup
      _locationDialogShown = true;

      // 3️⃣ Pop-up demandant d’activer la localisation
      if (!mounted) return;
      await _getCurrentLocation();

      // 4️⃣ Après fermeture du pop-up → re-vérifie
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationDialogShown = false;
        return;
      }
    }
  }



  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Service de localisation désactivé.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Permission de localisation refusée.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Permission de localisation refusée définitivement.");
      return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _markers.add(Marker(
        markerId: const MarkerId('current'),
        position: _currentPosition!,
        infoWindow: const InfoWindow(title: "Ma position"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    });
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 15),
    );
    }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }

  Future<void> _onTextChanged(String value, bool isStart) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isEmpty) {
        setState(() {
          if (isStart) {
            _startPredictions = [];
          } else {
            _destPredictions = [];
          }
          _isLoadingSuggestions = false;
        });
        return;
      }

      setState(() {
        _isLoadingSuggestions = true;
      });

      final nominatimResults = await _searchNominatim(value);
      final photonResults = await _searchPhoton(value);
      final combined = [...nominatimResults, ...photonResults];

      setState(() {
        if (isStart) {
          _startPredictions = combined;
        } else {
          _destPredictions = combined;
        }
        _isLoadingSuggestions = false;
      });
    });
  }

  Future<List<Map<String, dynamic>>> _searchNominatim(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=$query'
            '&format=json'
            '&addressdetails=1'
            '&limit=7'
            '&countrycodes=NE'
            '&viewbox=0.5,24,16,11'
            '&bounded=1'
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'flutter-app/1.0 (contact@tonapp.com)'
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) {
        final rawName = item['display_name'];
        final fixedName = fixEncoding(rawName);
        final cleanedName = cleanPlaceName(fixedName);
        return {
          'name': cleanedName,
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        };
      }).toList();
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchPhoton(String query) async {
    final url = Uri.parse(
        'https://photon.komoot.io/api/?q=$query&limit=7&lat=13.5&lon=2.1&lang=fr'
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'flutter-app/1.0 (contact@tonapp.com)'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;

      return features.map((item) {
        final coords = item['geometry']['coordinates'];
        final props = item['properties'];
        final rawName = props['name'] ?? props['street'] ?? 'Adresse inconnue';
        final fixedName = fixEncoding(rawName);
        final cleanedName = cleanPlaceName(fixedName);

        return {
          'name': cleanedName,
          'lat': coords[1],
          'lon': coords[0],
        };
      }).toList();
    } else {
      return [];
    }
  }

  Widget buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu avec Drawer
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  // Ouvre un Drawer modal avec les options
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.history, color: Colors.red),
                          title: const Text('Historique des courses'),
                          onTap: () {
                            Navigator.pop(context); // Ferme le bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HistoryPage(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.red),
                          title: const Text('À propos'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu, color: Colors.red),
                ),
              ),
            ),

            // Profil utilisateur
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userId: widget.userId),
                  ),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSearchField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isStart,
  }) {
    final predictions = isStart ? _startPredictions : _destPredictions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: isStart
                ? IconButton(
              icon: const Icon(Icons.my_location, color: Colors.black),
              onPressed: () => _useCurrentLocationForStart(),
            )
                : null,
            hintText: label,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 16),
          ),
          onChanged: (value) => _onTextChanged(value, isStart),
          onTap: () => setState(() => _isSelectingStart = isStart),
        ),
      ],
    );
  }

  double _getPanelHeight() {
    if (!_panelLockedOpen) return 0;

    if (!_isSelectingStart) {
      return MediaQuery.of(context).size.height * 0.6;
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasSuggestions = _startPredictions.isNotEmpty;

    if (bottomInset > 0) {
      return MediaQuery.of(context).size.height * 0.6;
    } else if (hasSuggestions) {
      return MediaQuery.of(context).size.height * 0.45;
    } else {
      return MediaQuery.of(context).size.height * 0.28;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _currentPosition == null
          ? const Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.white,
          color: Colors.red,
        ),
      )
          : Stack(
        children: [
          GoogleMap(
            onTap: _handleMapTap,
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 14,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition!, 15),
                );
              }
            },
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: buildHeader(context),
          ),
          // Bouton flottant en bas
          if (!_panelLockedOpen)
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 25,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _panelLockedOpen = true;
                    _isSelectingStart = true;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: _getPanelHeight(),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _isSelectingStart
                      ? Column(
                    key: const ValueKey('start'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(
                        label: "Adresse de départ",
                        controller: _startController,
                        focusNode: _startFocus,
                        isStart: true,
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionsList(_isSelectingStart),
                    ],
                  )
                      : _isSelectingPrice
                      ? Column(
                    key: const ValueKey('price'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Prix conseillé : ${_suggestedPrice()} F CFA',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Votre prix (min: ${_minPrice()}, max: ${_maxPrice()})',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bouton Retour vers le panneau précédent
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isSelectingPrice = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retour'),
                          ),

                          // Bouton Commander avec le prix
                          ElevatedButton(
                            onPressed: () async {
                              _panelLockedOpen = false;

                              // Récupération des markers
                              try {
                                departMarker = _markers.firstWhere((m) => m.markerId.value == 'start');
                                destMarker = _markers.firstWhere((m) => m.markerId.value == 'dest');
                              } catch (e) {
                                _showSnackBar("Veuillez sélectionner les deux positions sur la carte.");
                                return;
                              }

                              // Calcul du prix final
                              int enteredPrice = int.tryParse(_priceController.text) ?? _suggestedPrice();
                              if (enteredPrice < _minPrice()) enteredPrice = _minPrice();
                              if (enteredPrice > _maxPrice()) enteredPrice = _maxPrice();

                              // Navigation vers la page de récapitulatif
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecapitulatifCoursePage(
                                    clientId: widget.userId,
                                    depart: _startController.text,
                                    destination: _destController.text,
                                    modePaiement: _selectedPayment ?? 'Espèce',
                                    typeTaxi: _selectedTaxi ?? 'Privé',
                                    prixEstime: enteredPrice.toDouble(),
                                    departCoords: departMarker.position,
                                    destinationCoords: destMarker.position,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Commander'),
                          ),
                        ],
                      ),

                    ],
                  )
                      : Column(
                    key: const ValueKey('dest'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Mode de paiement',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedPayment,
                        items: ['Espèce'].map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(mode),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPayment = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Type de taxi',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedTaxi,
                        items: ['Privé', 'Public'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTaxi = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSearchField(
                        label: "Adresse de destination",
                        controller: _destController,
                        focusNode: _destFocus,
                        isStart: false,
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestionsList(false),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isSelectingStart = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Retour"),
                          ),
                          if (_hasSelectedDest)
                            ElevatedButton(
                              onPressed: () {
                                // Vérification des adresses
                                if (_destController.text.trim().isEmpty || _startController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Veuillez entrer les adresses de départ et destination."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (_selectedPayment == null || _selectedTaxi == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Veuillez sélectionner le mode de paiement et le type de taxi."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _isSelectingPrice = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("Suivant"),
                            ),
                        ],
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
  }


  Widget _buildSuggestionsList(bool isStart) {
    final suggestions = isStart ? _startPredictions : _destPredictions;

    if (_isLoadingSuggestions) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Colors.red,)),
      );
    }

    if (suggestions.isEmpty) {
      if (_showingSuggestions) {
        setState(() => _showingSuggestions = false);
      }
      return const SizedBox();
    } else {
      if (!_showingSuggestions) {
        setState(() => _showingSuggestions = true);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suggestions de lieux",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= suggestions.length) return const SizedBox(); // sécurité

              final place = suggestions[index];
              final String name = place['name'] ?? 'Adresse inconnue';
              final double? lat = place['lat'];
              final double? lon = place['lon'];

              if (lat == null || lon == null) return const SizedBox(); // sécurité

              final LatLng latLng = LatLng(lat, lon);

              return ListTile(
                leading: const Icon(Icons.place, color: Colors.red),
                title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        if (isStart) {
                          _startController.text = name;
                          _startPredictions.clear();
                          _markers.removeWhere((m) => m.markerId.value == 'start');
                          _markers.add(Marker(
                            markerId: const MarkerId('start'),
                            position: latLng,
                            infoWindow: InfoWindow(title: name),
                          ));
                          _isSelectingStart = false;
                          _isSelectingEnd = true;
                        } else {
                          _destController.text = name;
                          _destPredictions.clear();
                          _markers.removeWhere((m) => m.markerId.value == 'dest');
                          _markers.add(Marker(
                            markerId: const MarkerId('dest'),
                            position: latLng,
                            infoWindow: InfoWindow(title: name),
                          ));
                          _hasSelectedDest = true;   // ✅ destination validée
                        }
                      });
                    });

                    FocusScope.of(context).unfocus();
                  }
              );
            }
        ),
      ],
    );
  }

  Future<void> _useCurrentLocationForStart() async {
    if (_currentPosition == null) return;

    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        String fullAddress = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _startController.text = fullAddress;
          _markers.removeWhere((m) => m.markerId.value == 'start');
          _markers.add(Marker(
            markerId: const MarkerId('start'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: "Ma position actuelle"),
          ));
          _isPanelExpanded = true;
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 16),
          );
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _isSelectingStart = false; // Déclenche l'animation
          });
        });
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la récupération de l'adresse.");
    }
  }


  Future<List<Map<String, dynamic>>> fetchFromNominatimAndPhoton(String query) async {
    final nominatimUrl = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5',
    );
    final photonUrl = Uri.parse(
      'https://photon.komoot.io/api/?q=$query&limit=5',
    );

    try {
      final responses = await Future.wait([
        http.get(nominatimUrl, headers: {'User-Agent': 'YourAppName/1.0'}),
        http.get(photonUrl, headers: {'User-Agent': 'YourAppName/1.0'}),
      ]);

      final nominatimData = jsonDecode(responses[0].body) as List;
      final photonData = jsonDecode(responses[1].body);

      // Transformer photonData pour avoir une structure uniforme
      final photonFeatures = photonData['features'] as List;

      List<Map<String, dynamic>> photonResults = photonFeatures.map((feature) {
        final props = feature['properties'];
        final coords = feature['geometry']['coordinates'];
        return {
          'name': props['name'] ?? props['street'] ?? 'Adresse inconnue',
          'lat': coords[1],
          'lon': coords[0],
        };
      }).toList();

      // Transformer nominatimData pour la même structure
      List<Map<String, dynamic>> nominatimResults = nominatimData.map((item) {
        return {
          'name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        };
      }).toList();

      // Combiner et retirer doublons (optionnel)
      final combined = [...nominatimResults, ...photonResults];
      final uniqueResults = <Map<String, dynamic>>[];

      for (var result in combined) {
        bool exists = uniqueResults.any((r) =>
        (r['lat'] - result['lat']).abs() < 0.0001 &&
            (r['lon'] - result['lon']).abs() < 0.0001);
        if (!exists) {
          uniqueResults.add(result);
          final filtered = filterSimilarPlaces(uniqueResults, query);
          return filtered;
        }
      }

      return uniqueResults;
    } catch (e) {
      print('Erreur fetchFromNominatimAndPhoton: $e');
      return [];
    }
  }

  Future<void> _handleMapTap(LatLng tappedPoint) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        tappedPoint.latitude,
        tappedPoint.longitude,
      );

      String address = 'Adresse inconnue';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = [
          p.street,
          p.subLocality,
          p.locality,
          p.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      setState(() {
        final markerId = _isSelectingStart ? 'start' : 'dest';
        final controller = _isSelectingStart ? _startController : _destController;

        controller.text = address;

        _markers.removeWhere((m) => m.markerId.value == markerId);
        _markers.add(Marker(
          markerId: MarkerId(markerId),
          position: tappedPoint,
          infoWindow: InfoWindow(title: address),
        ));
      });
    } catch (e) {
      _showSnackBar("Impossible de récupérer l’adresse à cet endroit.");
    }
  }

  Future<void> _fetchDefaultSuggestions({required bool isStart}) async {
    const defaultQuery = "Niamey"; // Tu peux changer cette valeur

    final nominatimResults = await _searchNominatim(defaultQuery);
    final photonResults = await _searchPhoton(defaultQuery);

    final combined = [...nominatimResults, ...photonResults];

    setState(() {
      if (isStart) {
        _startPredictions = combined;
      } else {
        _destPredictions = combined;
      }
    });
  }

  String fixEncoding(String badText) {
    try {
      // Convertit le texte mal encodé (UTF-8 affiché en Latin1) vers un texte lisible
      return utf8.decode(latin1.encode(badText));
    } catch (_) {
      return badText; // Si erreur, renvoyer le texte original
    }
  }


  String cleanPlaceName(String name) {

    name = name.replaceAll(RegExp(r"[^A-Za-zÀ-ÿ0-9\s.,'\-()]"), '');
    name = name.replaceAll(RegExp(r'\s+'), ' ');
    name = name.replaceAll(RegExp(r'\s+([.,])'), r'\1');

    return name.trim();
  }

  Future<void> _enregistrerCourse() async {
    setState(() => _isLoading = true); // Affiche le loader

    try {
      final departMarker = _markers.firstWhere((m) => m.markerId.value == 'start');
      final destMarker = _markers.firstWhere((m) => m.markerId.value == 'dest');

      final distance = Geolocator.distanceBetween(
        departMarker.position.latitude,
        departMarker.position.longitude,
        destMarker.position.latitude,
        destMarker.position.longitude,
      ) / 1000;

      final prix = distance * (_selectedTaxi == 'Privé' ? 350 : 200);

      final data = {
        'adresse_depart': _startController.text.trim(),
        'adresse_arrivee': _destController.text.trim(),
        'latitude_depart': departMarker.position.latitude,
        'longitude_depart': departMarker.position.longitude,
        'latitude_arrivee': destMarker.position.latitude,
        'longitude_arrivee': destMarker.position.longitude,
        'type_taxi': _selectedTaxi,
        'moyen_paiement': _selectedPayment,
        'type_course': 'ville',
        'statut': 'en attente',
        'prix': prix,
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('Course').insert(data);

      _showSnackBar("Course enregistrée avec succès !");
    } catch (e) {
      _showSnackBar("Erreur lors de l'enregistrement : $e");
    } finally {
      setState(() => _isLoading = false); // Masque le loader
    }
  }

  List<Map<String, dynamic>> filterSimilarPlaces(
      List<Map<String, dynamic>> places,
      String query,
      ) {
    final lowerQuery = query.toLowerCase();

    return places
        .map((place) {
      final name = (place['name'] ?? '').toString().toLowerCase();
      final score = _similarityScore(name, lowerQuery);
      return {
        ...place,
        'score': score,
      };
    })
        .where((place) => place['score'] > 0) // on garde que les similaires
        .toList()
      ..sort((a, b) => b['score'].compareTo(a['score'])); // tri du plus proche au moins proche
  }

}
