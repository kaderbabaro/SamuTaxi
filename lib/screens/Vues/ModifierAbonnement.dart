import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ModifierAbonnementPage extends StatefulWidget {
  final Map<String, dynamic> abonnement;

  ModifierAbonnementPage({required this.abonnement});

  @override
  _ModifierAbonnementPageState createState() => _ModifierAbonnementPageState();
}

class _ModifierAbonnementPageState extends State<ModifierAbonnementPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _etatController;
  late TextEditingController _lieuDepartController;
  late TextEditingController _lieuDestinationController;
  late TextEditingController _dateDepartController;
  late TextEditingController _dateReservationController;
  late TextEditingController _prixAbonnementController;

  @override
  void initState() {
    super.initState();
    _etatController = TextEditingController(text: widget.abonnement['etat']);
    _lieuDepartController = TextEditingController(text: widget.abonnement['lieu_depart']);
    _lieuDestinationController = TextEditingController(text: widget.abonnement['lieu_destination']);
    _dateDepartController = TextEditingController(text: widget.abonnement['date_depart']);
    _dateReservationController = TextEditingController(text: widget.abonnement['date_reservation']);
    _prixAbonnementController = TextEditingController(text: widget.abonnement['prix_abonnement']);
  }

  @override
  void dispose() {
    _etatController.dispose();
    _lieuDepartController.dispose();
    _lieuDestinationController.dispose();
    _dateDepartController.dispose();
    _dateReservationController.dispose();
    _prixAbonnementController.dispose();
    super.dispose();
  }

  Future<void> _modifierAbonnement() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.put(
        Uri.parse('http://192.168.137.1:8000/api/abonnements/${widget.abonnement['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'etat': _etatController.text,
          'lieu_depart': _lieuDepartController.text,
          'lieu_destination': _lieuDestinationController.text,
          'date_depart': _dateDepartController.text,
          'date_reservation': _dateReservationController.text,
          'prix_abonnement': _prixAbonnementController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Erreur'),
            content: Text('Échec de la modification de l\'abonnement.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier l\'abonnement'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(2.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _etatController,
                decoration: InputDecoration(labelText: 'État'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'état';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _lieuDepartController,
                decoration: InputDecoration(labelText: 'Lieu de départ'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le lieu de départ';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _lieuDestinationController,
                decoration: InputDecoration(labelText: 'Lieu de destination'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le lieu de destination';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _dateDepartController,
                decoration: InputDecoration(labelText: 'Date de départ'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la date de départ';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _dateReservationController,
                decoration: InputDecoration(labelText: 'Date de réservation'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la date de réservation';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: _prixAbonnementController,
                decoration: InputDecoration(labelText: 'Prix de l\'abonnement'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le prix de l\'abonnement';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _modifierAbonnement,
                child: Text('Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
