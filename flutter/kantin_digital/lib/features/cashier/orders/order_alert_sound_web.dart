// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

class OrderAlertSound {
  html.AudioElement? _audio;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  Future<void> enableFromUserGesture() async {
    final audio = html.AudioElement()
      ..src = 'data:audio/wav;base64,${base64Encode(_createAlertWav())}'
      ..loop = true
      ..volume = 1;
    _audio?.pause();
    _audio = audio;

    await audio.play();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    audio.pause();
    audio.currentTime = 0;
    _isEnabled = true;
  }

  Future<void> play() async {
    if (!_isEnabled || _audio == null) return;
    _audio!.currentTime = 0;
    await _audio!.play();
  }

  void stop() {
    _audio?.pause();
    if (_audio != null) _audio!.currentTime = 0;
  }

  void disable() {
    stop();
    _isEnabled = false;
  }

  void dispose() {
    disable();
    _audio?.src = '';
    _audio = null;
  }

  Uint8List _createAlertWav() {
    const sampleRate = 22050;
    const durationSeconds = 1.6;
    const pulseSeconds = 0.15;
    const gapSeconds = 0.08;
    const pulseCount = 5;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);
    final pulseSamples = (sampleRate * pulseSeconds).round();
    final pulseStride = (sampleRate * (pulseSeconds + gapSeconds)).round();

    for (var i = 0; i < sampleCount; i++) {
      final pulsePosition = i % pulseStride;
      var sample = 0.0;
      if (i ~/ pulseStride < pulseCount && pulsePosition < pulseSamples) {
        final envelope = math.min(
          1.0,
          math.min(pulsePosition / 180, (pulseSamples - pulsePosition) / 280),
        );
        final frequency = (i ~/ pulseStride).isEven ? 880.0 : 1174.0;
        sample =
            math.sin(2 * math.pi * frequency * pulsePosition / sampleRate) *
            envelope *
            0.92;
      }
      pcmBytes.setInt16(i * 2, (sample * 32767).round(), Endian.little);
    }

    final wav = ByteData(44 + pcmBytes.lengthInBytes);
    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        wav.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    wav.setUint32(4, 36 + pcmBytes.lengthInBytes, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    wav.setUint32(16, 16, Endian.little);
    wav.setUint16(20, 1, Endian.little);
    wav.setUint16(22, 1, Endian.little);
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * 2, Endian.little);
    wav.setUint16(32, 2, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    wav.setUint32(40, pcmBytes.lengthInBytes, Endian.little);
    for (var i = 0; i < pcmBytes.lengthInBytes; i++) {
      wav.setUint8(44 + i, pcmBytes.getUint8(i));
    }
    return wav.buffer.asUint8List();
  }
}
