import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../models/signal_type.dart';

class AudioOutputService extends ChangeNotifier {
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  bool _isPlaying = false;
  
  bool get isPlaying => _isPlaying;

  // Generate WAV file header
  Uint8List _createWavHeader(int dataSize, int sampleRate) {
    final header = ByteData(44);
    
    // "RIFF" chunk descriptor
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little);
    
    // "WAVE" format
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    
    // "fmt " sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // Sub-chunk size
    header.setUint16(20, 1, Endian.little);  // Audio format (PCM)
    header.setUint16(22, 1, Endian.little);  // Number of channels (mono)
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    header.setUint16(32, 2, Endian.little);  // Block align
    header.setUint16(34, 16, Endian.little); // Bits per sample
    
    // "data" sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);
    
    return header.buffer.asUint8List();
  }

  // Generate audio samples for given frequency and signal type
  Uint8List _generateAudioSamples(
    SignalType signalType,
    double frequency,
    double amplitude,
  ) {
    const int sampleRate = 44100;
    const int duration = 1;
    final int totalSamples = sampleRate * duration;
    
    final int16Samples = Int16List(totalSamples);
    
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final angle = 2 * pi * frequency * t;
      
      double value;
      switch (signalType) {
        case SignalType.sine:
          value = sin(angle);
          break;
        case SignalType.square:
          value = sin(angle) > 0 ? 1.0 : -1.0;
          break;
        case SignalType.triangle:
          value = (2 / pi) * asin(sin(angle));
          break;
        case SignalType.sawtooth:
          value = 2 * (angle / (2 * pi) - ((angle / (2 * pi) + 0.5).floor()));
          break;
      }
      
      // Apply amplitude and convert to 16-bit PCM
      int16Samples[i] = (value * amplitude * 16384).clamp(-32768, 32767).round();
    }
    
    // Create WAV file
    final audioData = int16Samples.buffer.asUint8List();
    final header = _createWavHeader(audioData.length, sampleRate);
    
    // Combine header and data
    final wavFile = Uint8List(header.length + audioData.length);
    wavFile.setRange(0, header.length, header);
    wavFile.setRange(header.length, wavFile.length, audioData);
    
    return wavFile;
  }

  Future<void> playTone(
    SignalType signalType,
    double frequency,
    double amplitude,
  ) async {
    try {
      final clampedFreq = frequency.clamp(20.0, 20000.0);
      
      if (_isPlaying) {
        await stop();
      }

      // Generate WAV audio data
      final wavData = _generateAudioSamples(
        signalType,
        clampedFreq,
        amplitude / 5.0,
      );

      // Create audio source from bytes
      await _audioPlayer.setAudioSource(
        ja.AudioSource.uri(
          Uri.dataFromBytes(wavData, mimeType: 'audio/wav'),
        ),
      );
      
      // Set to loop
      await _audioPlayer.setLoopMode(ja.LoopMode.one);
      
      // Set volume
      await _audioPlayer.setVolume(amplitude / 5.0);
      
      // Play
      await _audioPlayer.play();
      
      _isPlaying = true;
      notifyListeners();
      
      debugPrint('Playing tone: ${clampedFreq}Hz, Type: $signalType');
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      notifyListeners();
      debugPrint('Audio stopped');
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> updateFrequency(
    SignalType signalType,
    double frequency,
    double amplitude,
  ) async {
    if (_isPlaying) {
      await playTone(signalType, frequency, amplitude);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
