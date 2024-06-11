import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:halal/Admin/admin_page.dart';
import 'package:halal/main.dart';
import 'package:halal/pages/login.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  // Check if 'role' field exists in the document
                  if (userSnapshot.data!.data()!.containsKey('role')) {
                    var userRole = userSnapshot.data!.data()?['role'] ?? 'user';

                    if (userRole == 'admin') {
                      // User is an admin, navigate to admin page
                      return const AdminPage();
                    } else {
                      // User is not an admin, navigate to user page
                      return const HomeScreen();
                    }
                  } else {
                    // Handle the case where 'role' field does not exist
                    print("User document does not contain 'role' field");
                    return const LoginPage();
                  }
                } else {
                  // Handle the case where the document does not exist
                  print("User document does not exist");
                  return const LoginPage();
                }
              },
            );
          }
          // User is not logged in, show the login page
          return const LoginPage();
        }
      },
    );
  }
}
