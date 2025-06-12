import 'package:flutter/material.dart';
import '../entryPoint/components/btm_nav_item.dart';


class AidePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aide'),
        backgroundColor: Colors.white54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Bienvenue dans l\'application de commande de taxi!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Comment ça marche:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.person_add, color: Colors.blueAccent),
              title: Text('Créer un compte:'),
              subtitle: Text('Commencez par créer un compte en fournissant vos informations personnelles.'),
            ),
            ListTile(
              leading: Icon(Icons.local_taxi, color: Colors.blueAccent),
              title: Text('Réserver un taxi:'),
              subtitle: Text('Une fois connecté, vous pouvez réserver un taxi en entrant votre lieu de départ, votre destination, et la date et l\'heure de départ souhaitées.'),
            ),
            ListTile(
              leading: Icon(Icons.track_changes, color: Colors.blueAccent),
              title: Text('Suivre votre réservation:'),
              subtitle: Text('Vous pouvez suivre l\'état de votre réservation dans la section "Mes Abonnements". Vous y trouverez les informations de votre réservation ainsi que les détails du chauffeur.'),
            ),
            SizedBox(height: 20),
            Text(
              'FAQ:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.blueAccent),
              title: Text('Comment puis-je annuler ma réservation?'),
              subtitle: Text('Vous pouvez annuler votre réservation en accédant à "Mes Abonnements" et en sélectionnant l\'option d\'annulation.'),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blueAccent),
              title: Text('Puis-je modifier les détails de ma réservation?'),
              subtitle: Text('Oui, vous pouvez modifier les détails de votre réservation avant la date et l\'heure de départ en accédant à "Mes Abonnements" et en sélectionnant l\'option de modification.'),
            ),
            ListTile(
              leading: Icon(Icons.support, color: Colors.blueAccent),
              title: Text('Comment contacter le support?'),
              subtitle: Text('Vous pouvez contacter le support en envoyant un email à samutaxisupport@gmail.com ou en appelant notre service client au (+227) 99-35-08-88.'),
            ),
            SizedBox(height: 20),
            Text(
              'Pour plus d\'informations, visitez notre site web ou consultez notre section de support dans l\'application.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

  }
}
