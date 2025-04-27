import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:first_app/data/providers/CallProvider.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        print('CallScreen build: isCalling=${callProvider.isCalling}, '
            'localRenderer=${callProvider.localRenderer != null}, '
            'remoteRenderer=${callProvider.remoteRenderer != null}');
        if (!callProvider.isCalling ||
            callProvider.localRenderer == null ||
            callProvider.remoteRenderer == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Stack(
            children: [
              // Remote video
              Positioned.fill(
                child: RTCVideoView(
                  callProvider.remoteRenderer!,
                  mirror: false,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              // Local video (small corner)
              Positioned(
                bottom: 20,
                right: 20,
                width: 120,
                height: 160,
                child: RTCVideoView(
                  callProvider.localRenderer!,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              // End call button
              Positioned(
                top: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () {
                    print('End call button pressed');
                    callProvider.endCall();
                  },
                  child: const Icon(Icons.call_end),
                ),
              ),
              // Call info
              Positioned(
                top: 20,
                left: 20,
                child: Text(
                  'Cuộc gọi với ${callProvider.callerName ?? "Unknown"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}