import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Chỉ số của tab được chọn

  // Thanh tìm kiếm
  Widget _nav() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        decoration: InputDecoration(
          label: const Text('Tìm kiếm'),
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
          hintText: 'Tìm kiếm...',
          hintStyle: const TextStyle(color: Colors.black54),
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Danh sách người dùng online
  Widget usersOnline() {
    final List<Map<String, dynamic>> onlineUsers = [
      {'name': 'Reus', 'avatar': 'https://thethaovanhoa.mediacdn.vn/thumb_w/650/372676912336973824/2024/5/31/dortmunds-german-forward-marco-reus-904311830-1717128711631634061682.jpg', 'isOnline': true},
      {'name': 'Beckham', 'avatar': 'https://iv1cdn.vnecdn.net/giaitri/images/web/2022/07/27/david-beckham-tap-luyen-giu-dang-1658895037.jpg?w=460&h=0&q=100&dpr=2&fit=crop&s=zjFL8LohqoklUTAYfA4xhw', 'isOnline': true},
      {'name': 'Ronaldo', 'avatar': 'https://b.fssta.com/uploads/application/soccer/headshots/885.vresize.350.350.medium.19.png', 'isOnline': false},
      {'name': 'Neymar', 'avatar': 'https://b.fssta.com/uploads/application/soccer/headshots/713.vresize.350.350.medium.34.png', 'isOnline': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: onlineUsers.length,
            itemBuilder: (context, index) {
              final user = onlineUsers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(user['avatar']),
                        ),
                        if (user['isOnline'])
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      user['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Danh sách các cuộc chat
  Widget chatList() {
    final List<Map<String, dynamic>> chats = [
      {'name': 'Reus', 'avatar': 'https://thethaovanhoa.mediacdn.vn/thumb_w/650/372676912336973824/2024/5/31/dortmunds-german-forward-marco-reus-904311830-1717128711631634061682.jpg', 'message': 'Hey, bạn khỏe không?', 'time': '10:30', 'unread': 2},
      {'name': 'Beckham', 'avatar': 'https://iv1cdn.vnecdn.net/giaitri/images/web/2022/07/27/david-beckham-tap-luyen-giu-dang-1658895037.jpg?w=460&h=0&q=100&dpr=2&fit=crop&s=zjFL8LohqoklUTAYfA4xhw', 'message': 'Hello bạn!', 'time': '09:15', 'unread': 0},
      {'name': 'Ronaldo', 'avatar': 'https://b.fssta.com/uploads/application/soccer/headshots/885.vresize.350.350.medium.19.png', 'message': 'Đá bóng chiều nay nhé!', 'time': 'Yesterday', 'unread': 1},
      {'name': 'Neymar', 'avatar': 'https://b.fssta.com/uploads/application/soccer/headshots/713.vresize.350.350.medium.34.png', 'message': 'Chào bạn!', 'time': 'Monday', 'unread': 0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(chat['avatar']), // Sử dụng avatar từ dữ liệu
              ),
              title: Text(
                chat['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(chat['message']),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chat['time'],
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  if (chat['unread'] > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4.0),
                      padding: const EdgeInsets.all(6.0),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat['unread'].toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () {}, 
            );
          },
        ),
      ],
    );
  }

  // Hàm xử lý khi chuyển tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.withOpacity(0.1), // Màu nền đồng nhất
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _nav(),
              usersOnline(),
              chatList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
