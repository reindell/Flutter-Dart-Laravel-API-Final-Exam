import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final first_name = TextEditingController();
  final last_name = TextEditingController();
  final email = TextEditingController();
  final contact = TextEditingController();
  final username = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();
  final address = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text("Create Account",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            _regField("First Name", first_name),
            _regField("Last Name", last_name),
            _regField("Email Address", email, keyboardType: TextInputType.emailAddress),
            _regField("Contact Number", contact, keyboardType: TextInputType.phone),
            _regField("Address", address),
            _regField("Username", username),
            _regField("Password", pass, isPass: true),
            _regField("Confirm Password", confirmPass, isPass: true),

            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: Colors.blue[900]),
              onPressed: () async {
                // 1. Password Match Validation
                if (pass.text != confirmPass.text) {
                  _showError("Passwords do not match!");
                  return;
                }

                // 2. Empty Field Validation
                if (username.text.isEmpty || pass.text.isEmpty || first_name.text.isEmpty || email.text.isEmpty) {
                  _showError("Please fill in all required fields");
                  return;
                }

                // 3. Simple Email Format Validation
                if (!email.text.contains('@')) {
                  _showError("Please enter a valid email address");
                  return;
                }

                setState(() => isLoading = true);

                // Send data to Provider
                bool success = await context.read<AppProvider>().register({
                  'first_name': first_name.text,
                  'last_name': last_name.text,
                  'email': email.text,
                  'contact': contact.text,
                  'address': address.text,
                  'username': username.text,
                  'password': pass.text,
                });

                if (!mounted) return;
                setState(() => isLoading = false);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Registration Successful!")),
                  );
                  Navigator.pop(context);
                } else {
                  _showError("Registration Failed. Username or Email might already exist.");
                }
              },
              child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login", style: TextStyle(color: Colors.yellow)),
            )
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _regField(String hint, TextEditingController controller, {bool isPass = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}