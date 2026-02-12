import 'package:flutter/material.dart';

void main() {
  runApp(const StudentBuddyApp());
}

class StudentBuddyApp extends StatelessWidget {
  const StudentBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Buddy',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Buddy'),
      ),
      body: const Center(
        child: Text(
          'App Skeleton Ready',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
