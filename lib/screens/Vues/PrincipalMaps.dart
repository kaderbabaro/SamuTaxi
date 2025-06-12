import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart' as google_place;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'Abonnement_list.dart';
import 'secrets.dart';  // Ensure your API key is defined here

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // Initializations
  late GoogleMapController mapController;
  late Position _currentPosition;
  late Timer _timer;

  String _currentAddress = '';
  String _startAddress = '';
  String _destinationAddress = '';
  String? _distanceText;
  int? _distanceValue;
  double? _calculatedPrice;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();
  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  List<google_place.AutocompletePrediction> predictionsForStart = [];
  List<google_place.AutocompletePrediction> predictionsForDestination = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late google_place.GooglePlace googlePlace;

  @override
  void initState() {
    super.initState();
    googlePlace = google_place.GooglePlace(Secrets.API_KEY);
    _getCurrentLocation();
    _fetchTarifs();
    _fetchUserLocation();
    _updateUserLocation();

    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _fetchUserLocation();
      await _updateUserLocation();
    });
  }

  @override
  void dispose() {
    startAddressController.dispose();
    destinationAddressController.dispose();
    startAddressFocusNode.dispose();
    destinationAddressFocusNode.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: CameraPosition(target: LatLng(0.0, 0.0)),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.satellite,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          splashColor: Colors.blue,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.white,
                        child: InkWell(
                          splashColor: Colors.blue,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: <Widget>[
                          _textField(
                            controller: startAddressController,
                            focusNode: startAddressFocusNode,
                            label: 'Départ',
                            hint: 'Choisissez votre point de départ',
                            width: width,
                            prefixIcon: Icon(Icons.looks_one),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.my_location),
                              onPressed: _getCurrentLocation,
                            ),
                            locationCallback: (String value) {
                              setState(() {
                                _startAddress = value;
                              });
                            },
                            predictions: predictionsForStart,
                            isStart: true,
                            enabled: true,
                          ),
                          SizedBox(height: 10),
                          _textField(
                            controller: destinationAddressController,
                            focusNode: destinationAddressFocusNode,
                            label: 'Destination',
                            hint: 'Choisissez votre destination',
                            width: width,
                            prefixIcon: Icon(Icons.looks_two),
                            locationCallback: (String value) {
                              setState(() {
                                _destinationAddress = value;
                              });
                            },
                            predictions: predictionsForDestination,
                            isStart: false,
                            enabled: true,
                          ),
                          SizedBox(height: 10),
                          Visibility(
                            visible: _distanceText != null,
                            child: Column(
                              children: [
                                Text(
                                  'DISTANCE: $_distanceText',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'PRIX: ${_calculatedPrice?.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/commander',
                                      arguments: {
                                        'depart': _startAddress,
                                        'destination': _destinationAddress,
                                        'distance': _distanceText,
                                        'prix': _calculatedPrice?.toStringAsFixed(2),
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.arrow_circle_right,
                                    size: 35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          ElevatedButton(
                            onPressed: (_startAddress.isNotEmpty && _destinationAddress.isNotEmpty)
                                ? () async {
                              setState(() {
                                if (markers.isNotEmpty) markers.clear();
                                if (polylines.isNotEmpty) polylines.clear();
                                if (polylineCoordinates.isNotEmpty)
                                  polylineCoordinates.clear();
                                _distanceText = null;
                              });
                              await _calculateDistance();
                              await _calculatePrice();
                              await _fetchTarifs();
                              await _fetchUserLocation();
                            }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                'Commandez'.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 7),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AbonnementListPage()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                'Abonnements'.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 35,),  // Spacer here
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Material(
                              color: Colors.white,
                              child: InkWell(
                                splashColor: Colors.blue,
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(Icons.my_location),
                                ),
                                onTap: () {
                                  mapController.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                          _currentPosition.latitude,
                                          _currentPosition.longitude,
                                        ),
                                        zoom: 18.0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 15.0), // Espacement entre les boutons
                          ClipOval(
                            child: Material(
                              color: Colors.white, // Bouton pour revenir en arrière
                              child: InkWell(
                                splashColor: Colors.blue,
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(Icons.arrow_back),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }


// Function to launch the phone dialer
  Future<void> _launchCaller(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _fetchUserLocation() async {
    final String apiUrl = 'http://192.168.137.1:8000/api/vehicules';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> userDataList = json.decode(response.body);

        setState(() {
          markers.clear();
          for (var userData in userDataList) {
            // Add debug prints and null checks
            print('UserData: $userData');
            double? latitude = userData['user']['latitude'];
            double? longitude = userData['user']['longitude'];
            String? nomchauffeur = userData['user']['identifiant'];
            String? telephone = userData['user']['telephone'];
            String? vehicule = userData['modele_marque'];
            String? matricule = userData['matricule'];

            if (latitude != null && longitude != null && nomchauffeur != null && telephone != null && vehicule != null) {
              markers.add(
                Marker(
                  markerId: MarkerId(userData['userId'].toString()),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(
                    title: 'Chauffeur: $nomchauffeur',
                    snippet: 'Etat: $matricule, Véhicule: $vehicule',
                    onTap: () {
                      _launchCaller(telephone);
                    },
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              );
            } else {
              print('Some user data is null: $userData');
            }
          }
        });
        if (userDataList.isNotEmpty) {
          double? firstUserLatitude = userDataList[0]['latitude'];
          double? firstUserLongitude = userDataList[0]['longitude'];

          if (firstUserLatitude != null && firstUserLongitude != null) {
            mapController.animateCamera(
              CameraUpdate.newLatLng(LatLng(firstUserLatitude, firstUserLongitude)),
            );
          } else {
            print('First user latitude or longitude is null');
          }
        }
      } else {
        throw Exception('Failed to load user locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // AutoComplete search functionality
  void autoCompleteSearch(String value, {required bool isStart}) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        if (isStart) {
          predictionsForStart = result.predictions!;
        } else {
          predictionsForDestination = result.predictions!;
        }
      });
    }
  }

  // Custom text field widget for address input
  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
    required List<google_place.AutocompletePrediction> predictions,
    required bool isStart,
    required bool enabled,
  }) {
    int maxSuggestions = 3;

    return Container(
      width: width * 0.8,
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              locationCallback(value);
              autoCompleteSearch(value, isStart: isStart);
            },
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                borderSide: BorderSide(
                  color: Colors.blue.shade300,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.all(15),
              hintText: hint,
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: predictions.take(maxSuggestions).map((prediction) {
                return ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(prediction.description!),
                  titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                  ),
                  onTap: () {
                    controller.text = prediction.description!;
                    locationCallback(prediction.description!);
                    setState(() {
                      predictions.clear();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  // Fetch current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Get address from current location
  _getAddress() async {
    try {
      List<geocoding.Placemark> p = await geocoding.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      geocoding.Placemark place = p[0];

      setState(() {
        _currentAddress =
        "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  // Fetch tariffs from API
  Future<double?> _fetchTarifs() async {
    final String baseUrl = 'http://192.168.137.1:8000/api/tarif';

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> tarifs = json.decode(response.body);

        double? prixPlage;

        tarifs.forEach((tarif) {
          if (tarif['typeTarif'] == 'partagé') {
            prixPlage = tarif['prixPlage'].toDouble();
          }
        });

        setState(() {});

        if (prixPlage != null) {
          // print('PrixPlage récupéré: $prixPlage');
        } else {
          print('Aucun tarif de type "partagé" trouvé');
        }

        return prixPlage;

      } else {
        throw Exception('Échec du chargement des tarifs');
      }
    } catch (e) {
      throw Exception('Échec du chargement des tarifs: $e');
    }
  }

  Future<void> _updateUserLocation() async {
    final Map<String, String> args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final String username = args['username']!;
    final String typedecompte = args['typecompte']!;

    final url = Uri.parse('http://192.168.137.1:8000/api/users/$username');
    if (typedecompte == 'Chauffeur') {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'longitude': _currentPosition.longitude,
          'latitude': _currentPosition.latitude,
        }),
      );
      if (response.statusCode == 204) {
        print('User location updated successfully');
      } else {
        print('Failed to update user location: ${response.body}');
      }
    }
  }



  // Calculate price based on distance
  Future<void> _calculatePrice() async {
    double? prixPlage = await _fetchTarifs();
    double price = _distanceValue! * prixPlage! / 1000;

    setState(() {
      _calculatedPrice = price;
    });

    print('Prix calculé: $price');
  }

  // Calculate distance between start and destination
  Future<void> _calculateDistance() async {
    final String origin = Uri.encodeComponent(_startAddress);
    final String destination = Uri.encodeComponent(_destinationAddress);
    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$origin&destinations=$destination&key=${Secrets.API_KEY}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK') {
          final distanceValue = json['rows'][0]['elements'][0]['distance']['value'];

          setState(() {
            _distanceText = json['rows'][0]['elements'][0]['distance']['text'];
            _distanceValue = distanceValue;
          });

          _calculatePrice();

        } else {
          print('Error: ${json['status']}');
        }
      } else {
        print('HTTP Request Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving data: $e');
    }
  }

}



class Destination extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Destination'),
      ),
      body: Center(
        child: Text('Destination Page'),
      ),
    );
  }

}

