import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../local_storage_services.dart';
import '../../screens/Vues/AjouterVehicule.dart';

class SignUpPageDriver extends StatefulWidget {
  const SignUpPageDriver({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPageDriver> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final phone = '+227${_phoneController.text.trim()}';
    final name = _nameController.text.trim();

    try {
      // 🔍 Étape 1 : vérifier si le numéro existe déjà
      final existingUser = await Supabase.instance.client
          .from('User')
          .select()
          .eq('numero_telephone', phone)
          .maybeSingle();

      if (existingUser != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ce numéro de téléphone existe déjà."),
          ),
        );
        return;
      }

      // 🧩 Étape 2 : insérer le nouvel utilisateur
      final response = await Supabase.instance.client
          .from('User')
          .insert({
        'nom': name,
        'numero_telephone': phone,
        'type_user': 'Chauffeur',
      })
          .select()
          .single();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inscription réussie !")),
      );

      // 💾 Sauvegarde en local
      await LocalStorageService.saveUser({
        'id': response['id'],
        'nom': response['nom'],
        'nom_utilisateur': response['nom_utilisateur'],
        'numero_telephone': response['numero_telephone'],
        'type_user': response['type_user'],
      });

      // 🚗 Redirection vers la page d’ajout de véhicule
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AddVehiclePage(userId: response['id'])),
      );
    } on PostgrestException catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur Supabase : ${error.message}")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Créer un compte",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Champ nom
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Champ requis';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Champ téléphone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: 'Ex: 93 00 11 22',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Champ requis';
                    if (value.length < 8) return 'Numéro invalide';
                    return null;
                  },
                ),

                const Spacer(),

                // Bouton principal
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Créer le compte',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
