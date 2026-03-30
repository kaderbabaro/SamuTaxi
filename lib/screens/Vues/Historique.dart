import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  const HistoryPage({required this.userId, Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _courses = [];
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final response = await Supabase.instance.client
          .from('Course')
          .select()
          .eq('client__id', widget.userId)
          .order('created_at', ascending: false)
          .execute();

      // Vérifie si la réponse contient des données
      if (response.data == null) {
        throw Exception('Aucune donnée reçue de Supabase');
      }

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response.data as List);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement : $e")),
      );
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des courses'),
        backgroundColor: Colors.red,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
          ? const Center(child: Text('Aucune course trouvée'))
          : ListView.builder(
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.local_taxi, color: Colors.red),
              title: Text(
                  '${course['adresse_depart']} → ${course['adresse_arrivee']}'),
              subtitle: Text(
                  'Statut: ${course['statut']}\nDate: ${DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.parse(course['created_at']))}\nType: ${course['type_taxi'] ?? "Standard"}'),
              trailing: Text('${course['prix']} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
            ),
          );
        },
      ),
    );
  }
}
