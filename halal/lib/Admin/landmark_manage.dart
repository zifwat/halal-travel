import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      home: LandmarkManage(),
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
    ),
  );
}

class LandmarkManage extends StatefulWidget {
  const LandmarkManage({Key? key}) : super(key: key);

  @override
  _LandmarkManageState createState() => _LandmarkManageState();
}

class _LandmarkManageState extends State<LandmarkManage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmark Management'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlaceDropdown(),
                  const SizedBox(height: 20.0),
                  _selectedPlace != null
                      ? _buildLandmarksListCard(_selectedPlace!)
                      : Container(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: () {
                  _showAddLandmarkDialog();
                },
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select Place',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      value: _selectedPlace,
      items: ['Bangkok', 'Chiang Mai', 'Hatyai']
          .map((place) => DropdownMenuItem(
                value: place,
                child: Text(place),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedPlace = value;
        });
      },
    );
  }

  Widget _buildLandmarksListCard(String place) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Landmarks List - $place',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 16.0),
            LandmarksList(place: place),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddLandmarkDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Add Landmark'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _placeController,
                  decoration: InputDecoration(
                    labelText: 'Place',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                _imageFile != null
                    ? Image.file(
                        _imageFile!,
                        height: 150,
                      )
                    : Container(),
                TextButton(
                  onPressed: () {
                    _pickImage();
                  },
                  child: const Text('Pick Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addLandmark();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addLandmark() async {
    if (_imageFile == null) {
      return;
    }

    String imageUrl = await _uploadImage(_imageFile!);

    FirebaseFirestore.instance.collection('landmarks').add({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'place': _placeController.text,
      'imageUrl': imageUrl,
    });

    _clearControllers();
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = imageFile.path.split('/').last;
    Reference storageReference =
        FirebaseStorage.instance.ref().child('landmarks/$fileName');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask;
    String downloadURL = await storageReference.getDownloadURL();
    return downloadURL;
  }

  void _clearControllers() {
    _nameController.clear();
    _descriptionController.clear();
    _placeController.clear();
    setState(() {
      _imageFile = null;
    });
  }
}

class LandmarksList extends StatelessWidget {
  final String place;

  const LandmarksList({Key? key, required this.place}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('landmarks')
          .where('place', isEqualTo: place)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final landmarks = snapshot.data?.docs;

        if (landmarks == null || landmarks.isEmpty) {
          return const Text('No landmarks found');
        }

        return Column(
          children: landmarks
              .map((landmark) => LandmarkCard(landmark: landmark))
              .toList(),
        );
      },
    );
  }
}

class LandmarkCard extends StatelessWidget {
  final QueryDocumentSnapshot landmark;

  const LandmarkCard({Key? key, required this.landmark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListTile(
        leading: landmark['imageUrl'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  landmark['imageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : null,
        title: Text(
          landmark['name'] as String,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          landmark['description'] as String,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditLandmarkDialog(context, landmark);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmationDialog(context, landmark);
              },
            ),
          ],
        ),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        onTap: () {
          // Handle landmark tap if needed
        },
      ),
    );
  }

  Future<void> _showEditLandmarkDialog(
      BuildContext context, QueryDocumentSnapshot landmark) async {
    final TextEditingController _editNameController =
        TextEditingController(text: landmark['name'] as String);
    final TextEditingController _editDescriptionController =
        TextEditingController(text: landmark['description'] as String);
    final String currentImageUrl = landmark['imageUrl'];

    File? _editImageFile;

    Future<void> _pickEditImage() async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _editImageFile = File(pickedFile.path);
      }
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Edit Landmark'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _editNameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _editDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                currentImageUrl.isNotEmpty
                    ? Image.network(
                        currentImageUrl,
                        height: 150,
                      )
                    : Container(),
                _editImageFile != null
                    ? Image.file(
                        _editImageFile!,
                        height: 150,
                      )
                    : Container(),
                TextButton(
                  onPressed: () {
                    _pickEditImage();
                  },
                  child: const Text('Pick Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _editLandmark(
                  landmark.id,
                  _editNameController.text,
                  _editDescriptionController.text,
                  _editImageFile,
                  currentImageUrl,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editLandmark(
    String landmarkId,
    String newName,
    String newDescription,
    File? newImageFile,
    String currentImageUrl,
  ) async {
    String? newImageUrl;

    if (newImageFile != null) {
      newImageUrl = await _uploadImage(newImageFile);
      await FirebaseStorage.instance.refFromURL(currentImageUrl).delete();
    }

    FirebaseFirestore.instance.collection('landmarks').doc(landmarkId).update({
      'name': newName,
      'description': newDescription,
      'imageUrl': newImageUrl ?? currentImageUrl,
    });
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = imageFile.path.split('/').last;
    Reference storageReference =
        FirebaseStorage.instance.ref().child('landmarks/$fileName');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask;
    String downloadURL = await storageReference.getDownloadURL();
    return downloadURL;
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, QueryDocumentSnapshot landmark) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Delete Landmark'),
          content: const Text('Are you sure you want to delete this landmark?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteLandmark(landmark.id, landmark['imageUrl']);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteLandmark(String landmarkId, String imageUrl) {
    FirebaseFirestore.instance.collection('landmarks').doc(landmarkId).delete();
    FirebaseStorage.instance.refFromURL(imageUrl).delete();
  }
}
