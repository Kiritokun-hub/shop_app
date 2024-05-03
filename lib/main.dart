
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
    InformationShopScreen(),
  ];

  // Track whether dark mode is enabled
  bool isDarkModeEnabled = false;

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
    theme: isDarkModeEnabled ? ThemeData.dark() : ThemeData.light(),
    home: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/lugo.png',
              height: 40,
              width: 40,
            ),
            SizedBox(width: 8),
            Text(
              'Ignite Creative',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pacifico',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: FirebaseAuth.instance.currentUser == null
          ? SignInScreen(
              providers: [EmailAuthProvider()],
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  setState(() {});
                }),
                AuthStateChangeAction<UserCreated>((context, state) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => InformationShopScreen(),
                    ),
                  );
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
              backgroundColor: Color.fromARGB(255, 250, 227, 194), // Baguhin ang kulay ng background ng navigation bar
              currentIndex: selectedTab,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'Messages',
                ),
              ],
              onTap: (value) {
                setState(() {
                  selectedTab = value;
                });
              },
              selectedItemColor: Colors.black, // Baguhin ang kulay kapag pinipindot
            ),
    ),
  );
}
}

class HomeScreen extends StatefulWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> acceptedBookings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontFamily: 'Calibri',
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 166, 0),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(213, 36, 18, 2), Color.fromARGB(213, 36, 18, 2)], 
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: widget._firestore.collection('booking').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              print('Error fetching bookings: ${snapshot.error}');
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('No bookings available.',style: TextStyle(color: Colors.white),),
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
                    onBookingAccepted: (acceptedBooking) async {
                      await _acceptBooking(context, acceptedBooking, booking.id); // Pasa ang document ID ng booking
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingScreen(
          acceptedBookings: acceptedBookings,
          shopOwnerId: 'YOUR_SHOP_OWNER_ID', // Dito mo ilagay ang actual shop owner ID
        ),
      ),
    );
  },
  backgroundColor: Color.fromARGB(255, 255, 166, 0), // Palitan ang background color ng FloatingActionButton
  child: Icon(Icons.pending_actions),
),
    );
  }

  Future<void> _acceptBooking(BuildContext context, Map<String, dynamic> bookingData, String bookingId) async {
    try {
      // Get the current user's UID from Firebase Authentication
      String shopOwnerId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (shopOwnerId.isNotEmpty) {
        // Add the shop owner's ID to the booking data
        bookingData['shopOwnerId'] = shopOwnerId;

        // Move booking data to pending collection
        await widget._firestore.collection('pending').add(bookingData);

        // Delete the booking from the original collection using bookingId as document ID
        await widget._firestore.collection('booking').doc(bookingId).delete(); // Tanggalin ang dokumento mula sa booking collection

        // Add accepted booking to the list
        acceptedBookings.add(bookingData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking accepted successfully.'),
          ),
        );
      } else {
        // Handle the case where the user is not authenticated or the UID is empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: User not authenticated.'),
          ),
        );
      }
    } catch (error) {
      print('Error accepting booking: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting booking: $error'),
        ),
      );
    }
  }
}


class BookingCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final Function(Map<String, dynamic>) onBookingAccepted;

  const BookingCard({Key? key, required this.bookingData, required this.onBookingAccepted}) : super(key: key);

  @override
Widget build(BuildContext context) {
  return Card(
    elevation: 2,
    color: Color.fromARGB(255, 255, 221, 157), // Kulay ng card
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
      trailing: TextButton(
        onPressed: () {
          // Tawagin ang callback function na ipinasa mula sa HomeScreen
          onBookingAccepted(bookingData);
        },
        style: TextButton.styleFrom(
          backgroundColor: Color.fromARGB(211, 173, 98, 31), // Kulay ng accept button
        ),
        child: Text(
          'Accept',
          style: TextStyle(
            color: Colors.white, // Palitan ang kulay ng text sa button ng puti
          ),
        ),
      ),
    ),
  );
}

}


class PendingScreen extends StatelessWidget {
  const PendingScreen({Key? key, required String shopOwnerId, required List<Map<String, dynamic>> acceptedBookings})
      : super(key: key);

