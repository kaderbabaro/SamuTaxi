import 'package:flutter/material.dart';

class AbonnementDetailsPage extends StatelessWidget {
  final Map<String, dynamic> abonnement;

  AbonnementDetailsPage({required this.abonnement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'abonnement'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.confirmation_number, 'ID:', abonnement['id']),
            _buildDetailRow(Icons.info, 'État:', abonnement['etat']),
            _buildDetailRow(Icons.location_on, 'Lieu de départ:', abonnement['lieu_depart']),
            _buildDetailRow(Icons.flag, 'Lieu de destination:', abonnement['lieu_destination']),
            _buildDetailRow(Icons.calendar_today, 'Date de départ:', abonnement['date_depart']),
            _buildDetailRow(Icons.calendar_today, 'Date de réservation:', abonnement['date_reservation']),
            _buildDetailRow(Icons.monetization_on, 'Prix de l\'abonnement:', abonnement['prix_abonnement']),
            _buildDetailRow(Icons.person, 'Chauffeur ID:', abonnement['chauffeur_id']),
            _buildDetailRow(Icons.person, 'Client ID:', abonnement['client_id']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
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
              value.toString(),
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
