import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lab3/Model/list_item.dart';
import 'package:nanoid/nanoid.dart';

class NovElement extends StatefulWidget {
  final Function addItem;

  const NovElement(this.addItem);
  @override
  State<StatefulWidget> createState() => _NovElementState();
}

class _NovElementState extends State<NovElement> {
  final _predmetController = TextEditingController();
  final _datumController = TextEditingController();

  DateTime pickedDate = DateTime.now();
  TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 30);
  late DateTime parsedTime;

  late String predmet;
  late DateTime datum;

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future addToDatabase({required ListItem item}) async {
    final docItem =
        FirebaseFirestore.instance.collection('predmeti').doc(item.id);
    final json = item.toJson();
    await docItem.set(json);
  }

  void _submitData() {
    if (_datumController.text.isEmpty) {
      return;
    }

    final vnesenPredmet = _predmetController.text;
    final vnesenDatum = DateTime.parse(_datumController.text);

    if (vnesenPredmet.isEmpty) {
      return;
    }

    final newItem = ListItem(
        id: nanoid(5),
        predmet: vnesenPredmet,
        datum: vnesenDatum,
        userId: auth.currentUser!.uid);
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
                    'Dodadi termin',
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
