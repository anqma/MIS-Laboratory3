import 'package:flutter/material.dart';
import 'Model/list_item.dart';
import 'widgets/nov_element.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laboratoriska vezba',
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          textTheme: ThemeData.light()
              .textTheme
              .copyWith(titleMedium: const TextStyle(fontSize: 26))),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<ListItem> _userItems = [];

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

  void _deleteItem(String id) {
    setState(() {
      _userItems.removeWhere((elem) => elem.id == id);
    });
  }

  Widget _createBody() {
    return Center(
      child: _userItems.isEmpty
          ? const Text("Nema dodadeno termini za polaganje")
          : ListView.builder(
              itemBuilder: (ctx, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  child: ListTile(
                    title: Text(
                      _userItems[index].predmet,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22.0),
                    ),
                    subtitle: Text(
                      _userItems[index].datum,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteItem(_userItems[index].id),
                    ),
                  ),
                );
              },
              itemCount: _userItems.length,
            ),
    );
  }

  PreferredSizeWidget _createAppBar() {
    return AppBar(title: const Text("Termini za polaganje"), actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => _addItemFunction(context),
      )
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
