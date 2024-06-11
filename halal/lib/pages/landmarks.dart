import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(
    MaterialApp(
      home: Landmarks(),
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
    ),
  );
}

class Landmarks extends StatefulWidget {
  const Landmarks({Key? key}) : super(key: key);

  @override
  _LandmarksState createState() => _LandmarksState();
}

class _LandmarksState extends State<Landmarks> {
  String? selectedPlace;
  List<String> places = [];

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('landmarks').get();
    final allLandmarks = snapshot.docs;

    final placeSet = <String>{};
    for (var landmark in allLandmarks) {
      placeSet.add(landmark['place'] as String);
    }

    setState(() {
      places = placeSet.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products List', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedPlace,
              hint: const Text('Select a place'),
              items: places.map((place) {
                return DropdownMenuItem(
                  value: place,
                  child: Text(place),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPlace = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Place',
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: selectedPlace != null
                  ? LandmarksList(selectedPlace: selectedPlace!)
                  : const Center(
                      child: Text('Please select a place to see landmarks'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandmarksList extends StatelessWidget {
  final String selectedPlace;

  const LandmarksList({Key? key, required this.selectedPlace})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('landmarks')
          .where('place', isEqualTo: selectedPlace)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading data'),
          );
        }

        final landmarks = snapshot.data?.docs;

        if (landmarks == null || landmarks.isEmpty) {
          return const Center(
            child: Text('No landmarks found'),
          );
        }

        return ListView.builder(
          itemCount: landmarks.length,
          itemBuilder: (context, index) {
            final landmark = landmarks[index];
            return LandmarkCard(landmark: landmark);
          },
        );
      },
    );
  }
}

class LandmarkCard extends StatelessWidget {
  final DocumentSnapshot landmark;

  const LandmarkCard({Key? key, required this.landmark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
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
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        onTap: () {
          // Handle landmark tap if needed
        },
      ),
    );
  }
}
