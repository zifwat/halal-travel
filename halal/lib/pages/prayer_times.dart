import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({Key? key}) : super(key: key);

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  late Map<String, dynamic> prayerTimesData;
  String selectedCity = 'Hatyai';
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    prayerTimesData = {}; // Initialize prayerTimesData here
    fetchPrayerTimes(selectedCity, currentDate);
  }

  Future<void> fetchPrayerTimes(String city, DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final String apiUrl =
        'https://api.aladhan.com/v1/timingsByCity?city=$city&country=TH&fajrAngle=18.0&ishaAngle=17.0&date=$formattedDate';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        prayerTimesData = data['data']['timings'];
      });
    } else {
      throw Exception('Failed to load prayer times');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prayer Times', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/mosque.jpg'),
                fit: BoxFit.fill,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selected City: $selectedCity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Current Date: ${DateFormat('MMMM dd, yyyy').format(currentDate)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: selectedCity,
              onChanged: (value) {
                setState(() {
                  selectedCity = value!;
                });
                fetchPrayerTimes(selectedCity, currentDate);
              },
              items: ['Hatyai', 'Bangkok', 'Chiang Mai', 'Phuket']
                  .map<DropdownMenuItem<String>>((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select City',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: prayerTimesData == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: <Widget>[
                      _buildPrayerTimeCard('Fajr', prayerTimesData['Fajr']),
                      _buildPrayerTimeCard('Dhuhr', prayerTimesData['Dhuhr']),
                      _buildPrayerTimeCard('Asr', prayerTimesData['Asr']),
                      _buildPrayerTimeCard(
                          'Maghrib', prayerTimesData['Maghrib']),
                      _buildPrayerTimeCard('Isha', prayerTimesData['Isha']),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(String prayerName, String? prayerTime) {
    if (prayerTime == null) {
      // Handle the case where prayerTime is null
      return Card(
        elevation: 3.0,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          title: Text(prayerName),
          subtitle: Text('Not available'),
        ),
      );
    }

    final formattedTime = DateFormat.jm().format(
      DateFormat('HH:mm').parse(prayerTime),
    );

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(prayerName),
        subtitle: Text(formattedTime),
      ),
    );
  }
}
