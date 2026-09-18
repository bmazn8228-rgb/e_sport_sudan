import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

class OrganizerComplaintsScreen extends StatelessWidget {
  const OrganizerComplaintsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاعتراضات والشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text('لا توجد اعتراضات', style: TextStyle(color: Colors.white54, fontSize: 16)),
      ),
    );
  }
}
