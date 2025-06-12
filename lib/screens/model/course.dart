import 'package:flutter/material.dart' show Color;

import 'package:flutter/material.dart';

class Course {
  final String title;
  final String description;
  final String iconSrc;
  final Color color;

  Course({
    required this.title,
    this.description = 'Recherche de taxis partagés',
    this.iconSrc = 'assets/icons/ios.svg', // Image par défaut si aucune n'est spécifiée
    this.color = const Color(0xFFFC0A0A),
  });
}

/*final List<Course> courses = [
  Course(
    title: "Apple",
  ),
  Course(
    title: "Android",
    iconSrc: "assets/icons/android.svg",
    color: const Color(0xFFFC0A0A),
  ),
];*/

final List<Course> recentCourses = [
  Course(
    title: "Entreprises\nNiamey-Taxi",
    color: const Color(0xFFE77322),
    iconSrc: "assets/Images/simple.jpg",
  ),
  Course(
      title: "Commande un taxi",
    iconSrc: "assets/Images/allo.jpg"
  ),
  Course(
    title: "Suis en temps réel",
    color: const Color(0xFFE77322),
    iconSrc: "assets/Images/bicycle.jpg",
  ),
];