  @override
Widget build(BuildContext context) {
  // Get the UID of the current user
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  if (currentUserId == null) {
    // Handle the case where the user is not logged in
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Bookings'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text('User not logged in.'),
      ),
    );
  } else {
    print('Fetching pending bookings for shop owner ID: $currentUserId');

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Bookings'),
        backgroundColor: const Color.fromARGB(255, 255, 166, 0),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
        ],
      ),
        body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color.fromARGB(213, 36, 18, 2), const Color.fromARGB(213, 36, 18, 2)],
    ),
  ),
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
      .collection('pending')
      .where('shopOwnerId', isEqualTo: currentUserId)
      .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(),
        );
      } else if (snapshot.hasError) {
        print('Error fetching pending bookings: ${snapshot.error}');
        return Center(
          child: Text('Error: ${snapshot.error}'),
        );
      } else if (snapshot.data!.docs.isEmpty) {
        print('No pending bookings available for shop owner ID: $currentUserId');
        return Center(
          child: Text('No pending bookings available.',style: TextStyle(color: Colors.white),),
        );
      } else {
        final pendingBookings = snapshot.data!.docs;
        print('Found ${pendingBookings.length} pending bookings for shop owner ID: $currentUserId');
        return ListView.builder(
          itemCount: pendingBookings.length,
          itemBuilder: (context, index) {
            final bookingData = pendingBookings[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              color: const Color.fromARGB(255, 255, 221, 157), // Bagong kulay para sa card
              child: ListTile(
                title: Text('Pending Booking ${index + 1}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${bookingData['name'] ?? 'N/A'}'),
                    Text('Phone Number: ${bookingData['phoneNumber'] ?? 'N/A'}'),
                    Text('Email: ${bookingData['email'] ?? 'N/A'}'),
                    Text('Timestamp: ${bookingData['timestamp'] ?? 'N/A'}'),
                    Text('UID: ${bookingData['userId'] ?? 'N/A'}'),
                    Text('Current Location: ${bookingData['currentLocation'] ?? 'N/A'}'),
                  ],
                ),
                trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    ElevatedButton(
      onPressed: () {
        _navigateToLocation(bookingData['currentLocation']);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(211, 173, 98, 31), // Kulay ng button
      ),
      child: Text('Navigate',style: TextStyle(color: Colors.white),),
    ),
    SizedBox(width: 8), // Add space between buttons
    ElevatedButton(
      onPressed: () {
        _finishBooking(context, pendingBookings[index].id, bookingData);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(211, 173, 98, 31), // Kulay ng button
      ),
      child: Text('Finish', style: TextStyle(color: Colors.white),),
    ),
  ],
),

              ),
            );
          },
        );
      }
    },
  ),
),

        floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.pop(context); // Go back to HomeScreen
  },
  backgroundColor: const Color.fromARGB(255, 255, 166, 0), // Palitan ang background color ng FloatingActionButton
  child: Icon(Icons.arrow_back),
),
      );
    }
  }

  void _navigateToLocation(String? location) async {
    if (location != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$location';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('Could not launch $url');
      }
    }
  }

  void _finishBooking(BuildContext context, String bookingId, Map<String, dynamic> bookingData) async {
    try {
      // Add booking data to finish collection
      await FirebaseFirestore.instance.collection('finish').doc(bookingId).set(bookingData);

      // Delete booking from pending collection
      await FirebaseFirestore.instance.collection('pending').doc(bookingId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking finished successfully.'),
        ),
      );
    } catch (error) {
      print('Error finishing booking: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finishing booking: $error'),
        ),
      );
    }
  }
}


class HistoryScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Booking History'),
      backgroundColor: Color.fromARGB(255, 255, 166, 0), // Palitan ang background color ng AppBar
    ),
    body: Container(
      color: const Color.fromARGB(213, 36, 18, 2), // Palitan ang background color ng Container
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('finish').snapshots(),
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
            final List<DocumentSnapshot> documents = snapshot.data!.docs;
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 2,
                    color: Color.fromARGB(255, 255, 221, 157), // Palitan ang background color ng Card
                    child: ListTile(
                      title: Text('Booking ${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${data['name'] ?? 'N/A'}'),
                          Text('Phone Number: ${data['phoneNumber'] ?? 'N/A'}'),
                          Text('Email: ${data['email'] ?? 'N/A'}'),
                          Text('Timestamp: ${data['timestamp'] ?? 'N/A'}'),
                          Text('UID: ${data['userId'] ?? 'N/A'}'),
                          Text('Current Location: ${data['currentLocation'] ?? 'N/A'}'),
                          Text('Status: ${data['status'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    ),
  );
}

}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Function to fetch admin messages from Firestore
  Future<List<Map<String, dynamic>>> _fetchAdminMessages() async {
  try {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get the current user's ID
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId) // Filter messages for the current user
        .orderBy('timestamp', descending: true)
        .get();
    
    List<Map<String, dynamic>> messages = [];
    querySnapshot.docs.forEach((doc) {
      messages.add({
        'message': doc['message'], // Retrieve message field
        'timestamp': doc['timestamp'], // Retrieve timestamp field
      });
    });
    
    return messages;
  } catch (e) {
    print('Error fetching admin messages: $e');
    throw e; // Rethrow the error for handling in UI
  }
}

  // Function para i-convert ang timestamp sa tamang format
  String formatTimestamp(Timestamp timestamp) {
    // Convert Timestamp object to DateTime
    DateTime dateTime = timestamp.toDate();

    // I-format ang DateTime sa iyong gusto na format
    String formattedDateTime = DateFormat('MMMM d, yyyy, hh:mm a').format(dateTime);

    return formattedDateTime;
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Messages'),
      backgroundColor: const Color.fromARGB(255, 255, 166, 0),
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
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(213, 36, 18, 2), // Ito ang iyong background color
            const Color.fromARGB(213, 36, 18, 2), // Ito rin ang iyong background color
          ],
        ),
      ),
      child: Center( // I-wrap ang mga laman ng Container gamit ang Center widget
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Admin Messages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), // Baguhin ang kulay ng text
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAdminMessages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white), // Baguhin ang kulay ng text
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Align(
                      alignment: Alignment.center,
                      child: Text(
                        'No messages found.',
                        style: TextStyle(color: Colors.white), // Baguhin ang kulay ng text
                      ),
                    );
                  }
                  List<Map<String, dynamic>> messages = snapshot.data!;
                  return Column(
                    children: messages.map((message) {
                      return Card(
                        elevation: 4,
                        color: Color.fromARGB(255, 255, 235, 179), // Baguhin ang kulay ng card
                        child: ListTile(
                          title: Text(message['message'], style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))), // Baguhin ang kulay ng text
                          subtitle: Text(
                            'Sent: ${formatTimestamp(message['timestamp'])}',
                            style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)), // Baguhin ang kulay ng text
                          ),
                        ),
                      );
                    }).toList(),
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


}

