import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/authentication/widgets/breathing_camera_button.dart';
import 'package:jisu_calendar/features/camera/screens/camera_screen.dart';
import 'package:jisu_calendar/features/home/screens/home_screen.dart';
import 'package:jisu_calendar/features/plaza/plaza_screen.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlazaScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: Hero(
        tag: 'camera_button_hero',
        flightShuttleBuilder: (flightContext, animation, flightDirection,
            fromHeroContext, toHeroContext) {
          return BreathingCameraButton(
            onPressed: () {},
            animate: false,
          );
        },
        child: BreathingCameraButton(
          onPressed: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 800),
              reverseTransitionDuration: const Duration(milliseconds: 800),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CameraScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ));
          },
          animate: true,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(icon: Icons.calendar_month, index: 0),
              const SizedBox(width: 48), // The space for the notch
              _buildNavItem(icon: Icons.dashboard_outlined, index: 1),
            ],
          ),
        ),
      ),
    );
  }

  // Use Transform.translate for a precise pixel shift
  Widget _buildNavItem({required IconData icon, required int index}) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return Transform.translate(
      offset: const Offset(0, -4), // Shift up by 2 pixels
      child: IconButton(
        onPressed: () => _onItemTapped(index),
        icon: Icon(icon, color: color, size: 28),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    );
  }
}
