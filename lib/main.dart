import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lab3/widgets/notifi_service.dart';
import 'Model/list_item.dart';
import 'widgets/nov_element.dart';
import 'Screens/CalendarScreen.dart';
import 'widgets/LoginWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      home: MainPage(),
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
              return MyHomePage();
            } else {
              return LoginWidget();
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
      /*Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Najaven kako',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              user.email!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),*/
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              style: ButtonStyle(
                fixedSize:
                    MaterialStateProperty.all<Size>(const Size.fromWidth(900)),
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
        ),
      ),
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
