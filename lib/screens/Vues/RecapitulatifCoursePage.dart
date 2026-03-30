import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/Apiservices/DirectionAPIs.dart';
import 'LoadingScreen.dart';


Future<bool> confirmerCommande() async {
  await Future.delayed(const Duration(seconds: 2));
  bool commandeReussie = true;
  return commandeReussie;
}

class RecapitulatifCoursePage extends StatefulWidget {
  final String? clientId;
  final String depart;
  final String destination;
  final String modePaiement;
  final String typeTaxi;
  final double prixEstime;
  final LatLng departCoords;
  final LatLng destinationCoords;

  const RecapitulatifCoursePage({
    Key? key,
    required this.depart,
    required this.destination,
    required this.modePaiement,
    required this.typeTaxi,
    required this.prixEstime,
    required this.departCoords,
    required this.destinationCoords,
    this.clientId,
  }) : super(key: key);

  @override
  State<RecapitulatifCoursePage> createState() => _RecapitulatifCoursePageState();
}

class _RecapitulatifCoursePageState extends State<RecapitulatifCoursePage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: widget.departCoords,
        infoWindow: const InfoWindow(title: 'Départ'),
      ),
      Marker(
        markerId: const MarkerId('dest'),
        position: widget.destinationCoords,
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    };

    getOsrmRoute(widget.departCoords, widget.destinationCoords).then((routePoints) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('trajet'),
            color: Colors.red,
            width: 5,
            points: routePoints,
          )
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.departCoords.latitude < widget.destinationCoords.latitude
            ? widget.departCoords.latitude
            : widget.destinationCoords.latitude,
        widget.departCoords.longitude < widget.destinationCoords.longitude
            ? widget.departCoords.longitude
            : widget.destinationCoords.longitude,
      ),
      northeast: LatLng(
        widget.departCoords.latitude > widget.destinationCoords.latitude
            ? widget.departCoords.latitude
            : widget.destinationCoords.latitude,
        widget.departCoords.longitude > widget.destinationCoords.longitude
            ? widget.departCoords.longitude
            : widget.destinationCoords.longitude,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Récapitulatif de la course'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (widget.departCoords.latitude + widget.destinationCoords.latitude) / 2,
                (widget.departCoords.longitude + widget.destinationCoords.longitude) / 2,
              ),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 200), () {
                _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
              });
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Départ', widget.depart),
                  const SizedBox(height: 8),
                  _buildInfoRow('Destination', widget.destination),
                  const SizedBox(height: 8),
                  _buildInfoRow('Type de taxi', widget.typeTaxi),
                  const SizedBox(height: 8),
                  _buildInfoRow('Mode de paiement', widget.modePaiement),
                  const SizedBox(height: 8),
                  _buildInfoRow('Prix estimé', '${widget.prixEstime.toStringAsFixed(2)} FCFA'),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        bool success = await confirmerCommande();

                        Navigator.pop(context);

                        if (success) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EcranRechercheChauffeur(
                                clientId: widget.clientId,
                                depart: widget.depart,
                                destination: widget.destination,
                                modePaiement: widget.modePaiement,
                                typeTaxi: widget.typeTaxi,
                                prixEstime: widget.prixEstime,
                                departCoords: widget.departCoords,
                                destinationCoords: widget.destinationCoords,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de la confirmation de la commande.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Confirmer la commande"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

}
