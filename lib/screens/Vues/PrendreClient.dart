import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class Prendreclient extends StatefulWidget {
  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<Prendreclient> {
  GoogleMapController? _controller;
  Location _location = Location();
  LatLng _initialPosition = LatLng(13.5116, 2.1254); // Niamey, Niger
  LatLng? _destinationPosition;
  Set<Marker> _markers = {};

  final String _googleApiKey = 'AIzaSyDO20mxTPHOBLF5y9Yd89Kxjk26FGsDKXY';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    LocationData userLocation;
    try {
      userLocation = await _location.getLocation();
      setState(() {
        _initialPosition = LatLng(userLocation.latitude!, userLocation.longitude!);
      });
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 14.0),
        ),
      );
    } on Exception catch (e) {
      print("Could not get user location: $e");
    }
  }

  Future<void> _getDestinationCoordinates(String destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(destination)}&key=$_googleApiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['results'][0]['geometry']['location'];
      final LatLng destinationPosition = LatLng(location['lat'], location['lng']);

      setState(() {
        _destinationPosition = destinationPosition;
        _markers.add(Marker(
          markerId: MarkerId('Destination'),
          position: destinationPosition,
          infoWindow: InfoWindow(title: 'Client'),
        ));
      });

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: destinationPosition, zoom: 14.0),
        ),
      );
    } else {
      print("Failed to get coordinates for the destination.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String destination = args['destination']!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDestinationCoordinates(destination); // Fetch destination coordinates
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Course Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Disable default button
            markers: _markers,
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.blue.shade200,
                    onPressed: _getUserLocation,
                    splashColor: Colors.white,
                    tooltip: 'Localisation',
                    child: Icon(Icons.my_location),
                  ),
                  SizedBox(height: 10),
                  FloatingActionButton(
                    onPressed: () {
                      // Add your custom action here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Custom Action')),
                      );
                    },
                    tooltip: 'Custom Action',
                    splashColor: Colors.white,
                    backgroundColor: Colors.blue.shade200,
                    child: Icon(Icons.star),
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
