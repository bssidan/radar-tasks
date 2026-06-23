import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnbData(
      icon: Icons.radar,
      title: 'רדאר התלויות הניהולי',
      body:
          'לא רשימת משימות רגילה — אלא ניהול תלויות בין אנשים. כל משימה ממוקמת לפי "מי מחכה למי".',
    ),
    _OnbData(
      icon: Icons.grid_view,
      title: 'ארבע הקטגוריות',
      body:
          'מחכים לי (אדום) · בטיפול פעיל (ירוק) · אני מחכה להם (כחול) · יום אחד/מוקפא (אפור). כל משימה שייכת לאחת מהן.',
    ),
    _OnbData(
      icon: Icons.add_circle,
      title: 'הוספת משימה',
      body:
          'לחץ על כפתור ה-"+" בכל מסך, או על "+" בתוך כרטיסיית קטגוריה כדי שהקטגוריה תיבחר אוטומטית.',
    ),
    _OnbData(
      icon: Icons.wb_sunny,
      title: 'תזכורת הבוקר',
      body:
          'כל בוקר תקבל סיכום של המשימות שמחכות לך ושבטיפולך. ניתן לשנות את השעה בהגדרות.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon, size: 96, color: AppTheme.accent),
                        const SizedBox(height: 32),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                                height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _page == i ? AppTheme.accent : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('דלג',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_page == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                        _page == _pages.length - 1 ? 'בוא נתחיל' : 'הבא'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await context.read<AppState>().markOnboardingDone();
    widget.onDone();
  }
}

class _OnbData {
  final IconData icon;
  final String title;
  final String body;
  const _OnbData({required this.icon, required this.title, required this.body});
}
