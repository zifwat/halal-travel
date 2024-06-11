import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late CollectionReference<Map<String, dynamic>> users;

  String selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    users = FirebaseFirestore.instance.collection('users');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Set the color of the back button arrow to white
      ),
      backgroundColor: Colors.black, // Set the background color to black
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Filter by Role: ',
                  style: TextStyle(color: Color.fromARGB(255, 248, 248, 248)),
                ),
                DropdownButton<String>(
                  value: selectedRole,
                  style: TextStyle(
                      color: const Color.fromARGB(255, 241, 241, 241)),
                  onChanged: (newValue) {
                    setState(() {
                      selectedRole = newValue!;
                      fetchUsers();
                    });
                  },
                  items: ['All', 'Admin', 'User']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role,
                              style: TextStyle(color: Colors.black),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: users.get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No users found.');
                  }

                  final filteredUsers = snapshot.data!.docs.where((userDoc) {
                    final userData = userDoc.data();
                    if (selectedRole == 'All') {
                      return true;
                    } else {
                      return userData['role'] == selectedRole.toLowerCase();
                    }
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final userData = filteredUsers[index].data();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            '${userData['name']} (${userData['email']})',
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            'Role: ${userData['role']}',
                            style: TextStyle(color: Colors.black),
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: const Text('Delete Account'),
                              ),
                              PopupMenuItem(
                                value: 'updateRole',
                                child: const Text('Update Role'),
                              ),
                            ],
                            onSelected: (value) {
                              handleUserAction(value, userData);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void fetchUsers() {
    // Fetch and display users based on the selected role
    setState(() {
      // Reset userList to display filtered users
    });
  }

  void handleUserAction(String action, Map<String, dynamic> userData) {
    switch (action) {
      case 'delete':
        // Implement delete user logic
        deleteAccount(userData);
        break;
      case 'updateRole':
        // Implement update user role logic
        showRoleUpdateDialog(userData);
        break;
      default:
        break;
    }
  }

  void deleteAccount(Map<String, dynamic> userData) {
    String userId = userData[
        'userId']; // Replace with the actual field name for the user ID
    users.doc(userId).delete().then((value) {
      // Successfully deleted the user account
      // You may want to add additional logic here (e.g., show a confirmation message)
    }).catchError((error) {
      // Handle errors if any
      print('Error deleting user: $error');
      // You may want to show an error message to the user
    });
  }

  void showRoleUpdateDialog(Map<String, dynamic> userData) {
    // Implement a dialog to select the new role and update the user document
  }
}
