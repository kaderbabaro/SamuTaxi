import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rive_animation/screens/Vues/PrincipalMaps.dart';
import 'dart:convert';

import 'package:rive_animation/screens/entryPoint/entry_point.dart';

import 'UserLocation.dart';

class OrderTaxiPage extends StatefulWidget {
  const OrderTaxiPage({Key? key}) : super(key: key);

  @override
  _OrderTaxiPageState createState() => _OrderTaxiPageState();
}

class _OrderTaxiPageState extends State<OrderTaxiPage> {
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  String? _tariffType;
  String? _paymentMethod;
  String? _statusMessage,_statut;
  Timer? _timer;
  int? id;
  TextEditingController _startLocationController = TextEditingController();
  TextEditingController _endLocationController = TextEditingController();
  TextEditingController _orderTimeController = TextEditingController();
  TextEditingController _distanceController = TextEditingController();
  TextEditingController _prixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startLocationController.text = '';
    _endLocationController.text = '';
    _distanceController.text = '';
    _prixController.text = '';
    _statusMessage = '';
  }

  @override
  void dispose() {
    _timer?.cancel(); // Assurez-vous d'annuler le timer à la fin de l'utilisation du widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String?> args =
    ModalRoute.of(context)!.settings.arguments as Map<String, String?>;
    final String Depart = args['depart']!;
    final String Destination = args['destination']!;
    final String Distance = args['distance']!;
    final String Prix = args['prix']!;

    _startLocationController.text = Depart;
    _endLocationController.text = Destination;
    _distanceController.text = Distance;
    _prixController.text = Prix;

    return Scaffold(
      appBar: AppBar(
        title: Text('Commander un Taxi'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 5,
                blurRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: ListView(
                children: [
                  _buildDropdownFormField(
                    'Type de tarif',
                    ['Partagé'],
                        (value) {
                      setState(() {
                        _tariffType = value;
                      });
                    },
                    _tariffType,
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(
                    'Lieu de départ',
                    _startLocationController,
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(
                    'Lieu d\'arrivée',
                    _endLocationController,
                  ),
                  SizedBox(height: 16),
                  _buildDateTimePickerFormField(
                    'Heure de la commande',
                    _orderTimeController,
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(
                    'Distance (en km)',
                    _distanceController,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(
                    'Prix',
                    _prixController,
                  ),
                  SizedBox(height: 16),
                  _buildDropdownFormField(
                    'Mode de paiement',
                    ['Espèce', 'Carte', 'MyNita', 'AirtelMoney', 'ZamaniCash'],
                        (value) {
                      setState(() {
                        _paymentMethod = value;
                      });
                    },
                    _paymentMethod,
                  ),
                  SizedBox(height: 32),
                  _buildSubmitButton(context),
                  SizedBox(height: 16),
                  if (_isLoading || _isUpdatingStatus) ...[
                    Center(child: CircularProgressIndicator()),
                  ],
                  if (_statusMessage!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _statusMessage == 'Commande acceptée' ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    final url = Uri.parse('http://192.168.137.1:8000/api/courses');
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'typetarif': _tariffType,
          'client_id': 'me',
          'paymentMethod': _paymentMethod,
          'lieu_prise_course': _startLocationController.text,
          'destination_course': _endLocationController.text,
          'orderTime': _orderTimeController.text,
          'distance': _distanceController.text,
          'prix_course': _prixController.text,
          'statut': 'En recherche de taxi',
        }),
      );

      if (response.statusCode == 201) {
        // La commande a été créée avec succès
        final responseData = json.decode(response.body);
        final orderId = responseData['id'];
        final statut = responseData['statut'];
        id = orderId;
        _statut = statut;
        print('Commande réussie. ID de la commande : $orderId');
        setState(() {
          _statusMessage = 'Commande envoyée. ID : $orderId';
        });
        _startStatusCheckTimer(); // Démarrer la vérification du statut avec l'ID retourné
      } else {
        // Si la requête a échoué
        print('Erreur de commande');
        setState(() {
          _statusMessage = 'Commande non effectuée';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la requête HTTP: $e');
      setState(() {
        _statusMessage = 'Commande non effectuée';
        _isLoading = false;
      });
    }
  }

  void _startStatusCheckTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkOrderStatus();
    });
  }
  Future<void> _checkOrderStatus() async {
    final url = Uri.parse('http://192.168.137.1:8000/api/courses/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final status = json.decode(response.body)['statut'];
      if (status == 'Course acceptée') {
        setState(() {
          _statusMessage = 'Commande acceptée';
          _isLoading = true;
          _isUpdatingStatus = true;
        });
        _timer?.cancel();
        await Future.delayed(Duration(seconds: 2));
        Navigator.pushNamed(context, '/coursepage', arguments: {'destination' :  _endLocationController.text});
      }
    } else {
      print('Erreur lors de la vérification du statut de la commande');
    }
  }

  Widget _buildDropdownFormField(
      String label,
      List<String> items,
      void Function(String?)? onChanged,
      String? value,
      ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items
          .map((type) => DropdownMenuItem<String>(
        value: type,
        child: Text(type),
      ))
          .toList(),
      onChanged: onChanged,
      value: value,
    );
  }

  Widget _buildTextFormField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
    );
  }

  Widget _buildDateTimePickerFormField(
      String label,
      TextEditingController controller,
      ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onTap: () async {
        DateTime? dateTime = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );

        if (dateTime != null) {
          TimeOfDay? time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (time != null) {
            setState(() {
              controller.text =
              '${dateTime.toLocal().toIso8601String().substring(0, 10)} ${time.format(context)}';
            });
          }
        }
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading || _isUpdatingStatus ? null : () async {
        await _submitOrder();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Commander'.toUpperCase(),
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
    );
  }
}

