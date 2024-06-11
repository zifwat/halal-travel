import 'package:flutter/material.dart';
import 'package:halal/pages/itinerary_tab.dart';
import 'package:halal/pages/landmarks.dart';
import 'package:halal/pages/prayer_times.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'qibla_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<String>? allRestaurants;
  List<String>? allMosques;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          SizedBox(height: 10),
          _buildNavigationMenu(),
          SizedBox(height: 20),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildFeaturedPlaceItem(String name) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: SizedBox(
        width: 210,
        child: ListTile(
          title: Text(name),
          onTap: () {
            // Handle item tap
            print('Tapped on $name');
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/bangkok.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          height: 200,
        ),
        Positioned(
          bottom: 16.0,
          child: ElevatedButton(
            onPressed: () {
              // Handle button tap
              print('Button tapped');
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
            child: Text(
              'Thailand',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 360,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 255, 254, 254),
                Color.fromARGB(255, 243, 245, 243)
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 4,
                offset: Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuItem('Prayer Time', Icons.access_time),
                  _buildDivider(), // Add divider between menu items
                  _buildMenuItem('Qibla Direction', Icons.location_on),
                ],
              ),
              SizedBox(
                height: 9,
              ),
              Divider(
                color: Colors.grey, // Adjust the color of the divider
                height: 10, // Adjust the height of the divider
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuItem('Itinerary', Icons.explore),
                  _buildDivider(), // Add divider between menu items
                  _buildMenuItem('Landmarks', Icons.location_city),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 70,
      width: 1,
      color: Colors.grey, // You can adjust the color of the divider
    );
  }

  Widget _buildMenuItem(String text, IconData icon) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            // Handle navigation item tap
            print('$text tapped');

            if (text == 'Qibla Direction') {
              // Navigate to the QiblaDirectionPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QiblahCompass()),
              );
            }
            if (text == 'Prayer Time') {
              // Navigate to the QiblaDirectionPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrayerTimes()),
              );
            }
            if (text == 'Itinerary') {
              // Navigate to the QiblaDirectionPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ItineraryTab()),
              );
            }
            if (text == 'Landmarks') {
              // Navigate to the QiblaDirectionPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Landmarks()),
              );
            }
          },
          icon: Icon(
            icon,
            color: const Color.fromARGB(255, 34, 33, 33),
          ),
        ),
        SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(color: const Color.fromARGB(255, 8, 8, 8)),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Discover Halal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Explore the best halal places around you.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24.0),
          const SizedBox(height: 8.0),
          _buildSwipeableStack(),
        ],
      ),
    );
  }

  Widget _buildSwipeableStack() {
    return FutureBuilder<Map<String, List<String>?>?>(
      future: _fetchFeaturedPlaces(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError || snapshot.data == null) {
          return Text('Error loading featured places');
        } else {
          Map<String, List<String>?> places = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategoryTitle('Halal Restaurants'),
              SizedBox(
                height: 180.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: places['restaurants']!.length,
                  itemBuilder: (context, index) {
                    final restaurant = places['restaurants']![index];
                    return _buildFeaturedPlaceItem(restaurant);
                  },
                ),
              ),
              const SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () {
                  _showAllData('Halal Restaurants', places['restaurants']);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 255, 253, 253),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Show All',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              _buildCategoryTitle('Mosques'),
              SizedBox(
                height: 180.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: places['mosques']!.length,
                  itemBuilder: (context, index) {
                    final mosque = places['mosques']![index];
                    return _buildFeaturedPlaceItem(mosque);
                  },
                ),
              ),
              const SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () {
                  _showAllData('Mosques', places['mosques']);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 255, 253, 253),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Show All',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // Method to handle "Show All" button tap
  void _showAllData(String category, List<String>? data) {
    if (data != null && data.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('All $category'),
            content: Column(
              children: data.map((item) => Text(item)).toList(),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle the case where there is no data
      print('No data available for $category');
    }
  }
}

Widget _buildCategoryTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );
}

Future<Map<String, List<String>>?> _fetchFeaturedPlaces() async {
  try {
    final http.Client client = http.Client();

    final restaurantResponse = await client.get(
      Uri.parse(
        'https://api.foursquare.com/v3/places/search?ll=7.008578858747216%2C100.47434784056865&categories=13191',
      ),
      headers: {
        "accept": "application/json",
        "Authorization": "fsq3JHhX5Zxt6WlGqO+95daOMqduxODxW9rAMXwrYeOszXU=",
      },
    );

    final mosqueResponse = await client.get(
      Uri.parse(
        'https://api.foursquare.com/v3/places/search?ll=7.008578858747216%2C100.47434784056865&categories=12106',
      ),
      headers: {
        "accept": "application/json",
        "Authorization": "fsq3JHhX5Zxt6WlGqO+95daOMqduxODxW9rAMXwrYeOszXU=",
      },
    );

    if (restaurantResponse.statusCode == 200 &&
        mosqueResponse.statusCode == 200) {
      final Map<String, dynamic> restaurantData =
          json.decode(restaurantResponse.body);
      final Map<String, dynamic> mosqueData = json.decode(mosqueResponse.body);

      final List<dynamic>? restaurantVenues = restaurantData['results'];
      final List<dynamic>? mosqueVenues = mosqueData['results'];

      if (restaurantVenues != null && mosqueVenues != null) {
        final List<String> restaurants = restaurantVenues
            .map<String>((venue) => venue['name'].toString())
            .toList();

        final List<String> mosques = mosqueVenues
            .map<String>((venue) => venue['name'].toString())
            .toList();

        return {'restaurants': restaurants, 'mosques': mosques};
      } else {
        throw Exception('No venues found in the response');
      }
    } else {
      throw Exception('Failed to load featured places');
    }
  } catch (error) {
    print('Error: $error');
    return null;
  }
}
