import 'package:flutter/material.dart';
import 'radar_screen.dart';
import 'today_screen.dart';
import 'all_tasks_screen.dart';
import 'settings_screen.dart';

/// מעטפת ראשית עם ניווט תחתון בין ארבעת המסכים.
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index;

  static const _screens = [
    RadarScreen(),
    TodayScreen(),
    AllTasksScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  /// מאפשר ניווט חיצוני (למשל מהתראה).
  void goToTab(int i) {
    if (i >= 0 && i < _screens.length) {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.radar), label: 'רדאר'),
          BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny), label: 'היום שלי'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'כל המשימות'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'הגדרות'),
        ],
      ),
    );
  }
}
