import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/Apiservices/Tarifs_services.dart';

class Constants {
  static const String unspecifiedText = 'Non spécifié';
  static const String appBarTitle = 'Tarifs';
  static const String detailsAppBarTitle = 'Détails du Tarif';
}

class TarifsList extends StatefulWidget {
  @override
  _TarifsListState createState() => _TarifsListState();
}

class _TarifsListState extends State<TarifsList> {
  final TarifService _tarifService = TarifService();
  Future<List<dynamic>>? _futureTarifs;

  @override
  void initState() {
    super.initState();
    _futureTarifs = _tarifService.getTarifs();

    _futureTarifs!.then((tarifs) {
      print('Tarifs récupérés depuis l\'API :');
      for (var tarif in tarifs) {
        print(tarif.keys); // Cette ligne imprime les clés de chaque objet JSON
      }
    });
  }

  void _showTarifDetails(int id) async {
    try {
      final tarif = await _tarifService.getTarif(id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TarifDetails(tarif: tarif),
        ),
      );
    } catch (e) {
      print('Erreur lors de la récupération du tarif: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération du tarif')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.appBarTitle),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureTarifs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.data!.isEmpty) {
            return Center(child: Text('Aucun tarif trouvé'));
          } else {
            return ListView.separated(
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final tarif = snapshot.data![index];
                final typeTarif = tarif['typeTarif'] ?? Constants.unspecifiedText;
                final prixPlage = tarif['prixPlage'] ?? Constants.unspecifiedText;
                final distance = tarif['distance'] ?? Constants.unspecifiedText;
                return ListTile(
                  title: Text('Type $typeTarif'),
                  subtitle: Text('Prix: $prixPlage frcfa/$distance km'),
                  onTap: () => _showTarifDetails(tarif['id']),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}

class TarifDetails extends StatelessWidget {
  final Map<String, dynamic> tarif;

  TarifDetails({required this.tarif});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.detailsAppBarTitle),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type de tarif: ${tarif['typeTarif'] ?? Constants.unspecifiedText}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Distance: ${tarif['distance']?.toString() ?? Constants.unspecifiedText} km', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Prix: ${tarif['prixPlage']?.toString() ?? Constants.unspecifiedText} Frcfa', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Description: ${tarif['description'] ?? Constants.unspecifiedText}', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
