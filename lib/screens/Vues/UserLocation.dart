import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapView2 extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView2> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';
  String _currentCoordinates = ''; // To store current coordinates

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';

  Set<Marker> markers = {}; // Keep this for future use if needed

  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _getCurrentLocation();
      _updateUserLocation();
    });
  }

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        _currentCoordinates =
        'Latitude: ${position.latitude}, Longitude: ${position.longitude}'; // Set coordinates

        // Animate camera to the current location
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );

        // Update user location on the server
        _updateUserLocation();
      });
    }).catchError((e) {
      print(e);
    });
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
    // else if (typedecompte == null) {
    //   final response = await http.put(
    //     url,
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({
    //       'longitude': null,
    //       'latitude': null,
    //     }),
    //   );
    //   if (response.statusCode == 204) {
    //     print('User location updated successfully');
    //   } else {
    //     print('Failed to update user location: ${response.body}');
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final String username = args['username']!;
    final String typedecompte = args['typecompte']!;

    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              markers: Set<Marker>.from(markers), // No markers added
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.shade100, // Button color
                      child: InkWell(
                        splashColor: Colors.orange, // Splash color
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
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 10,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: Text(
                  _currentCoordinates, // Display the current coordinates
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}