import 'package:flutter/services.dart';

class AudioHapticService {
  static void triggerEmergencyAlert() {
    // Medium-heavy haptic alert on physical device
    HapticFeedback.heavyImpact();
    // System sound alert fallback
    SystemSound.play(SystemSoundType.alert);
  }

  static void triggerClick() {
    HapticFeedback.selectionClick();
  }

  static void triggerSuccess() {
    HapticFeedback.mediumImpact();
  }

  static void triggerWarning() {
    HapticFeedback.vibrate();
  }
}
