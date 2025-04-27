import 'package:first_app/data/repositories/WebRTCService/webRTCService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final WebRTCService webRTCService;

  const VideoCallScreen({Key? key, required this.webRTCService}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo WebRTC
    widget.webRTCService.init().then((_) {
      // Gọi createOffer nếu là người gọi
      // widget.webRTCService.createOffer().then((offer) {
      //   // Gửi offer qua WebSocket
      // });
      setState(() {}); // Cập nhật UI khi renderer sẵn sàng
    });
  }

  @override
  void dispose() {
    widget.webRTCService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: Stack(
        children: [
          // Remote video (chiếm toàn màn hình)
          Positioned.fill(
            child: RTCVideoView(
              widget.webRTCService.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          // Local video (góc nhỏ)
          Positioned(
            top: 20,
            right: 20,
            width: 100,
            height: 150,
            child: RTCVideoView(
              widget.webRTCService.localRenderer,
              mirror: true, // Lật video cục bộ
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          // Nút điều khiển (kết thúc cuộc gọi, v.v.)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.webRTCService.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('End Call'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}