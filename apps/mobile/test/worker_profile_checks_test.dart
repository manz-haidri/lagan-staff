import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lagan_staff/features/worker/presentation/worker_onboarding_notifier.dart';
import 'package:lagan_staff/features/worker/screens/onboarding/live_selfie_check.dart';

void main() {
  test('five skills are valid and a sixth cannot be submitted', () {
    const five = WorkerOnboardingState(
      selectedSkillIds: {'1', '2', '3', '4', '5'},
    );
    expect(five.isStep2Valid, isTrue);
    expect(
      five
          .copyWith(selectedSkillIds: {...five.selectedSkillIds, '6'})
          .isStep2Valid,
      isFalse,
    );
  });

  test('a still neutral face cannot satisfy either live action', () {
    final face = Face(
      boundingBox: const Rect.fromLTWH(20, 20, 100, 100),
      landmarks: {},
      contours: {},
      headEulerAngleY: 0,
      leftEyeOpenProbability: .95,
      rightEyeOpenProbability: .95,
      smilingProbability: .05,
    );
    expect(matchesSelfiePose(SelfiePose.neutral, face), isTrue);
    expect(matchesSelfiePose(SelfiePose.eyesClosed, face), isFalse);
    expect(matchesSelfiePose(SelfiePose.smile, face), isFalse);
  });
}
