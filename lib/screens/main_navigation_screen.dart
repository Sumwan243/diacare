import 'package:flutter/material.dart';
import '../widgets/medical_bottom_navigation.dart';
import 'home_screen.dart';
import 'reminders_screen.dart';
import 'ai_insights_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  AppTab _currentTab = AppTab.home;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(AppTab tab) {
    if (tab == _currentTab) return;
    
    setState(() {
      _currentTab = tab;
    });
    
    _pageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentTab = AppTab.values[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          HomeScreen(),
          RemindersScreen(),
          AIInsightsScreen(),
        ],
      ),
      bottomNavigationBar: MedicalBottomNavigation(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}