import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_community_management_screen.dart';
import 'admin_report_management_screen.dart';
import 'admin_inquiry_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUserManagementScreen(),
    const AdminCommunityManagementScreen(),
    const AdminReportManagementScreen(),
    const AdminInquiryManagementScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1A237E), // Dark Navy
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '대시보드'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '사용자 관리'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: '커뮤니티 관리'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: '신고 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '1:1 문의',
          ),
        ],
      ),
    );
  }
}
