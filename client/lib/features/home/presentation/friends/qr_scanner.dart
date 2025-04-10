import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/features/home/presentation/users_profile/other_us_profile.dart';
import 'bloc/friends_bloc.dart';
import 'bloc/friends_event.dart';
import 'bloc/friends_state.dart';
import 'package:first_app/data/dto/scanned_user.dart';

class NewQrScannerScreen extends StatefulWidget {
  final FriendsBloc friendsBloc;

  const NewQrScannerScreen({super.key, required this.friendsBloc});

  @override
  State<NewQrScannerScreen> createState() => _NewQrScannerScreenState();
}

class _NewQrScannerScreenState extends State<NewQrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;
  bool isFlashOn = false;
  String? scannedResult;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanned && scanData.code != null) {
        setState(() {
          isScanned = true;
          scannedResult = scanData.code;
        });
        await controller.pauseCamera();
        widget.friendsBloc.add(ScanQrCodeEvent(scanData.code!));
      }
    });
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    controller?.toggleFlash();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendsBloc, FriendsState>(
      bloc: widget.friendsBloc,
      listener: (context, state) {
        print('BlocListener State: $state');
        if (state is FriendsLoaded && state.scannedUser != null) {
          print('User found: ${state.scannedUser!.id}, ${state.scannedUser!.username}');
          // Navigate to OtherProfilePage and replace NewQrScannerScreen in the stack
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtherProfilePage(
                viewerId: widget.friendsBloc.currentUserId,
                targetUserId: state.scannedUser!.id,
              ),
            ),
          );
        } else if (state is FriendsError && isScanned) {
          print('Error state: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          setState(() {
            isScanned = false;
            scannedResult = null;
          });
          // Do not resume the camera automatically
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blueAccent,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Quét mã QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Đặt mã QR vào khung để quét',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isScanned)
                          const Text(
                            'Đang xử lý...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        if (!isScanned && scannedResult == null)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isScanned = false;
                                scannedResult = null;
                              });
                              controller?.resumeCamera();
                            },
                            child: const Text('Thử lại'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}