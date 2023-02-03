import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:lab3/Model/list_item.dart';

class CalendarScreen extends StatelessWidget {
  final List<ListItem> userEvents;

  const CalendarScreen({super.key, required this.userEvents});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalendar so termini za polaganje',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SfCalendar(
        view: CalendarView.month,
        firstDayOfWeek: 1,
        dataSource: MeetingDataSource(_getDataSource()),
        monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            appointmentDisplayCount: 2,
            showAgenda: true,
            agendaStyle: AgendaStyle(
              appointmentTextStyle: TextStyle(
                fontStyle: FontStyle.normal,
                fontSize: 18,
              ),
              dateTextStyle: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
              dayTextStyle: TextStyle(fontSize: 18, color: Colors.black),
            )),
      ),
    );
  }

  List<Event> _getDataSource() {
    final List<Event> events = <Event>[];
    for (var u in userEvents) {
      final DateTime start = u.datum;
      final DateTime end = start.add(const Duration(hours: 1));
      events.add(Event(u.predmet, start, end, Colors.green, false));
    }
    return events;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Event> source) {
    appointments = source;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}

class Event {
  Event(this.eventName, this.from, this.to, this.background, this.isAllDay);
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
}
