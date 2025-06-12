import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:first_app/data/providers/CallProvider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Animation cho fade-in thông tin và nút
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        print('CallScreen build: isCalling=${callProvider.isCalling}, '
            'localRenderer=${callProvider.localRenderer != null}, '
            'remoteRenderer=${callProvider.remoteRenderer != null}');

        // Trạng thái khi không có cuộc gọi
        if (!callProvider.isCalling ||
            callProvider.localRenderer == null ||
            callProvider.remoteRenderer == null) {
          return Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang kết nối...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // Remote video
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: RTCVideoView(
                    callProvider.remoteRenderer!,
                    mirror: false,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
              // Local video
              Positioned(
                bottom: 20,
                right: 20,
                width: 120,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      callProvider.localRenderer!,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
              // Call info
              AnimatedOpacity(
                opacity: _fadeAnimation.value,
                duration: const Duration(milliseconds: 500),
                child: Positioned(
                  top: 40,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cuộc gọi với ${callProvider.callerName ?? "Unknown"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black87,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // End call button
              AnimatedOpacity(
                opacity: _fadeAnimation.value,
                duration: const Duration(milliseconds: 500),
                child: Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 1.0, end: 1.0),
                      duration: const Duration(milliseconds: 100),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          // child: FloatingActionButton(
                          //   backgroundColor: Colors.red,
                          //   onPressed: () {
                          //     print('End call button pressed');
                          //     callProvider.endCall();
                          //   },
                          //   // child: const Icon(
                          //   //   Icons.call_end,
                          //   //   size: 32,
                          //   //   color: Colors.white,
                          //   // ),
                          //   elevation: 6,
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.circular(16),
                          //   ),
                          // ),
                        );
                      },
                    ),
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