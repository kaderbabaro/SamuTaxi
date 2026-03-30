import 'package:flutter/material.dart';
import 'package:rive_animation/screens/HomeChauffeur/ChauffeurHomePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../HomeV2/HomeV2.dart';

class AddVehiclePage extends StatefulWidget {
  final String userId;
  const AddVehiclePage({required this.userId, Key? key}) : super(key: key);

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _permisController = TextEditingController();
  final TextEditingController _plaqueController = TextEditingController();
  final TextEditingController _taxiNumberController = TextEditingController();

  bool _isFetching = true;
  bool _isSaving = false;
  bool _vehicleExists = false;

  String _username = '';
  String _phone = '';
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadVehicle();
    _loadUserInfo();
  }

  Future<void> _loadVehicle() async {
    setState(() => _isFetching = true);

    final response = await Supabase.instance.client
        .from('Vehicule')
        .select()
        .eq('user_id', widget.userId)
        .maybeSingle();

    if (response != null) {
      _vehicleExists = true;
      _marqueController.text = response['marque'] ?? '';
      _permisController.text = response['numero_permis'] ?? '';
      _plaqueController.text = response['numero_plaque'] ?? '';
      _taxiNumberController.text = response['numero_taxi'] ?? '';
    } else {
      _vehicleExists = false;
    }

    setState(() => _isFetching = false);
  }

  Future<void> _loadUserInfo() async {
    final response = await Supabase.instance.client
        .from('User')
        .select('nom_utilisateur, numero_telephone, type_user') // ← ajouter le champ type
        .eq('id', widget.userId)
        .maybeSingle();

    if (response != null) {
      final username = response['nom_utilisateur'] ?? '';
      final phone = response['numero_telephone'] ?? '';
      final type = response['type_user'] ?? '';

      setState(() {
        _username = username;
        _phone = phone;
        _userType = type; // ← stocker
      });
    }
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    // Si un véhicule existe déjà, on affiche le popup et on bloque
    if (_vehicleExists) {
      await _showVehicleExistsDialog();
      return;
    }

    setState(() => _isSaving = true);

    // Sinon on insère
    await Supabase.instance.client.from('Vehicule').insert({
      'user_id': widget.userId,
      'marque': _marqueController.text,
      'numero_permis': _permisController.text,
      'numero_plaque': _plaqueController.text,
      'numero_taxi': _taxiNumberController.text,
      'created_at': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Véhicule ajouté avec succès 🚗")));

    setState(() => _isSaving = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChauffeurHomePage(userId: widget.userId)),
    );
  }


  Future<void> _deleteVehicle() async {
    // on supprime le véhicule
    await Supabase.instance.client
        .from('Vehicule')
        .delete()
        .eq('user_id', widget.userId);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Véhicule supprimé ✅")));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChauffeurHomePage(userId: widget.userId)),
    );
  }

  Future<void> _showVehicleExistsDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Action impossible"),
        content: const Text(
          "Vous avez déjà un véhicule enregistré.\n\n"
              "Pour en ajouter un nouveau, vous devez d'abord supprimer le véhicule existant.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Info du taxi"), backgroundColor: Colors.red),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child:  ListView(
            children: [
              // 🔹 Texte d’information avec un style
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Text(
                  "⚠️ Si vous n'ajoutez pas de véhicule, vous ne pouvez pas accepter de course.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(_marqueController, "Marque"),
              const SizedBox(height: 12),
              _buildTextField(_permisController, "Numéro de permis"),
              const SizedBox(height: 12),
              _buildTextField(_plaqueController, "Numéro de plaque"),
              const SizedBox(height: 12),
              _buildTextField(_taxiNumberController, "Numéro de taxi"),
              const SizedBox(height: 32),

              // Les deux boutons côte à côte
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitVehicle,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                         "Ajouter",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  if (_vehicleExists) const SizedBox(width: 12),
                  if (_vehicleExists)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _deleteVehicle,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text(
                          "Supprimer",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChauffeurHomePage(userId: widget.userId),));
                  },
                  child: const Text(
                    "Ignorer",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (value) =>
      value == null || value.isEmpty ? "Veuillez entrer $label" : null,
    );
  }
}
