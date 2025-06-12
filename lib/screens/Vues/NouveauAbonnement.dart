import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NouvelAbonnementPage extends StatefulWidget {
  @override
  _NouvelAbonnementPageState createState() => _NouvelAbonnementPageState();
}

class _NouvelAbonnementPageState extends State<NouvelAbonnementPage> {
  TextEditingController _etatController = TextEditingController();
  TextEditingController _lieuDepartController = TextEditingController();
  TextEditingController _lieuDestinationController = TextEditingController();
  TextEditingController _dateDepartController = TextEditingController();
  TextEditingController _dateReservationController = TextEditingController();
  TextEditingController _prixAbonnementController = TextEditingController();
  int? _selectedChauffeur;
  int? _selectedClient;

  List<dynamic> _chauffeurs = [];
  List<dynamic> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchChauffeurs();
    _fetchClients();
  }

  Future<void> _fetchChauffeurs() async {
    final response = await http.get(Uri.parse('http://192.168.137.1:8000/api/chauffeurs'));
    if (response.statusCode == 200) {
      setState(() {
        _chauffeurs = json.decode(response.body);
      });
    }
  }

  Future<void> _fetchClients() async {
    final response = await http.get(Uri.parse('http://192.168.137.1:8000/api/clients'));
    if (response.statusCode == 200) {
      setState(() {
        _clients = json.decode(response.body);
      });
    }
  }

  Future<void> _ajouterAbonnement() async {
    final Map<String, dynamic> nouvelAbonnement = {
      'etat': _etatController.text,
      'lieu_depart': _lieuDepartController.text,
      'lieu_destination': _lieuDestinationController.text,
      'date_depart': _dateDepartController.text,
      'date_reservation': _dateReservationController.text,
      'prix_abonnement': _prixAbonnementController.text,
      'chauffeur_id': _selectedChauffeur,
      'client_id': _selectedClient,
    };

    final response = await http.post(
      Uri.parse('http://192.168.137.1:8000:8000/api/abonnements'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(nouvelAbonnement),
    );

    if (response.statusCode == 201) {
      Navigator.of(context).pop();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Échec de la création de l\'abonnement.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvel Abonnement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 4,
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              children: [
                TextField(
                  controller: _etatController,
                  decoration: InputDecoration(labelText: 'État'),
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: _lieuDepartController,
                  decoration: InputDecoration(labelText: 'Lieu de départ'),
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: _lieuDestinationController,
                  decoration: InputDecoration(labelText: 'Lieu de destination'),
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: _dateDepartController,
                  decoration: InputDecoration(labelText: 'Date de départ'),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (date != null) {
                      setState(() {
                        _dateDepartController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: _dateReservationController,
                  decoration: InputDecoration(labelText: 'Date de réservation'),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (date != null) {
                      setState(() {
                        _dateReservationController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: _prixAbonnementController,
                  decoration: InputDecoration(labelText: 'Prix de l\'abonnement'),
                ),
                DropdownButton<int>(
                  hint: Text('Sélectionnez un chauffeur'),
                  value: _selectedChauffeur,
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedChauffeur = newValue;
                    });
                  },
                  items: _chauffeurs.map<DropdownMenuItem<int>>((chauffeur) {
                    return DropdownMenuItem<int>(
                      value: chauffeur['id'],
                      child: Text(chauffeur['nom']),
                    );
                  }).toList(),
                ),
                DropdownButton<int>(
                  hint: Text('Sélectionnez un client'),
                  value: _selectedClient,
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedClient = newValue;
                    });
                  },
                  items: _clients.map<DropdownMenuItem<int>>((client) {
                    return DropdownMenuItem<int>(
                      value: client['id'],
                      child: Text(client['nom']),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _ajouterAbonnement,
                  child: Text('Ajouter Abonnement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
