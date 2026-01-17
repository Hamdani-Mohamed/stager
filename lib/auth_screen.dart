import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;
  var _email = '', _password = '', _name = '', _phone = '', _level = '', _skills = '';
  var _isCompany = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email, password: _password);
        if(mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email, password: _password);
        Map<String, dynamic> data = {'email': _email, 'role': _isCompany ? 'company' : 'student', 'name': _name, 'phone': _phone, 'createdAt': Timestamp.now()};
        if (!_isCompany) { data['level'] = _level; data['skills'] = _skills; }
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(data);
        if(mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Erreur"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? "Connexion" : "Créer un compte")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.lock_person, size: 80, color: Color(0xFF2EC4B6)),
                const SizedBox(height: 20),
                TextFormField(decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)), onSaved: (v) => _email = v!.trim(), validator: (v) => v!.contains('@') ? null : "Email invalide"),
                const SizedBox(height: 15),
                TextFormField(decoration: const InputDecoration(labelText: "Mot de passe", prefixIcon: Icon(Icons.lock_outline)), obscureText: true, onSaved: (v) => _password = v!.trim(), validator: (v) => v!.length < 6 ? "Min 6 caractères" : null),
                if (!_isLogin) ...[
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: SwitchListTile(title: const Text("Je suis une entreprise"), activeColor: const Color(0xFF2EC4B6), value: _isCompany, onChanged: (v) => setState(() => _isCompany = v)),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(decoration: InputDecoration(labelText: _isCompany ? "Nom Entreprise" : "Nom Étudiant", prefixIcon: const Icon(Icons.person_outline)), onSaved: (v) => _name = v!.trim(), validator: (v) => v!.isEmpty ? "Requis" : null),
                  const SizedBox(height: 15),
                  TextFormField(decoration: const InputDecoration(labelText: "Téléphone", prefixIcon: Icon(Icons.phone_outlined)), onSaved: (v) => _phone = v!.trim(), keyboardType: TextInputType.phone),
                  if (!_isCompany) ...[
                    const SizedBox(height: 15),
                    TextFormField(decoration: const InputDecoration(labelText: "Niveau", prefixIcon: Icon(Icons.school_outlined)), onSaved: (v) => _level = v!.trim()),
                    const SizedBox(height: 15),
                    TextFormField(decoration: const InputDecoration(labelText: "Compétences", prefixIcon: Icon(Icons.code)), onSaved: (v) => _skills = v!.trim()),
                  ]
                ],
                const SizedBox(height: 30),
                if (_isLoading) const CircularProgressIndicator() else SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: Text(_isLogin ? "SE CONNECTER" : "S'INSCRIRE"))),
                TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "Pas de compte ? S'inscrire" : "Déjà un compte ? Connexion", style: TextStyle(color: Colors.grey[600]))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
