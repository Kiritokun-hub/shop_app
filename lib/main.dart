import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vulcanizing_app_ignite_creative/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int selectedTab = 0;
  List<Widget> screens = [
    HomeScreen(),
    ProfileScreen(),
    InformationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Ignite Creative')),
        body: FirebaseAuth.instance.currentUser == null
            ? SignInScreen(
                providers: [EmailAuthProvider()],
                actions: [
                  AuthStateChangeAction<SignedIn>((context, state) {
                    setState(() {});
                  }),
                  AuthStateChangeAction<UserCreated>((context, state) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => InformationScreen(),
                    ));
                  }),
                ],
              )
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    final userRole = snapshot.data!.get('role');
                    if (userRole == 'Shop Owner') {
                      return screens[selectedTab];
                    } else {
                      // Return an error message if the user is not a shop owner
                      return Center(
                        child: Text('Only shop owners can login.'),
                      );
                    }
                  }
                },
              ),
        bottomNavigationBar: FirebaseAuth.instance.currentUser == null
            ? null
            : BottomNavigationBar(
                currentIndex: selectedTab,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                onTap: (value) {
                  setState(() {
                    selectedTab = value;
                  });
                },
              ),
      ),
    );
  }
}



class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('booking').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No bookings available.'),
            );
          } else {
            final bookings = snapshot.data!.docs;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final data = booking.data() as Map<String, dynamic>;
                return BookingCard(
                  bookingData: data,
                );
              },
            );
          }
        },
      ),
    );
  }
}



class BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingCard({Key? key, required this.bookingData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text('Name: ${bookingData['name'] ?? 'N/A'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone Number: ${bookingData['phoneNumber'] ?? 'N/A'}'),
            Text('Email: ${bookingData['email'] ?? 'N/A'}'),
            Text('Timestamp: ${bookingData['timestamp'] ?? 'N/A'}'),
            Text('UID: ${bookingData['userId'] ?? 'N/A'}'),
            Text('Current Location: ${bookingData['currentLocation'] ?? 'N/A'}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _acceptBooking(context, bookingData);
          },
          child: Text('Accept'),
        ),
      ),
    );
  }

  Future<void> _acceptBooking(BuildContext context, Map<String, dynamic> bookingData) async {
    try {
      String? location = bookingData['currentLocation'];
      if (location != null) {
        List<String> latLng = location.split(',');
        if (latLng.length == 2) {
          double latitude = double.parse(latLng[0].trim());
          double longitude = double.parse(latLng[1].trim());

          // Launch Google Maps with the provided latitude and longitude
          String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
          if (await canLaunch(googleMapsUrl)) {
            await launch(googleMapsUrl);
            return;
          } else {
            throw 'Could not launch Google Maps.';
          }
        } else {
          throw 'Invalid location format.';
        }
      } else {
        throw 'Location data is missing.';
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: const Text('Profile content goes here'),
      ),
    );
  }
}class InformationScreen extends StatefulWidget {
  @override
  _InformationScreenState createState() => _InformationScreenState();
}
class _InformationScreenState extends State<InformationScreen> {
  late User? _user;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _PhoneNumer = TextEditingController();
  final String _selectedRole = 'Shop Owner'; // Set the role to 'Shop Owner'

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 600,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'User ID: ${_user?.uid}',
                        style: TextStyle(fontSize: 20),
                      ),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                        
                      ),
                      
                      TextFormField(
                        controller: _PhoneNumer,
                        decoration: InputDecoration(labelText: 'Phone Number'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Phone Number';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveUserInfo();
                          }
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveUserInfo() async {
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user?.uid)
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'role': _selectedRole, // Set the role directly to 'Shop Owner'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User information saved successfully'),
        ),
      );

      // Navigate to the MainApp screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainApp()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }
}
