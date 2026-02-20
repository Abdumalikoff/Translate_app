import 'package:flutter/material.dart';
import 'translate/translate_screen.dart';
import 'translate/screens/favorites_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [TranslateScreen(), FavoritesScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (v) => setState(() => _index = v),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0024A5),
          unselectedItemColor: const Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.translate),
              label: 'Translate',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          ],
        ),
      ),
    );
  }
}
