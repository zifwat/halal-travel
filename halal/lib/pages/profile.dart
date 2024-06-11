import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halal/pages/login.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  void selectImage() {}

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        nameController.text = user.displayName ?? '';
        emailController.text = user.email ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          _buildPersonalInfoSection(),
          SizedBox(height: 20),
          _buildProfileSettingsSection(context),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      color: Colors.teal,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 0),
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/cover_photo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 58,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : NetworkImage(
                        FirebaseAuth.instance.currentUser?.photoURL ??
                            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                      ) as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: _selectImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            nameController.text,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            emailController.text,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Upload the image to Firebase Storage
      await _uploadImageToFirebase();
    }
  }

  Future<void> _uploadImageToFirebase() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}.jpg');
        await storageRef.putFile(_image!);

        // Get the download URL and update the user's profile with the image URL
        String downloadURL = await storageRef.getDownloadURL();
        await user.updatePhotoURL(downloadURL);

        // Save the download URL to Firestore under the user's document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profile_image': downloadURL,
        }, SetOptions(merge: true));

        // Fetch the updated user data
        await _fetchUserData();
      }
    } catch (e) {
      print('Error uploading image to Firebase: $e');
    }
  }

  Widget _buildProfileSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Profile Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        _buildProfileSettingItem(
          context,
          'Name',
          Icons.person,
          () {
            _showEditDialog(context, 'Name', nameController);
          },
        ),
        _buildProfileSettingItem(
          context,
          'Email',
          Icons.email,
          () {
            _showEditDialog(context, 'Email', emailController);
          },
        ),
        _buildProfileSettingItem(
          context,
          'Change Password',
          Icons.lock,
          () {
            _showPasswordChangeDialog(context);
          },
        ),
        _buildLogoutButton(
            context), // Add this line to include the logout button
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Icon(Icons.exit_to_app),
          SizedBox(width: 8),
          Text('Logout'),
          Spacer(),
          Icon(Icons.arrow_forward),
        ],
      ),
      onTap: () {
        _logout(context);
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigate to the authentication wrapper to handle the authentication state
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Widget _buildProfileSettingItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Row(
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(title),
          Spacer(),
          Icon(Icons.arrow_forward),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showEditDialog(
    BuildContext context,
    String field,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Enter new $field'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  if (field == 'Name') {
                    await user.updateProfile(displayName: controller.text);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': controller.text});
                  } else if (field == 'Email') {
                    await user.updateEmail(controller.text);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'email': controller.text});
                  }

                  // Fetch the updated user data
                  await _fetchUserData();
                }

                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPasswordChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Enter new password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Update the user password in Firebase
                  await user.updatePassword(passwordController.text);
                }

                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
