import 'dart:math';
import 'signal_type.dart';
import 'signal_parameters.dart';

class SignalGenerator {
  static const int samplesPerCycle = 360;
  
  /// Generate signal samples based on type and parameters
  static List<double> generateSamples(
    SignalType type,
    SignalParameters params, {
    int sampleCount = 360,
  }) {
    final samples = <double>[];
    final phaseRad = params.phase * pi / 180.0;
    
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleCount.toDouble();
      final angle = 2 * pi * t + phaseRad;
      
      double value;
      switch (type) {
        case SignalType.sine:
          value = _generateSine(angle);
          break;
        case SignalType.square:
          value = _generateSquare(angle);
          break;
        case SignalType.triangle:
          value = _generateTriangle(angle);
          break;
        case SignalType.sawtooth:
          value = _generateSawtooth(angle);
          break;
      }
      
      // Apply amplitude and offset
      value = value * params.amplitude + params.offset;
      samples.add(value);
    }
    
    return samples;
  }

  static double _generateSine(double angle) {
    return sin(angle);
  }

  static double _generateSquare(double angle) {
    final normalized = angle % (2 * pi);
    return normalized < pi ? 1.0 : -1.0;
  }

  static double _generateTriangle(double angle) {
    final normalized = (angle % (2 * pi)) / (2 * pi);
    if (normalized < 0.25) {
      return 4 * normalized;
    } else if (normalized < 0.75) {
      return 2 - 4 * normalized;
    } else {
      return -4 + 4 * normalized;
    }
  }

  static double _generateSawtooth(double angle) {
    final normalized = (angle % (2 * pi)) / (2 * pi);
    return 2 * normalized - 1;
  }

  /// Generate time-domain samples for real-time transmission
  static List<double> generateTimeSamples(
    SignalType type,
    SignalParameters params,
    int sampleRate,
    double duration,
  ) {
    final sampleCount = (sampleRate * duration).round();
    final samples = <double>[];
    final phaseRad = params.phase * pi / 180.0;
    
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate.toDouble();
      final angle = 2 * pi * params.frequency * t + phaseRad;
      
      double value;
      switch (type) {
        case SignalType.sine:
          value = _generateSine(angle);
          break;
        case SignalType.square:
          value = _generateSquare(angle);
          break;
        case SignalType.triangle:
          value = _generateTriangle(angle);
          break;
        case SignalType.sawtooth:
          value = _generateSawtooth(angle);
          break;
      }
      
      // Apply amplitude and offset
      value = value * params.amplitude + params.offset;
      samples.add(value);
    }
    
    return samples;
  }
}
