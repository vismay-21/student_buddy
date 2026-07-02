import 'package:flutter/material.dart';

class LectureMock {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String teacher;
  final String room;
  final int colorValue;

  const LectureMock({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.room,
    required this.colorValue,
  });
}

class SubjectAttendanceMock {
  final String id;
  final String name;
  final double attendancePercent;
  final int targetPercent;
  final int canMiss;
  final int attended;
  final int total;
  final String status; // 'safe_to_skip' or 'must_attend'

  const SubjectAttendanceMock({
    required this.id,
    required this.name,
    required this.attendancePercent,
    required this.targetPercent,
    required this.canMiss,
    required this.attended,
    required this.total,
    required this.status,
  });
}

class FinanceAccountMock {
  final String id;
  final String name;
  final double balance;
  final IconData icon;

  const FinanceAccountMock({
    required this.id,
    required this.name,
    required this.balance,
    required this.icon,
  });
}

class TransactionMock {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final String category;
  final String account;
  final String dateString;

  const TransactionMock({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.account,
    required this.dateString,
  });
}

class TodoMock {
  final String id;
  final String title;
  final String subject;
  final String dueDateString;
  final String cognitiveLoad; // 'Low', 'Medium', 'High'
  final bool isCompleted;
  final String? description;
  final String? dueTime;
  final bool repeatTask;
  final String createdBy; // 'Manual', 'WhatsApp', 'AI', 'OCR'

  const TodoMock({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDateString,
    required this.cognitiveLoad,
    required this.isCompleted,
    this.description,
    this.dueTime,
    this.repeatTask = false,
    this.createdBy = 'Manual',
  });
}

class NotesFileMock {
  final String name;
  final String type; // 'PDF', 'PPT', 'DOCX'
  final String size;

  const NotesFileMock({required this.name, required this.type, required this.size});
}

class NotesUnitMock {
  final String unitNumber;
  final String unitTitle;
  final List<NotesFileMock> files;

  const NotesUnitMock({
    required this.unitNumber,
    required this.unitTitle,
    required this.files,
  });
}

class NotesSubjectMock {
  final String subjectName;
  final List<NotesUnitMock> units;

  const NotesSubjectMock({required this.subjectName, required this.units});
}

class ReviewItemMock {
  final String id;
  final String source; // 'WhatsApp', 'OCR'
  final String description;
  final String dateString;
  final Map<String, String> details;

  const ReviewItemMock({
    required this.id,
    required this.source,
    required this.description,
    required this.dateString,
    required this.details,
  });
}

class DummyData {
  static const List<LectureMock> lecturesMonday = [
    LectureMock(id: '1', name: 'Database Management Systems', startTime: '09:00', endTime: '09:55', teacher: 'Dr. Ramesh K.', room: 'B-204', colorValue: 0xFF3B82F6),
    LectureMock(id: '2', name: 'Computer Networks', startTime: '10:00', endTime: '10:55', teacher: 'Prof. Sarah Thomas', room: 'A-102', colorValue: 0xFF8B5CF6),
    LectureMock(id: '3', name: 'Software Engineering', startTime: '11:15', endTime: '12:10', teacher: 'Dr. Anita Roy', room: 'Lab 3', colorValue: 0xFF10B981),
    LectureMock(id: '4', name: 'Design & Analysis of Algorithms', startTime: '14:00', endTime: '14:55', teacher: 'Prof. V. Sharma', room: 'C-301', colorValue: 0xFFEC4899),
  ];

  static const List<LectureMock> lecturesTuesday = [
    LectureMock(id: '5', name: 'Computer Networks', startTime: '09:00', endTime: '09:55', teacher: 'Prof. Sarah Thomas', room: 'A-102', colorValue: 0xFF8B5CF6),
    LectureMock(id: '6', name: 'Operating Systems', startTime: '11:15', endTime: '12:10', teacher: 'Prof. John Doe', room: 'B-101', colorValue: 0xFFF59E0B),
    LectureMock(id: '7', name: 'Database Management Systems', startTime: '14:00', endTime: '15:30', teacher: 'Dr. Ramesh K.', room: 'B-204', colorValue: 0xFF3B82F6),
  ];

  static const List<LectureMock> lecturesWednesday = [
    LectureMock(id: '8', name: 'Software Engineering', startTime: '09:00', endTime: '09:55', teacher: 'Dr. Anita Roy', room: 'Lab 3', colorValue: 0xFF10B981),
    LectureMock(id: '9', name: 'Design & Analysis of Algorithms', startTime: '10:00', endTime: '10:55', teacher: 'Prof. V. Sharma', room: 'C-301', colorValue: 0xFFEC4899),
    LectureMock(id: '10', name: 'Operating Systems', startTime: '14:00', endTime: '14:55', teacher: 'Prof. John Doe', room: 'B-101', colorValue: 0xFFF59E0B),
  ];

