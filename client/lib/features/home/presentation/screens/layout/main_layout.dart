import 'package:first_app/features/home/presentation/friends/friends.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int currentUserId; // Thêm currentUserId để truyền vào Friends

  const MainLayout({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.currentUserId,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Friends(currentUserId: currentUserId),
        ),
      );
    } else {
      // Gọi hàm onItemTapped cho các tab khác
      onItemTapped(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'messenger',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              // Logic khi nhấn nút đóng (nếu cần)
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Đoạn chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Bạn bè',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) => _handleNavigation(context, index),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}