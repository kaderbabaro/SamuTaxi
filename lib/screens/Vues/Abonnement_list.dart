import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Datails_Abonnement.dart';
import 'ModifierAbonnement.dart';
import 'NouveauAbonnement.dart';


class AbonnementListPage extends StatefulWidget {
  @override
  _AbonnementListPageState createState() => _AbonnementListPageState();
}

class _AbonnementListPageState extends State<AbonnementListPage> {
  late Future<List<dynamic>> _futureAbonnements;

  Future<List<dynamic>> fetchAbonnements() async {
    final response = await http.get(Uri.parse('http://192.168.1.21:8000/api/abonnements'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load abonnements');
    }
  }

  @override
  void initState() {
    super.initState();
    _futureAbonnements = fetchAbonnements();
  }

  void _refreshAbonnements() {
    setState(() {
      _futureAbonnements = fetchAbonnements();
    });
  }

  void _supprimerAbonnement(int id) async {
    final response = await http.delete(Uri.parse('http://192.168.137.1:8000/api/abonnements/$id'));
    if (response.statusCode == 200) {
      _refreshAbonnements();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Échec de la suppression de l\'abonnement.'),
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

  void _afficherFormulaireCreation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: NouvelAbonnementPage(),
      ),
    ).then((_) => _refreshAbonnements());
  }

  void _afficherFormulaireModification(Map<String, dynamic> abonnement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ModifierAbonnementPage(abonnement: abonnement),
      ),
    ).then((value) {
      if (value == true) {
        _refreshAbonnements();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des abonnements'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _afficherFormulaireCreation,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureAbonnements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(child: Text('Aucun abonnement disponible.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (context, index) {
                var abonnement = snapshot.data?[index];
                return ListTile(
                  title: Text('Abonnement ${abonnement['id']}'),
                  subtitle: Text('Lieu de départ: ${abonnement['lieu_depart']} - Destination: ${abonnement['lieu_destination']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _afficherFormulaireModification(abonnement);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _supprimerAbonnement(abonnement['id']),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AbonnementDetailsPage(abonnement: abonnement),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