class InformationShopScreen extends StatefulWidget {
  @override
  _InformationShopScreenState createState() => _InformationShopScreenState();
}

class _InformationShopScreenState extends State<InformationShopScreen> {
  late User? _user;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _proofOfPaymentController = TextEditingController();
  final String _selectedRole = 'Shop Owner';
  Uint8List? _imageBytes;

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
              color: const Color.fromARGB(255, 255, 221, 157), // Set color for the card
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
                        controller: _phoneNumberController,
                        decoration: InputDecoration(labelText: 'Phone Number'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Phone Number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _proofOfPaymentController,
                        decoration: InputDecoration(labelText: 'Proof of Payment'),
                        validator: (value) {
                          if (_imageBytes == null) {
                            return 'Please upload proof of payment';
                          }
                          return null;
                        },
                        readOnly: true,
                        onTap: _selectImage,
                      ),
                      ElevatedButton(
  onPressed: () {
    if (_formKey.currentState!.validate()) {
      _saveUserInfo();
    }
  },
  style: ButtonStyle(
    backgroundColor: MaterialStateProperty.all<Color>(Color.fromARGB(211, 173, 98, 31)),
  ),
  child: Text(
    'Save',
    style: TextStyle(color: Colors.white),
  ),
),
SizedBox(height: 20),
_imageBytes == null
  ? ElevatedButton(
      onPressed: () {
        _selectImage();
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Color.fromARGB(211, 173, 98, 31)),
      ),
      child: Text(
        'Upload Proof of Payment',
        style: TextStyle(color: Colors.white),
      ),
    )
  : Column(
      children: [
        Image.memory(
          _imageBytes!,
          width: 200,
          height: 200,
        ),
        ElevatedButton(
          onPressed: () {
            _uploadImage();
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Color.fromARGB(211, 173, 98, 31)),
          ),
          child: Text(
            'Confirm Upload',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
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
  void _registerAndDisableUser( String email, String password) async {
  try {
    // Register user using FirebaseAuth
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Get the user's ID
    String userId = userCredential.user!.uid;
    
    // Save user information to Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      // User information fields here
    });
    
    // Disable the user in FirebaseAuth
    await FirebaseAuth.instance.currentUser!.delete();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User registered and account disabled successfully'),
      ),
    );
    
    // Redirect to another screen or perform any other actions
  } catch (error) {
    // Handle any errors that occur
    print('Error registering and disabling user: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error registering and disabling user: $error'),
      ),
    );
  }
}


void _saveUserInfo() async {
  String firstName = _firstNameController.text;
  String lastName = _lastNameController.text;
  String phoneNumber = _phoneNumberController.text;
  String proofOfPaymentUrl = _imageBytes != null ? await _uploadImage() : '';

  try {
    // Makakuha ng kasalukuyang petsa
    DateTime now = DateTime.now();
    // Format ng petsa para sa Firestore
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    // I-save ang impormasyon ng gumagamit sa Firestore
    await FirebaseFirestore.instance.collection('users').doc(_user?.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': _selectedRole,
      'proofOfPaymentUrl': proofOfPaymentUrl,
      'approved': false,
      'date': formattedDate, // I-save ang petsa
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User information saved successfully'),
      ),
    );

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

  void _selectImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Read bytes from picked file
      setState(() {
        _imageBytes = Uint8List.fromList(bytes); // Convert bytes to Uint8List
      });
    }
  }

  Future<String> _uploadImage() async {
    try {
      String fileName = _user!.uid + '_proofOfPaymentUrl.jpg';
      Reference storageReference = FirebaseStorage.instance.ref().child('proofOfPaymentUrl/$fileName');
      UploadTask uploadTask = storageReference.putData(_imageBytes!); // Use putData for Uint8List
      await uploadTask.whenComplete(() => null);
      String imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading proof of payment: $error'),
        ),
      );
      return '';
    }
  }
}
