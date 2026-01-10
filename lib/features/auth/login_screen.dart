import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneCtrl = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Title
            const Text(
              'भारत मंडी',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'कमीशन एजेंट मॅनेजमेंट',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Phone Input
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'मोबाईल नंबर',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              maxLength: 10,
            ),
            const SizedBox(height: 20),

            // Login Button
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  // Simple login - directly go to dashboard
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'लॉगिन',
                  style: TextStyle(fontSize: 16),
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              'व्यवसाय सुरू करण्यासाठी लॉगिन करा',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }
}
