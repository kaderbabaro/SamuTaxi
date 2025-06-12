import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart' as google_place;
import 'package:http/http.dart' as http;
import 'package:rive_animation/screens/Vues/Abonnement_list.dart';
import 'package:rive_animation/screens/Vues/CommandeTaxi.dart';
import 'dart:convert';

import 'secrets.dart';  // Assurez-vous d'avoir votre clé API ici

class MapDriver extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapDriver> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _distanceText;
  int? _distanceValue;
  Timer? _timer;

  Set<Marker> markers = {};

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late google_place.GooglePlace googlePlace;
  List<google_place.AutocompletePrediction> predictionsForStart = [];
  List<google_place.AutocompletePrediction> predictionsForDestination = [];


  @override
  void initState() {
    super.initState();
    googlePlace = google_place.GooglePlace(Secrets.API_KEY);
    _getCurrentLocation();
    _fetchTarifs();
    _fetchUserLocation();

    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _fetchUserLocation();
    });
  }

  List<LatLng> _getRandomTaxiPositions() {
    // Simule 5 positions de taxi autour de l'utilisateur
    List<LatLng> positions = [];
    final Random random = Random();

    for (int i = 0; i < 5; i++) {
      double lat = _currentPosition.latitude + random.nextDouble() * 0.05; // +/- 0.025 autour de la latitude actuelle
      double lng = _currentPosition.longitude + random.nextDouble() * 0.05; // +/- 0.025 autour de la longitude actuelle
      positions.add(LatLng(lat, lng));
    }

    return positions;
  }


  void _addTaxiMarkers(List<LatLng> taxiPositions) {
    setState(() {
      markers.clear(); // Efface les marqueurs existants

      for (int i = 0; i < taxiPositions.length; i++) {
        var markerIdVal = 'taxi_$i';
        final MarkerId markerId = MarkerId(markerIdVal);

        final Marker marker = Marker(
          markerId: markerId,
          position: taxiPositions[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), // Icône pour les taxis
          infoWindow: InfoWindow(
            title: 'Taxi $i',
            snippet: 'Position du taxi $i',
          ),
        );

        markers.add(marker);
      }
    });
  }


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
    int maxSuggestions = 3; // Limite de suggestions à afficher

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

      // Update taxi positions based on user's location
      List<LatLng> taxiPositions = _getRandomTaxiPositions();
      _addTaxiMarkers(taxiPositions);
    }).catchError((e) {
      print(e);
    });
  }



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

  Future<double?> _fetchTarifs() async {
    final String baseUrl = 'http://192.168.137.1:8000/api/tarif';

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> tarifs = json.decode(response.body);

        double? prixPlage; // Variable pour contenir le prix de la plage

        tarifs.forEach((tarif) {
          if (tarif['typeTarif'] == 'partagé') {
            prixPlage = tarif['prixPlage'].toDouble();
          }
        });

        // Mise à jour de l'interface après récupération des données
        setState(() {});

        // Affichage du prix de la plage récupéré
        if (prixPlage != null) {
          // print('PrixPlage récupéré: $prixPlage');
        } else {
          print('Aucun tarif de type "partagé" trouvé');
        }

        return prixPlage; // Retourne le prix de la plage récupéré

      } else {
        throw Exception('Échec du chargement des tarifs');
      }
    } catch (e) {
      throw Exception('Échec du chargement des tarifs: $e');
    }
  }

  double? _calculatedPrice;

  Future<void> _calculatePrice() async {

    double? prixPlage = await _fetchTarifs();
    double price = _distanceValue! * prixPlage! /1000;

    setState(() {
      _calculatedPrice = price;
    });
    // Affichage du prix calculé
    print('Prix calculé: $price');
  }

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
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
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
                        color: Colors.blue.shade100,
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
                        color: Colors.blue.shade100,
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

                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(height: 10.0), // Espacement entre les boutons
                        // Bouton pour centrer la carte sur la position actuelle
                        ClipOval(
                          child: Material(
                            color: Colors.orange.shade100,
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
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  // Fetch user location markers
  Future<void> _fetchUserLocation() async {
    final String apiUrl = 'http://192.168.137.1:8000/api/users/client';
    final Map<String, String> args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final String username = args['username']!;

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> userDataList = json.decode(response.body);

        setState(() {
          markers.clear();
          for (var userData in userDataList) {
            // Add debug prints and null checks
            print('UserData: $userData');
            double? latitude = userData['latitude'];
            double? longitude = userData['longitude'];
            String? nomchauffeur = userData['identifiant'];
            String? telephone = userData['telephone'];
            String? vehicule = userData['vehicule']['ModeleMarque'];
            String? etat = userData['vehicule']['Etat'];

            if (latitude != null && longitude != null && nomchauffeur != null && telephone != null && vehicule != null) {
              markers.add(
                Marker(
                  markerId: MarkerId(userData['userId'].toString()),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(
                    title: 'Chauffeur: $nomchauffeur, Téléphone: $telephone',
                    snippet: 'Etat: $etat, Véhicule: $vehicule',
                    onTap: () {
                      // Ajoutez ici le code à exécuter lorsqu'on appuie sur l'InfoWindow
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