  static const List<LectureMock> lecturesThursday = [
    LectureMock(id: '11', name: 'Database Management Systems', startTime: '09:00', endTime: '09:55', teacher: 'Dr. Ramesh K.', room: 'B-204', colorValue: 0xFF3B82F6),
    LectureMock(id: '12', name: 'Computer Networks', startTime: '11:15', endTime: '12:10', teacher: 'Prof. Sarah Thomas', room: 'A-102', colorValue: 0xFF8B5CF6),
    LectureMock(id: '13', name: 'Operating Systems Lab', startTime: '14:00', endTime: '16:00', teacher: 'Prof. John Doe', room: 'OS Lab', colorValue: 0xFFF59E0B),
  ];

  static const List<LectureMock> lecturesFriday = [
    LectureMock(id: '14', name: 'Design & Analysis of Algorithms', startTime: '09:00', endTime: '10:30', teacher: 'Prof. V. Sharma', room: 'C-301', colorValue: 0xFFEC4899),
    LectureMock(id: '15', name: 'Software Engineering', startTime: '11:15', endTime: '12:10', teacher: 'Dr. Anita Roy', room: 'Lab 3', colorValue: 0xFF10B981),
  ];

  static const List<LectureMock> lecturesWeekend = [];

  static List<LectureMock> getLecturesForDay(int dayIndex) {
    switch (dayIndex) {
      case 0: return lecturesMonday;
      case 1: return lecturesTuesday;
      case 2: return lecturesWednesday;
      case 3: return lecturesThursday;
      case 4: return lecturesFriday;
      default: return lecturesWeekend;
    }
  }

  static const List<SubjectAttendanceMock> attendanceList = [
    SubjectAttendanceMock(id: 'a1', name: 'Database Management Systems', attendancePercent: 78.57, targetPercent: 80, canMiss: 0, attended: 11, total: 14, status: 'must_attend'),
    SubjectAttendanceMock(id: 'a2', name: 'Computer Networks', attendancePercent: 88.24, targetPercent: 85, canMiss: 2, attended: 15, total: 17, status: 'safe_to_skip'),
    SubjectAttendanceMock(id: 'a3', name: 'Software Engineering', attendancePercent: 91.67, targetPercent: 80, canMiss: 3, attended: 11, total: 12, status: 'safe_to_skip'),
    SubjectAttendanceMock(id: 'a4', name: 'Design & Analysis of Algorithms', attendancePercent: 85.71, targetPercent: 80, canMiss: 1, attended: 12, total: 14, status: 'safe_to_skip'),
    SubjectAttendanceMock(id: 'a5', name: 'Operating Systems', attendancePercent: 90.12, targetPercent: 85, canMiss: 2, attended: 14, total: 16, status: 'safe_to_skip'),
  ];

  static const List<FinanceAccountMock> accounts = [
    FinanceAccountMock(id: 'acc1', name: 'UPI (GPay/PhonePe)', balance: 3450.00, icon: Icons.phone_android),
    FinanceAccountMock(id: 'acc2', name: 'Cash Wallet', balance: 450.00, icon: Icons.account_balance_wallet),
    FinanceAccountMock(id: 'acc3', name: 'Savings Account', balance: 12300.00, icon: Icons.account_balance),
    FinanceAccountMock(id: 'acc4', name: 'Pocket Money', balance: 800.00, icon: Icons.savings),
  ];

  static const List<TransactionMock> transactions = [
    TransactionMock(id: 't1', title: 'Lunch at Canteen', amount: 120.00, isIncome: false, category: 'Food', account: 'Cash Wallet', dateString: 'Today, 1:15 PM'),
    TransactionMock(id: 't2', title: 'Monthly Stipend', amount: 5000.00, isIncome: true, category: 'Stipend', account: 'Savings Account', dateString: 'Yesterday, 10:00 AM'),
    TransactionMock(id: 't3', title: 'Notebooks & Stationery', amount: 350.00, isIncome: false, category: 'Academics', account: 'UPI (GPay/PhonePe)', dateString: '20 Jun, 4:30 PM'),
    TransactionMock(id: 't4', title: 'Bus Pass Recharge', amount: 200.00, isIncome: false, category: 'Transport', account: 'UPI (GPay/PhonePe)', dateString: '18 Jun, 9:00 AM'),
    TransactionMock(id: 't5', title: 'Shared Uber Ride', amount: 80.00, isIncome: false, category: 'Transport', account: 'UPI (GPay/PhonePe)', dateString: '17 Jun, 6:15 PM'),
    TransactionMock(id: 't6', title: 'Movie Ticket', amount: 250.00, isIncome: false, category: 'Entertainment', account: 'UPI (GPay/PhonePe)', dateString: '15 Jun, 8:00 PM'),
  ];

