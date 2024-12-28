import 'package:call_app_livekit/src/screens/home_screen.dart';
import 'package:call_app_livekit/src/screens/pp_screen.dart';
import 'package:flutter/material.dart';

class LandingHandler extends StatefulWidget {
  const LandingHandler({super.key});

  @override
  _LandingHandlerState createState() => _LandingHandlerState();
}

class _LandingHandlerState extends State<LandingHandler> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = const [HomeScreen(), PpScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'P2P',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
