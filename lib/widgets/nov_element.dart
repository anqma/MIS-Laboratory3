import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lab3/Model/list_item.dart';
import 'package:nanoid/nanoid.dart';
import 'adaptive_flat_button.dart';

class NovElement extends StatefulWidget {
  final Function addItem;

  const NovElement(this.addItem);
  @override
  State<StatefulWidget> createState() => _NovElementState();
}

class _NovElementState extends State<NovElement> {
  final _predmetController = TextEditingController();
  final _datumController = TextEditingController();

  DateTime pickedDate = DateTime.now(); //datumot
  TimeOfDay pickedTime = const TimeOfDay(hour: 12, minute: 30);
  late DateTime parsedTime; //vremeto

  late String predmet;
  late DateTime datum;

  void _submitData() {
    if (_datumController.text.isEmpty) {
      return;
    }

    final vnesenPredmet = _predmetController.text;
    final vnesenDatum = _datumController.text;

    if (vnesenPredmet.isEmpty || vnesenDatum.isEmpty) {
      return;
    }

    final newItem =
        ListItem(id: nanoid(5), predmet: vnesenPredmet, datum: vnesenDatum);
    widget.addItem(newItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
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
            onSubmitted: (_) => _submitData(),
            onTap: () async {
              pickedDate = (await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101)))!;
              String formattedDate =
                  DateFormat('dd.MM.yyyy').format(pickedDate);
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
          TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.deepPurple.withOpacity(0.04);
                  }
                  if (states.contains(MaterialState.focused) ||
                      states.contains(MaterialState.pressed)) {
                    return Colors.deepPurple.withOpacity(0.12);
                  }
                  return null;
                },
              ),
            ),
            onPressed: _submitData,
            child: const Text(
              'Dodadi termin',
              style: TextStyle(fontSize: 22.0),
            ),
          )
        ],
      ),
    );
  }
}
