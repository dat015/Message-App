import 'dart:typed_data';
import 'package:first_app/features/home/presentation/friends/bloc/friends_bloc.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_event.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_state.dart';
import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/features/home/presentation/friends/search_users.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int currentUserId;
  final String currentUserName;
  final String userAvatar;

  const MainLayout({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.currentUserId,
    required this.currentUserName,
    required this.userAvatar,
  });

  void _handleNavigation(BuildContext context, int index) {
    onItemTapped(index);
  }

  void _showQrCodeDialog(BuildContext context) {
    final friendsBloc = context.read<FriendsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<FriendsBloc, FriendsState>(
        bloc: friendsBloc,
        builder: (context, state) {
          if (state is FriendsLoaded && state.qrCodeData != null) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Mã QR của bạn', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Image.memory(Uint8List.fromList(state.qrCodeData!), width: 200, height: 200),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }
          return const AlertDialog(content: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundImage: userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
            child: userAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            backgroundColor: userAvatar.isEmpty ? Colors.blueAccent : null,
          ),
        ),
        title: Text(
          selectedIndex == 0
              ? 'Đoạn chat'
              : selectedIndex == 1
                  ? 'Bạn bè'
                  : selectedIndex == 2
                      ? 'Bảng tin'
                      : selectedIndex == 3
                          ? 'Thông báo'
                          : 'Cá nhân',
          style: const TextStyle(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blueAccent),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(
                  currentUserId: currentUserId,
                  friendsBloc: context.read<FriendsBloc>(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.blueAccent),
            onPressed: () {
              context.read<FriendsBloc>().add(GenerateUserQrCodeEvent());
              _showQrCodeDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
            onPressed: () {
              NavigationHelper().goToQrScanner(context, context.read<FriendsBloc>());
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5)],
        ),
        margin: const EdgeInsets.only(top: 4),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: body,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Đoạn chat'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Bạn bè'),
            BottomNavigationBarItem(icon: Icon(Icons.post_add_outlined), activeIcon: Icon(Icons.post_add), label: 'Bảng tin'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: 'Thông báo'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cá nhân'),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          onTap: (index) => _handleNavigation(context, index),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
          elevation: 0,
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final int currentUserId;
  final FriendsBloc friendsBloc;

  CustomSearchDelegate({required this.currentUserId, required this.friendsBloc});

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            friendsBloc.add(ResetSearchEvent());
          },
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          friendsBloc.add(ResetSearchEvent());
          close(context, '');
        },
      );

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      friendsBloc.add(SearchUsersEvent(query));
    }
    return BlocListener<FriendsBloc, FriendsState>(
      bloc: friendsBloc,
      listener: (context, state) {
        if (state is FriendsSearchSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchUsersScreen(
                searchResults: state.searchResults,
                currentUserId: currentUserId,
                friendsBloc: friendsBloc, // Truyền friendsBloc
              ),
            ),
          );
        } else if (state is FriendsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container();
}