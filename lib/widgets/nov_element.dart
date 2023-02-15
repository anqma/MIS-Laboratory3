import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lab3/Model/list_item.dart';
import 'package:nanoid/nanoid.dart';
import 'package:geolocator/geolocator.dart';

class NovElement extends StatefulWidget {
  final Function addItem;

  const NovElement(this.addItem, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _NovElementState();
  }
}

class _NovElementState extends State<NovElement> {
  bool mapToggle = false;
  Position? currentLocation;

  final _predmetController = TextEditingController();
  final _datumController = TextEditingController();
  GoogleMapController? _mapController;

  final LatLng _center = const LatLng(41.9965, 21.4314);
  List<Marker> myMarker = [];

  DateTime pickedDate = DateTime.now();
  TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 30);
  late DateTime parsedTime;

  late String predmet;
  late DateTime datum;
  late LatLng _latLng;

  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _handleLocationPermission();

    Geolocator.getCurrentPosition().then((currloc) {
      setState(() {
        currentLocation = currloc;
        mapToggle = true;
      });
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

  Future addToDatabase({required ListItem item}) async {
    final docItem =
        FirebaseFirestore.instance.collection('predmeti').doc(item.id);
    final json = item.toJson();
    await docItem.set(json);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _handleTap(LatLng tappedPoint) {
    setState(() {
      myMarker = [];
      myMarker.add(Marker(
        markerId: MarkerId(tappedPoint.toString()),
        position: tappedPoint,
      ));
      _latLng = tappedPoint;
    });
  }

  void _submitData() {
    if (_datumController.text.isEmpty) {
      return;
    }

    final vnesenPredmet = _predmetController.text;
    final vnesenDatum = DateTime.parse(_datumController.text);
    final lat = _latLng.latitude;
    final lon = _latLng.longitude;
    GeoPoint geoPoint = GeoPoint(lat, lon);

    if (vnesenPredmet.isEmpty) {
      return;
    }

    final newItem = ListItem(
      id: nanoid(5),
      predmet: vnesenPredmet,
      datum: vnesenDatum,
      userId: auth.currentUser!.uid,
      mesto: geoPoint,
    );
    widget.addItem(newItem);
    addToDatabase(item: newItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          TextField(
            controller: _predmetController,
            decoration: const InputDecoration(
                labelText: "Ime na predmetot",
                labelStyle: TextStyle(fontSize: 22.0)),
            onSubmitted: (_) => _submitData(),
          ),
          TextField(
            controller: _datumController,
            decoration: const InputDecoration(
                labelText: "Datum i vreme na polaganje",
                labelStyle: TextStyle(fontSize: 22.0)),
            readOnly: true,
            onSubmitted: (_) => _submitData(),
            onTap: () async {
              pickedDate = (await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101)))!;
              String formattedDate =
                  DateFormat('yyyy-MM-dd').format(pickedDate);
              setState(() {
                _datumController.text = formattedDate;
              });

              pickedTime = (await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 12, minute: 0)))!;
              parsedTime =
                  DateFormat.jm().parse(pickedTime.format(context).toString());
              String formattedTime = DateFormat('HH:mm').format(parsedTime);
              setState(() {
                _datumController.text =
                    "${_datumController.text} $formattedTime";
              });
            },
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 200,
              child: mapToggle
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 12.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onTap: _handleTap,
                      markers: Set.from(myMarker),
                    )
                  : const Center(child: Text('Se vcituva...'))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all<Size>(
                        const Size.fromWidth(900)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  onPressed: _submitData,
                  child: const Text(
                    'Dodadi polaganje',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
