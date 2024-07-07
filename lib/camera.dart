import 'dart:async';
import 'dart:io' as io; // Use 'io' as an alias to avoid name conflicts
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  XFile? currentImage;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  bool isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller?.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    }
  }

  Future<void> captureImage() async {
    setState(() {
      isTimerRunning = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (controller != null && controller!.value.isInitialized) {
      final XFile image = await controller!.takePicture();
      setState(() {
        currentImage = image;
        isTimerRunning = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Yoga'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: isCameraInitialized
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentImage == null)
                SizedBox(
                  width: MediaQuery.of(context).size.width, // Set the width to screen width
                  height: MediaQuery.of(context).size.height * 0.6, // Set a suitable height
                  child: AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: CameraPreview(controller!),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: kIsWeb
                      ? Image.network(currentImage!.path)
                      : SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.file(io.File(currentImage!.path)),
                  ),
                ),
              const SizedBox(height: 20),
              if (!isTimerRunning && currentImage == null)
                ElevatedButton(
                  onPressed: captureImage,
                  child: const Text('Open Camera'),
                ),
              if (isTimerRunning)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Capturing in 3 seconds...'),
                ),
              if (currentImage != null)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentImage = null;
                      isCameraInitialized = false;
                    });
                    initializeCamera();
                  },
                  child: const Text('Retake'),
                ),
            ],
          )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
