import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rive_animation/screens/Vues/CoursePage.dart';
import 'package:rive_animation/screens/Vues/PrendreClient.dart';
import '../../services/Apiservices/Courses_services.dart';

class CourseList extends StatefulWidget {
  @override
  _CourseListState createState() => _CourseListState();
}

class _CourseListState extends State<CourseList> {
  late Future<List<dynamic>> _courses;

  @override
  void initState() {
    super.initState();
    _courses = CourseService().getCourses(); // Utilisez la méthode getCourses() de votre service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses disponibles'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _courses,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var course = snapshot.data![index];
                return ListTile(
                  title: Text(course['destination_course']),
                  subtitle: Text(course['statut']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetail(course: course),
                      ),
                    );
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

class CourseDetail extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetail({Key? key, required this.course}) : super(key: key);

  @override
  _CourseDetailState createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  late String courseStatus;

  @override
  void initState() {
    super.initState();
    courseStatus = widget.course['statut'];
  }

  Future<void> updateCourse(BuildContext context) async {
    final url = Uri.parse('http://192.168.137.1:8000/api/courses/${widget.course['id']}');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'duree': 0,
        'prix_course': widget.course['prix_course'],
        'distance': widget.course['distance'],
        'lieu_prise_course': widget.course['lieu_prise_course'],
        'destination_course': widget.course['destination_course'],
        'statut': 'Course acceptée', // Assuming 'Course acceptée' is the new status
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        courseStatus = 'Course acceptée';
        widget.course['statut'] = 'Course acceptée';
      });
      Navigator.pushReplacementNamed(
        context,
        '/clientdestination',
        arguments: {'destination': widget.course['lieu_prise_course']},
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course acceptée avec succès')));
      await Future.delayed(Duration(seconds: 2));
      MaterialPageRoute(builder: (context) => Prendreclient());

    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec: la course n\'est pas acceptée')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Course'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.location_on, 'Lieu de prise de course:', widget.course['lieu_prise_course']),
            _buildDetailRow(Icons.flag, 'Destination de la course:', widget.course['destination_course']),
            //_buildDetailRow(Icons.access_time, 'Durée:', widget.course['duree']),
            _buildDetailRow(Icons.monetization_on, 'Prix de la course:', widget.course['prix_course']),
            _buildDetailRow(Icons.directions_car, 'Distance:', widget.course['distance']),
            _buildDetailRow(Icons.check_circle, 'Statut:', courseStatus),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: courseStatus == 'Course acceptée' ? null : () => updateCourse(context),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Accepter'.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: courseStatus == 'Course acceptée' ? Colors.grey : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.red),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
