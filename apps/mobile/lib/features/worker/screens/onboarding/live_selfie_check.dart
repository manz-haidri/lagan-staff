import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/localization/app_language.dart';

enum SelfiePose { neutral, eyesClosed, smile }

bool matchesSelfiePose(SelfiePose pose, Face face) {
  final yaw = face.headEulerAngleY;
  final left = face.leftEyeOpenProbability;
  final right = face.rightEyeOpenProbability;
  final smile = face.smilingProbability;
  if (yaw == null ||
      yaw.abs() > 18 ||
      left == null ||
      right == null ||
      smile == null) {
    return false;
  }
  return switch (pose) {
    SelfiePose.neutral => left > .65 && right > .65 && smile < .40,
    SelfiePose.eyesClosed => left < .30 && right < .30,
    SelfiePose.smile => left > .55 && right > .55 && smile > .80,
  };
}

class LiveSelfieCheck extends StatefulWidget {
  const LiveSelfieCheck({super.key, required this.language});
  final AppLanguage language;

  @override
  State<LiveSelfieCheck> createState() => _LiveSelfieCheckState();
}

class _LiveSelfieCheckState extends State<LiveSelfieCheck>
    with WidgetsBindingObserver {
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  late final _poses = [
    SelfiePose.neutral,
    ...([SelfiePose.eyesClosed, SelfiePose.smile]..shuffle(Random.secure())),
    SelfiePose.neutral,
  ];
  CameraController? _camera;
  int _step = 0;
  String? _error;
  bool _stopped = false;

  String words(String en, String hi, String hinglish) =>
      switch (widget.language) {
        AppLanguage.english => en,
        AppLanguage.hindi => hi,
        AppLanguage.hinglish => hinglish,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _run();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      }
      _stopped = true;
    }
  }

  @override
  void dispose() {
    _stopped = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _run() async {
    CameraController? camera;
    try {
      final cameras = await availableCameras();
      if (_stopped || !mounted) return;
      final front = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (front.isEmpty) throw StateError('Front camera unavailable');
      camera = CameraController(
        front.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await camera.initialize();
      if (_stopped || !mounted) return;
      setState(() => _camera = camera);
      final timer = Stopwatch()..start();
      int? lastId;
      Rect? lastBox;
      int consecutive = 0;
      while (mounted &&
          !_stopped &&
          timer.elapsed < const Duration(seconds: 55)) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted || _stopped) return;
        final shot = await camera.takePicture();
        final file = File(shot.path);
        try {
          final faces = await _detector.processImage(InputImage.fromFile(file));
          if (!mounted || _stopped) return;
          final face = faces.length == 1 ? faces.single : null;
          final switched =
              face != null &&
              lastBox != null &&
              ((!lastBox.overlaps(face.boundingBox)) ||
                  (lastId != null &&
                      face.trackingId != null &&
                      lastId != face.trackingId));
          lastBox = face?.boundingBox;
          lastId = face?.trackingId;
          if (face == null || switched) {
            consecutive = 0;
            if (_step != 0) setState(() => _step = 0);
            continue;
          }
          consecutive = matchesSelfiePose(_poses[_step], face)
              ? consecutive + 1
              : 0;
          if (consecutive < 2) continue;
          consecutive = 0;
          if (_step == _poses.length - 1) {
            final bytes = await file.readAsBytes();
            if (mounted && !_stopped) Navigator.of(context).pop(bytes);
            return;
          }
          setState(() => _step++);
        } finally {
          if (await file.exists()) await file.delete();
        }
      }
      if (mounted && !_stopped) {
        setState(
          () => _error = words(
            'Live check timed out. Try again in good light with only your face in view.',
            'समय समाप्त। अच्छी रोशनी में सिर्फ अपना चेहरा दिखाकर फिर कोशिश करें।',
            'Time khatam. Achhi light mein sirf apna chehra dikhakar phir try karein.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Live selfie camera: $e');
      if (mounted && !_stopped) {
        setState(
          () => _error = words(
            'Could not complete the camera check. Allow camera access and try again.',
            'कैमरा जाँच पूरी नहीं हुई। कैमरे की अनुमति देकर फिर कोशिश करें।',
            'Camera check poora nahi hua. Camera permission dekar phir try karein.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _camera = null);
      await camera?.dispose();
      await _detector.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = switch (_poses[_step]) {
      SelfiePose.neutral => words(
        'Look straight ahead. Open your eyes and relax your smile.',
        'सामने देखें। आँखें खुली रखें और मुस्कुराना बंद करें।',
        'Seedha dekhein. Aankhen khuli rakhein aur chehra normal rakhein.',
      ),
      SelfiePose.eyesClosed => words(
        'Close both eyes and hold briefly.',
        'दोनों आँखें थोड़ी देर बंद रखें।',
        'Dono aankhen thodi der band rakhein.',
      ),
      SelfiePose.smile => words(
        'Smile and hold your smile.',
        'मुस्कुराएँ और थोड़ी देर ऐसे ही रहें।',
        'Muskuraayein aur thodi der hold karein.',
      ),
    };
    final camera = _camera;
    return Scaffold(
      appBar: AppBar(
        title: Text(words('Live selfie', 'लाइव सेल्फी', 'Live selfie')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: camera == null
                    ? (_error == null
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.no_photography_outlined, size: 54))
                    : CameraPreview(camera),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                _error ?? '${_step + 1}/${_poses.length}  $prompt',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_error != null)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(words('Back', 'वापस', 'Wapas')),
              ),
          ],
        ),
      ),
    );
  }
}
