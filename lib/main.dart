import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lab3/widgets/notifi_service.dart';
import 'Model/list_item.dart';
import 'widgets/nov_element.dart';
import 'Screens/CalendarScreen.dart';
import 'widgets/LoginWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:lab3/AppStrings.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService().initNotification();
  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Laboratoriska vezba',
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          textTheme: ThemeData.light()
              .textTheme
              .copyWith(titleMedium: const TextStyle(fontSize: 26))),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong!'),
              );
            } else if (snapshot.hasData) {
              return const MyHomePage();
            } else {
              return const LoginWidget();
            }
          },
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late GoogleMapController mapController;

  bool mapToggle = false;
  List<LatLng> polylineCoordinates = [];
  Position? currentLocation;

  Future<Position> position =
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => currentLocation = position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    Geolocator.getCurrentPosition().then((currloc) {
      setState(() {
        currentLocation = currloc;
        mapToggle = true;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _showLocations() {
    showModalBottomSheet(
        context: context,
        builder: (_) => SizedBox(
            width: MediaQuery.of(context).size.width,
            child: mapToggle
                ? GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(41.9965, 21.4314),
                      zoom: 12.0,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: setMarkers(_userItems),
                  )
                : const Center(child: Text('Se vcituva...'))));
  }

  Set<Marker> setMarkers(List<ListItem> userItems) {
    return userItems.map((element) {
      LatLng mesto = LatLng(element.mesto.latitude, element.mesto.longitude);
      return Marker(
        markerId: MarkerId(element.id),
        position: mesto,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: element.predmet),
      );
    }).toSet();
  }

  void _showDirection(ListItem predmet) {
    _getCurrentPosition();
    polylineCoordinates.clear();
    getPolyPoints(
      predmet.mesto.latitude,
      predmet.mesto.longitude,
      currentLocation!.latitude,
      currentLocation!.longitude,
    ).then((e) {
      if (polylineCoordinates.isEmpty) {
        setState(() {});
      } else {
        setState(() => showModalBottomSheet(
            context: context,
            builder: (_) => SizedBox(
                width: MediaQuery.of(context).size.width,
                child: mapToggle
                    ? GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(41.9965, 21.4314),
                          zoom: 12.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: setMarker(predmet),
                        polylines: {
                          Polyline(
                            polylineId: PolylineId(predmet.id),
                            points: polylineCoordinates,
                            color: Colors.blue,
                            width: 5,
                          ),
                        },
                      )
                    : const Center(child: Text('Se vcituva...')))));
      }
    });
  }

  Future<List<LatLng>?> getPolyPoints(
      double startLat, double startLon, double destLat, double destLon) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult route = await polylinePoints.getRouteBetweenCoordinates(
        AppStrings.googleMapsAPIKey,
        PointLatLng(startLat, startLon),
        PointLatLng(destLat, destLon),
        travelMode: TravelMode.driving);
    if (route.points.isNotEmpty) {
      for (PointLatLng point in route.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
      setState(() {});
      return polylineCoordinates;
    } else {
      return null;
    }
  }

  Set<Marker> setMarker(ListItem predmetLokacija) {
    return <Marker>{
      Marker(
        markerId: MarkerId(predmetLokacija.id),
        position: LatLng(
            predmetLokacija.mesto.latitude, predmetLokacija.mesto.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: predmetLokacija.predmet),
      )
    };
  }

  List<ListItem> _userItems = [];

  Future<List<ListItem>> readItems() => FirebaseFirestore.instance
      .collection('predmeti')
      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get()
      .then((response) => response.docs
          .map((element) => ListItem.fromJson(element.data()))
          .toList());

  void _addItemFunction(BuildContext ct) {
    showModalBottomSheet(
        context: ct,
        builder: (_) {
          return GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: NovElement(_addNewItemToList));
        });
  }

  void _addNewItemToList(ListItem item) {
    setState(() {
      _userItems.add(item);
    });
  }

  Future deleteItem(String id) async {
    try {
      await FirebaseFirestore.instance.collection("predmeti").doc(id).delete();
    } catch (e) {
      return false;
    }
  }

  void _showCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CalendarScreen(userEvents: _userItems.toList())),
    );
  }

  Widget _createBody() {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: FutureBuilder<List<ListItem>>(
              future: readItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    "Error! ${snapshot.error.toString()}",
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w500),
                  );
                } else if (snapshot.hasData) {
                  _userItems = snapshot.data!;
                  if (_userItems.isEmpty) {
                    const Text(
                      "Nema dodadeno termini za polaganje!",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                    );
                  }
                  return ListView(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    children: _userItems.map(buildItem).toList(),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              })),
      Expanded(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Row(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(
                      const Size.fromWidth(180)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
                onPressed: _showCalendar,
                child: const Text(
                  'Prikazi kalendar',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.normal),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all<Size>(
                      const Size.fromWidth(180)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
                onPressed: _showLocations,
                child: const Text(
                  'Prikazi mapa',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ],
        ),
      )),
    ]);
  }

  Widget buildItem(ListItem predmet) => ListTile(
        title: Text(
          predmet.predmet,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
        ),
        subtitle: Text(
          DateFormat("dd/MM/yyyy hh:mm").format(predmet.datum),
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: FittedBox(
          fit: BoxFit.fill,
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await deleteItem(predmet.id);
                  setState(() => {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  NotificationService().showNotification(
                      title: 'IMASH POLAGANJE!',
                      body:
                          '${predmet.predmet} na ${DateFormat("dd/MM/yyyy hh:mm").format(predmet.datum)}');
                },
                color: const Color.fromARGB(214, 189, 32, 32),
              ),
              IconButton(
                icon: const Icon(Icons.location_pin),
                onPressed: () async {
                  _showDirection(predmet);
                },
              ),
            ],
          ),
        ),
      );

  PreferredSizeWidget _createAppBar() {
    return AppBar(title: const Text("Termini za polaganje"), actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => _addItemFunction(context),
      ),
      IconButton(
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _createAppBar(),
      body: _createBody(),
    );
  }
}
