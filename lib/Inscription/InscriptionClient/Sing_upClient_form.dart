import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_animation/screens/HomeV2/HomeV2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../local_storage_services.dart';

class SignUpPageClient extends StatefulWidget {
  const SignUpPageClient({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPageClient> {
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final phone = '+227${_phoneController.text.trim()}';
      final name = _nameController.text.trim();

      try {
        final response = await Supabase.instance.client
            .from('User')
            .insert({
          'nom': name,
          'numero_telephone': phone,
          'type_user': 'Client',
        })
            .select()
            .single(); // ⬅ récupère directement la ligne insérée

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inscription réussie !")),
        );

        await LocalStorageService.saveUser({
          'id': response['id'],
          'nom': response['nom'],
          'nom_utilisateur': response['nom_utilisateur'],
          'numero_telephone': response['numero_telephone'],
          'type_user': response['type_user'],
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeV2(userId: response['id'], username: response['nom_utilisateur'], telephone: response['numero_telephone'],)),
        );
      } on PostgrestException catch (error) {
        setState(() {
          _isLoading = false;
        });

        if (error.code == '23505' ||
            (error.message.toLowerCase().contains('duplicate'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Ce numéro de téléphone existe déjà.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${error.message}")),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur inattendue : $e")),
        );
      }
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

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Champ requis';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: 'Ex: 93 00 11 22',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.red.shade300 : Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    'S\'inscrire',
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
