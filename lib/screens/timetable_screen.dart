import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late int _selectedDayIndex;

  final List<String> _days = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // DateTime weekday:
    // Monday = 1
    // Sunday = 7
    int todayIndex = now.weekday - 1;

    _selectedDayIndex = todayIndex;
  }

  String getFormattedDate() { //for the date shown on the top
  final now = DateTime.now();

  // Find Monday of this week
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  // Add selected day offset
  DateTime selectedDate = startOfWeek.add(Duration(days: _selectedDayIndex));

  int day = selectedDate.day;

  String suffix;
  if (day >= 11 && day <= 13) {
    suffix = "th";
  } else {
    switch (day % 10) {
      case 1:
        suffix = "st";
        break;
      case 2:
        suffix = "nd";
        break;
      case 3:
        suffix = "rd";
        break;
      default:
        suffix = "th";
    }
  }

  String month = DateFormat('MMMM').format(selectedDate);

  return "$day$suffix $month";
}

String getFullDayName() { //to get the full name of the day on top bar
  final now = DateTime.now();

  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  DateTime selectedDate = startOfWeek.add(Duration(days: _selectedDayIndex));

  return DateFormat('EEEE').format(selectedDate);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Timetable",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
        
        Padding( //the bar with day and date
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getFullDayName(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                getFormattedDate(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

          const Expanded( //the main expanded body unique for each day (most probably not sure)
            child: Center(
              child: Text(
                "No classes added yet",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),


          SizedBox( //the days bar 
            height: 60,
            child: Padding ( //this padding is to add space on both the sides of the day selector
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_days.length, (index) {

                  final bool isSelected = index == _selectedDayIndex;

                  return Expanded(
                    child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },

                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _days[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: Padding( // the add button
        padding: const EdgeInsets.only(bottom: 45), 
        child: FloatingActionButton(
        onPressed: () {
          // We'll implement Add Class later
        },
        child: const Icon(Icons.add),
      ),
      ),
    );
  }
}