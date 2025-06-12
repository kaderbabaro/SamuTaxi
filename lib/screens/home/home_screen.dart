import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../model/course.dart';
import 'components/course_card.dart';

List<String> imageUrls = [
  "assets/icons/taxi.jpg",
  "assets/icons/allo.jpg",
  "assets/icons/bicycle.jpg",
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Fonction pour envoyer un email
  Future<void> sendEmail(BuildContext context, String suggestion) async {
    String username = 'your_email@gmail.com'; // Votre adresse e-mail
    String password = 'your_password'; // Votre mot de passe

    final smtpServer = gmail(username, password);

    // Création du message
    final message = Message()
      ..from = Address(username)
      ..recipients.add('recipient_email@example.com') // L'adresse e-mail du destinataire
      ..subject = 'Nouvelle suggestion'
      ..text = suggestion; // Le contenu du message (ici, la suggestion)

    try {
      final sendReport = await send(message, smtpServer);
      print('Message envoyé: ${sendReport.toString()}');
      // Afficher un message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Suggestion envoyée avec succès !'),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      // Afficher un message d'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Impossible d\'envoyer la suggestion.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController suggestionController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  viewportFraction: 0.8,
                ),
                items: imageUrls.map((imageUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.blue,
                            image: DecorationImage(
                              image: AssetImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Text("Commander un taxi, plus facile et rapide maintenant")
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              /*const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Plateformes",
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: courses
                      .map(
                        (course) => Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: CourseCard(
                        title: course.title,
                        iconSrc: course.iconSrc,
                        color: course.color,
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),*/
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Des suggestions ?",
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: suggestionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Écrivez vos suggestions ici...",
                  ),
                ),
              ),
              SizedBox(height: 10), // Espacement entre le champ de texte et le bouton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    String suggestion = suggestionController.text.trim();
                    if (suggestion.isNotEmpty) {
                      sendEmail(context, suggestion);
                      suggestionController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez entrer une suggestion.'),
                        ),
                      );
                    }
                  },
                  child: Text('Envoyer'),
                ),
              ),
              const SizedBox(height: 70,)
            ],
          ),
        ),
      ),
    );
  }
}
