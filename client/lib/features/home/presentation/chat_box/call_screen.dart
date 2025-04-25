import 'package:first_app/data/providers/CallProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatelessWidget {
  final int userId;
  final int conversationId;

  const CallScreen({
    Key? key,
    required this.userId,
    required this.conversationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuộc gọi nhóm'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Consumer<CallProvider>(
          builder: (context, callProvider, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  callProvider.isCalling
                      ? 'Đang gọi ${callProvider.callerName ?? "nhóm"}...'
                      : 'Cuộc gọi đã kết thúc',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    callProvider.endCall();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Kết thúc cuộc gọi'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}