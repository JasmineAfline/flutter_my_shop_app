import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to My Shop!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (user != null) ...[
              Text('Logged in as:'),
              const SizedBox(height: 8),
              Text(
                user.email ?? 'No email',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {
                // Later you can navigate to products, profile, etc.
              },
              icon: const Icon(Icons.store),
              label: const Text('Go to Shop'),
            ),
          ],
        ),
      ),
    );
  }
}
