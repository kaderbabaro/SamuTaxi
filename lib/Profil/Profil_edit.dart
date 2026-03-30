import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_animation/screens/Vues/AjouterVehicule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local_storage_services.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await Supabase.instance.client
          .from('User')
          .select()
          .eq('id', widget.userId)
          .single();

      _nomController.text = response['nom'] ?? '';
      _usernameController.text = response['nom_utilisateur'] ?? '';
      _phoneController.text =
          response['numero_telephone']?.replaceAll('+227', '') ?? '';
      _mailController.text = response['mail'] ?? '';
      _passwordController.text = response['mot_de_passe'] ?? '';
      _role = response['type_user']; 
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



  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await Supabase.instance.client
            .from('User')
            .update({
          'nom': _nomController.text.trim(),
          'nom_utilisateur': _usernameController.text.trim(),
          'numero_telephone': '+227${_phoneController.text.trim()}',
          'mail': _mailController.text.trim(),
        })
            .eq('id', widget.userId)
            .select();

        print("Résultat Supabase : $response"); // 🔹 Log complet
        print("User ID Flutter: ${widget.userId}");

        if (response == null || (response is List && response.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aucune ligne mise à jour. ID incorrect ou accès refusé.")),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour avec succès")),
        );

        Navigator.pop(context);
      } catch (e) {
        print("Erreur update: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  void dispose() {
    _nomController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _mailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Modifier votre profil"),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: const AssetImage('assets/avaters/logo_defaut.png'),
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nomController, 'Nom'),
                  const SizedBox(height: 16),
                  _buildTextField(_usernameController, 'Nom d\'utilisateur'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _phoneController,
                    'Numéro de téléphone',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _mailController,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  
                  if (_role == 'Chauffeur') ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AddVehiclePage(
                                      userId: widget.userId
                                  ),
                            )
                        );
                      },
                      child: const Text(
                        "Modifier les informations de mon taxi",
                        style: TextStyle(color: Colors.red, fontSize: 15),
                      ),
                    ),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Enregistrer",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.red,
        onPressed: _logout,
        child: const Icon(Icons.logout, color: Colors.white),
      ),
    );

  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Champ requis';
        return null;
      },
    );
  }
  void _logout() async {
    try {

      await LocalStorageService.clearUser();

      Navigator.of(context).pushNamedAndRemoveUntil(
          '/choixderole', (Route<dynamic> route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la déconnexion : $e")),
      );
    }
  }

}
