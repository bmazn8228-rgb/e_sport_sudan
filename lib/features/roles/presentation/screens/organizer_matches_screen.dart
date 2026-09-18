import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

class OrganizerMatchesScreen extends StatelessWidget {
  const OrganizerMatchesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المباريات المكتملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text('لا توجد مباريات مكتملة', style: TextStyle(color: Colors.white54, fontSize: 16)),
      ),
    );
  }
}
