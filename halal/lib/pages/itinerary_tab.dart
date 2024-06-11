import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Itinerary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ItineraryTab(),
    );
  }
}

class ItineraryTab extends StatefulWidget {
  const ItineraryTab({Key? key}) : super(key: key);

  @override
  _ItineraryTabState createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  final List<String> destinations = [
    'Bangkok',
    'Chiang Mai',
    'Phuket',
    'Hat Yai'
  ];
  String? selectedDestination;
  int? numberOfDays;
  List<List<Map<String, String>>> itinerary = [];
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerary'),
        backgroundColor: Colors.green,
      ),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Destination:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedDestination,
                  onChanged: (value) {
                    setState(() {
                      selectedDestination = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a destination';
                    }
                    return null;
                  },
                  items: destinations
                      .map<DropdownMenuItem<String>>((String destination) {
                    return DropdownMenuItem<String>(
                      value: destination,
                      child: Text(
                        destination,
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Please select a destination',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Number of Days:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter number of days',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      numberOfDays = int.tryParse(value);
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of days';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid number of days';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      generateItinerary();
                    }
                  },
                  child: Text(
                    'Generate Itinerary',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: itinerary.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                'Day ${index + 1}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: itinerary[index]
                                    .map((activity) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(
                                            '${activity['time']}: ${activity['description']}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailsItineraryScreen(
                                      day: index + 1,
                                      activities: itinerary[index],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> generateItinerary() async {
    if (numberOfDays == null || numberOfDays! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Number of days must be greater than 0')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      itinerary = [];

      // Fetch interesting places, prayer times, and restaurants based on destination
      final places = await _fetchPlaces(selectedDestination!);
      final prayerTimes = await _fetchPrayerTimes(selectedDestination!);
      final restaurants = await _fetchRestaurants(selectedDestination!);

      // Generate itinerary for the given number of days
      for (int day = 0; day < numberOfDays!; day++) {
        List<Map<String, String>> activities = [];
        int currentTime = 8; // Start at 8:00 AM

        // Add breakfast
        activities.add({
          'time': _formatTime(currentTime, 'AM'),
          'description': 'Breakfast at ${restaurants[day % restaurants.length]}'
        });
        currentTime += 1; // Assume breakfast takes 1 hour

        // Add a place visit in the morning
        activities.add({
          'time': _formatTime(currentTime, 'AM'),
          'description': 'Visit ${places[day % places.length]}'
        });
        currentTime += 2; // Assume visiting a place takes 2 hours

        // Add lunch
        activities.add({
          'time': _formatTime(12, 'PM'),
          'description':
              'Lunch at ${restaurants[(day + 1) % restaurants.length]}'
        });

        // Add an afternoon place visit
        activities.add({
          'time': _formatTime(2, 'PM'),
          'description': 'Visit ${places[(day + 1) % places.length]}'
        });

        // Add prayer times
        final times = prayerTimes[day % prayerTimes.length];
        for (String prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
          activities.add({
            'time': _formatTimeFromString(times[prayer]!),
            'description': 'Pray $prayer'
          });
        }

        // Add dinner
        activities.add({
          'time': _formatTime(7, 'PM'),
          'description':
              'Dinner at ${restaurants[(day + 2) % restaurants.length]}'
        });

        // Add an evening activity
        activities.add({
          'time': _formatTime(9, 'PM'),
          'description': 'Evening walk or visit a local event'
        });

        // Sort activities by time
        activities.sort(
            (a, b) => _parseTime(a['time']!).compareTo(_parseTime(b['time']!)));

        itinerary.add(activities);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate itinerary: $e')),
      );
    }
  }

  String _formatTime(int hour, String period) {
    return '$hour:00 $period';
  }

  String _formatTimeFromString(String time24) {
    final dateFormat24 = DateFormat("HH:mm");
    final dateFormat12 = DateFormat("h:mm a");

    final dateTime = dateFormat24.parse(time24);
    return dateFormat12.format(dateTime);
  }

  DateTime _parseTime(String time12) {
    final dateFormat12 = DateFormat("h:mm a");
    return dateFormat12.parse(time12);
  }

  Future<List<String>> _fetchPlaces(String destination) async {
    final response = await http.get(
      Uri.parse(
        'https://api.foursquare.com/v3/places/search?near=$destination&categories=13191',
      ),
      headers: {
        "accept": "application/json",
        "Authorization": "fsq3JHhX5Zxt6WlGqO+95daOMqduxODxW9rAMXwrYeOszXU=",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> places = data['results'];
      return places.map((place) => place['name'].toString()).toList();
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<List<String>> _fetchRestaurants(String destination) async {
    final response = await http.get(
      Uri.parse(
        'https://api.foursquare.com/v3/places/search?near=$destination&categories=13065',
      ),
      headers: {
        "accept": "application/json",
        "Authorization": "fsq3JHhX5Zxt6WlGqO+95daOMqduxODxW9rAMXwrYeOszXU=",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> restaurants = data['results'];
      return restaurants
          .map((restaurant) => restaurant['name'].toString())
          .toList();
    } else {
      throw Exception('Failed to load restaurants');
    }
  }

  Future<List<String>> _fetchNearbyMosques(
      double latitude, double longitude) async {
    final response = await http.get(
      Uri.parse(
        'https://api.foursquare.com/v3/places/search?ll=$latitude%2C$longitude&categories=12106',
      ),
      headers: {
        "accept": "application/json",
        "Authorization": "fsq3JHhX5Zxt6WlGqO+95daOMqduxODxW9rAMXwrYeOszXU=",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> mosques = data['results'];
      return mosques.map((mosque) => mosque['name'].toString()).toList();
    } else {
      throw Exception('Failed to load nearby mosques');
    }
  }

  Future<List<Map<String, String>>> _fetchPrayerTimes(
      String destination) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final response = await http.get(
      Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity?city=$destination&country=TH&fajrAngle=18.0&ishaAngle=17.0&date=$formattedDate',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final timings = data['data']['timings'];
      return [
        {
          'Fajr': timings['Fajr'],
          'Dhuhr': timings['Dhuhr'],
          'Asr': timings['Asr'],
          'Maghrib': timings['Maghrib'],
          'Isha': timings['Isha']
        }
      ];
    } else {
      throw Exception('Failed to load prayer times');
    }
  }

  Future<List<String>> _fetchHotels(String destination) async {
    final response = await http.get(
      Uri.parse(
        'https://api.foursquare.com/v3/places/search?near=$destination&categories=19014',
      ),
      headers: {
        "accept": "application/json",
        "Authorization": "fsq3JHhX5Zxt6WlGqO+95daOMqduxODxW9rAMXwrYeOszXU=",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hotels = data['results'];
      return hotels.map((hotel) => hotel['name'].toString()).toList();
    } else {
      throw Exception('Failed to load hotels');
    }
  }
}

class DetailsItineraryScreen extends StatelessWidget {
  final int day;
  final List<Map<String, String>> activities;

  const DetailsItineraryScreen({
    required this.day,
    required this.activities,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Day $day Itinerary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activities for Day $day:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              for (Map<String, String> activity in activities)
                ListTile(
                  title: Text(activity['time']!),
                  subtitle: Text(activity['description']!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
