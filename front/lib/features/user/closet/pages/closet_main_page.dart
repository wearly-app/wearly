import 'package:flutter/material.dart';
import 'package:front/features/user/closet/widgets/add_item_sheets.dart';
import 'package:front/features/user/closet/pages/closet_home_page.dart';
import 'package:front/features/user/closet/pages/codi_calendar_page.dart';
import 'package:front/services/location_service.dart';

class ClosetMainPage extends StatefulWidget {
  const ClosetMainPage({super.key});

  @override
  State<ClosetMainPage> createState() => _ClosetMainPageState();
}

class _ClosetMainPageState extends State<ClosetMainPage> {
  int _currentIndex = 0;
  final LocationService _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    _prepareLocation();
  }

  Future<void> _prepareLocation() async {
    await _locationService.getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ClosetHomePage(),
      const CodiCalendarPage(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, '홈'),
              const Expanded(child: SizedBox()),
              _navItem(1, Icons.calendar_month_outlined, Icons.calendar_month, '캘린더'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData active, String label) {
    final sel = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sel ? active : icon,
                size: 24,
                color: sel ? const Color(0xFF1A1A1A) : Colors.grey.shade400),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  color: sel ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddItemSourceSheet(onAdded: () {}),
    );
  }
}
