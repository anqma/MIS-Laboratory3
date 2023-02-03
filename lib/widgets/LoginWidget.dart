import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lab3/main.dart';

class LoginWidget extends StatefulWidget {
  @override
  _LoginWidgetState createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 180),
          const Text(
            'TERMINI ZA POLAGANJE',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dobredojde',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: emailController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 4),
          TextField(
              controller: passwordController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: najaviSe,
              icon: const Icon(
                Icons.lock_open,
                size: 25,
              ),
              label: const Text(
                'Najavi se',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ))
        ]),
      );

  Future najaviSe() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print(e);
    }

    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
}
