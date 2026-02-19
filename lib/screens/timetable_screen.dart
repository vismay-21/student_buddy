import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/timetable_service.dart';
import '../models/subject.dart';
import '../models/class_session.dart';


class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}



class _TimetableScreenState extends State<TimetableScreen> {
  late int _selectedDayIndex;
  late PageController _dayPageController;
  late Map<int, Future<List<Map<String, dynamic>>>> _dayFutures;


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
    _dayFutures = {
      for (int i = 0; i < 7; i++)
        i: TimetableService().getClassesForDay(i),
    };

    

    // DateTime weekday:
    // Monday = 1
    // Sunday = 7
    int todayIndex = now.weekday - 1;

    _selectedDayIndex = todayIndex;

    _dayPageController = PageController(initialPage: _selectedDayIndex);


  }

  @override
void dispose() {
  _dayPageController.dispose();
  super.dispose();
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

          Expanded(
            child: PageView.builder(
              controller: _dayPageController,
              itemCount: 7,
              onPageChanged: (index) {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _dayFutures[index],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No classes added yet",
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    }

                    final classes = snapshot.data!;

                    return ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, i) {
                        final item = classes[i];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 8,
                              color: Color(item['color']),
                            ),
                            title: Text(item['name']),
                            subtitle: Text(
                                "${item['start_time']} - ${item['end_time']}\n${item['teacher']} • ${item['room']}"),
                          ),
                        );
                      },
                    );
                  },
                );
              },
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
                      _dayPageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
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