  static const List<TodoMock> todoItems = [
    TodoMock(id: 'asg1', title: 'DBMS Normalization Assignment', subject: 'Database Management Systems', dueDateString: 'Tomorrow, 11:59 PM', cognitiveLoad: 'High', isCompleted: false),
    TodoMock(id: 'asg2', title: 'CN Socket Programming Lab', subject: 'Computer Networks', dueDateString: 'Fri, 26 Jun', cognitiveLoad: 'Medium', isCompleted: false),
    TodoMock(id: 'asg3', title: 'DAA Red-Black Tree Coding', subject: 'Design & Analysis of Algorithms', dueDateString: 'Mon, 29 Jun', cognitiveLoad: 'High', isCompleted: false),
    TodoMock(id: 'asg4', title: 'SE Requirement Specification', subject: 'Software Engineering', dueDateString: 'Completed 2 days ago', cognitiveLoad: 'Low', isCompleted: true),
  ];

  static const List<NotesSubjectMock> notesRepo = [
    NotesSubjectMock(
      subjectName: 'Database Management Systems',
      units: [
        NotesUnitMock(
          unitNumber: 'Unit 1',
          unitTitle: 'Introduction & ER Model',
          files: [
            NotesFileMock(name: 'DBMS_Unit1_Basics.pdf', type: 'PDF', size: '2.4 MB'),
            NotesFileMock(name: 'ER_Diagram_Cheatsheet.pdf', type: 'PDF', size: '1.1 MB'),
          ],
        ),
        NotesUnitMock(
          unitNumber: 'Unit 2',
          unitTitle: 'Relational Model & SQL',
          files: [
            NotesFileMock(name: 'SQL_Tutorial_Slides.ppt', type: 'PPT', size: '4.8 MB'),
            NotesFileMock(name: 'Practice_Queries.docx', type: 'DOCX', size: '512 KB'),
          ],
        ),
      ],
    ),
    NotesSubjectMock(
      subjectName: 'Computer Networks',
      units: [
        NotesUnitMock(
          unitNumber: 'Unit 1',
          unitTitle: 'Introduction & Physical Layer',
          files: [
            NotesFileMock(name: 'CN_Lec1_OSI_Model.pdf', type: 'PDF', size: '3.1 MB'),
          ],
        ),
        NotesUnitMock(
          unitNumber: 'Unit 2',
          unitTitle: 'Data Link Layer',
          files: [
            NotesFileMock(name: 'Sliding_Window_Protocols.ppt', type: 'PPT', size: '1.9 MB'),
          ],
        ),
      ],
    ),
    NotesSubjectMock(
      subjectName: 'Design & Analysis of Algorithms',
      units: [
        NotesUnitMock(
          unitNumber: 'Unit 1',
          unitTitle: 'Divide and Conquer',
          files: [
            NotesFileMock(name: 'Divide_and_Conquer_Lec.pdf', type: 'PDF', size: '5.2 MB'),
          ],
        ),
      ],
    ),
  ];

  static List<ReviewItemMock> reviewQueue = [
    ReviewItemMock(
      id: 'rev1',
      source: 'WhatsApp',
      description: 'Uncategorized expense logged from chatbot',
      dateString: 'Today, 10:45 AM',
      details: {
        'Message': 'spent 500 on dinner with friends',
        'Extracted Amount': '₹500.00',
        'Missing': 'Category & Source Account',
      },
    ),
    ReviewItemMock(
      id: 'rev2',
      source: 'OCR',
      description: 'Timetable schedule extraction confidence low',
      dateString: '21 Jun, 3:30 PM',
      details: {
        'Uploaded Image': 'timetable_scan_sem4.jpg',
        'Extracted Class': 'DAA Lab - Friday 14:00 - Room Lab 2 (Unverified)',
        'Issue': 'Text overlap detected',
      },
    ),
    ReviewItemMock(
      id: 'rev3',
      source: 'WhatsApp',
      description: 'Class cancelled announcement detected',
      dateString: '19 Jun, 11:15 AM',
      details: {
        'Message': 'Database lecture is off today because Ramesh sir is not coming',
        'Detected Action': 'Cancel Lecture - DBMS - Today 09:00 AM',
        'Status': 'Requires Confirmation',
      },
    ),
  ];
}
