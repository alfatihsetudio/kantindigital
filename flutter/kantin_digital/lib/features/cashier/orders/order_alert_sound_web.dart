// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

class OrderAlertSound {
  html.AudioElement? _audio;
  html.AudioElement? _previewAudio;
  bool _isEnabled = false;
  String _soundType = 'dingdong';

  bool get isEnabled => _isEnabled;
  String get soundType => _soundType;

  void setSoundType(String type) {
    if (_soundType == type && _audio != null) return;
    _soundType = type;
    if (_isEnabled && _audio != null) {
      final wasPlaying = !_audio!.paused;
      _audio?.pause();
      _audio?.src = _getAudioSrc(type);
      if (wasPlaying) {
        _audio?.play();
      }
    }
  }

  String _getAudioSrc(String type) {
    return 'data:audio/wav;base64,${base64Encode(_createAlertWav(type))}';
  }

  Future<void> enableFromUserGesture({String? soundType}) async {
    if (soundType != null && soundType.trim().isNotEmpty) {
      _soundType = soundType.trim();
    }
    final audio = html.AudioElement()
      ..src = _getAudioSrc(_soundType)
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

  Future<void> play({String? soundType}) async {
    if (soundType != null && soundType.trim().isNotEmpty && soundType != _soundType) {
      setSoundType(soundType);
    }
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

  /// Memainkan preview satu kali (one-shot) untuk tes nada suara
  Future<void> preview(String type) async {
    stopPreview();
    final audio = html.AudioElement()
      ..src = _getAudioSrc(type)
      ..loop = false
      ..volume = 1;
    _previewAudio = audio;
    await audio.play();
  }

  void stopPreview() {
    _previewAudio?.pause();
    if (_previewAudio != null) {
      _previewAudio!.currentTime = 0;
      _previewAudio?.src = '';
    }
    _previewAudio = null;
  }

  void dispose() {
    disable();
    stopPreview();
    _audio?.src = '';
    _audio = null;
  }

  Uint8List _createAlertWav(String type) {
    const sampleRate = 22050;
    final normalizedType = type.trim().toLowerCase();

    switch (normalizedType) {
      case 'chime':
        return _createChimeWav(sampleRate);
      case 'marimba':
        return _createMarimbaWav(sampleRate);
      case 'bell':
        return _createBellWav(sampleRate);
      case 'gentle':
        return _createGentleWav(sampleRate);
      case 'urgent':
        return _createUrgentWav(sampleRate);
      case 'beep':
        return _createDigitalBeepWav(sampleRate);
      case 'dingdong':
      default:
        return _createDingDongWav(sampleRate);
    }
  }

  /// Preset 1: Ding Dong Kasir (Dua dentang lonceng khas kasir / minimarket)
  Uint8List _createDingDongWav(int sampleRate) {
    const durationSeconds = 1.6;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);

    const dingFreq = 659.25; // E5
    const dongFreq = 523.25; // C5
    final dongStartSample = (sampleRate * 0.42).round();

    for (var i = 0; i < sampleCount; i++) {
      var sample = 0.0;
      if (i < dongStartSample) {
        // Nada "Ding"
        final t = i / sampleRate;
        final envelope = math.exp(-4.2 * t);
        final fundamental = math.sin(2 * math.pi * dingFreq * t);
        final harmonic = 0.28 * math.sin(2 * math.pi * (dingFreq * 2) * t);
        sample = (fundamental + harmonic) * envelope * 0.9;
      } else {
        // Nada "Dong"
        final t = (i - dongStartSample) / sampleRate;
        final envelope = math.exp(-2.8 * t);
        final fundamental = math.sin(2 * math.pi * dongFreq * t);
        final harmonic = 0.25 * math.sin(2 * math.pi * (dongFreq * 2) * t);
        sample = (fundamental + harmonic) * envelope * 0.92;
      }
      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Preset 2: Chime Melodi (3 nada arpeggio naik yang hangat & ramah)
  Uint8List _createChimeWav(int sampleRate) {
    const durationSeconds = 1.6;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);

    final n2Start = (sampleRate * 0.20).round();
    final n3Start = (sampleRate * 0.40).round();

    const f1 = 523.25; // C5
    const f2 = 659.25; // E5
    const f3 = 783.99; // G5
    const f4 = 1046.50; // C6

    for (var i = 0; i < sampleCount; i++) {
      var sample = 0.0;
      if (i >= n3Start) {
        final t = (i - n3Start) / sampleRate;
        final env = math.exp(-3.2 * t);
        final s3 = math.sin(2 * math.pi * f3 * t);
        final s4 = 0.4 * math.sin(2 * math.pi * f4 * t);
        sample = (s3 + s4) * env * 0.88;
      } else if (i >= n2Start) {
        final t = (i - n2Start) / sampleRate;
        final env = math.exp(-4.5 * t);
        sample = math.sin(2 * math.pi * f2 * t) * env * 0.85;
      } else {
        final t = i / sampleRate;
        final env = math.exp(-5.0 * t);
        sample = math.sin(2 * math.pi * f1 * t) * env * 0.85;
      }
      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Preset 3: Marimba Ceria (4 nada perkusif bilah kayu bernada ceria)
  Uint8List _createMarimbaWav(int sampleRate) {
    const durationSeconds = 1.3;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);

    final stepSamples = (sampleRate * 0.12).round();
    final freqs = [784.0, 987.77, 1174.66, 1567.98]; // G5, B5, D6, G6

    for (var i = 0; i < sampleCount; i++) {
      final noteIndex = math.min(i ~/ stepSamples, 3);
      final localSample = i - (noteIndex * stepSamples);
      final t = localSample / sampleRate;
      final freq = freqs[noteIndex];

      final decayRate = (noteIndex == 3) ? 4.5 : 8.5;
      final env = math.exp(-decayRate * t);
      // Karakter marimba: fundamental kuat + overtone ke-3 ringan
      final fundamental = math.sin(2 * math.pi * freq * t);
      final overtone = 0.18 * math.sin(2 * math.pi * (freq * 3) * t);
      final sample = (fundamental + overtone) * env * 0.90;

      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Preset 4: Lonceng Resto (Dentang ganda meja counter logam jernih)
  Uint8List _createBellWav(int sampleRate) {
    const durationSeconds = 1.5;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);

    const f = 1046.50; // C6
    final secondStrike = (sampleRate * 0.28).round();

    for (var i = 0; i < sampleCount; i++) {
      var sample = 0.0;
      if (i >= secondStrike) {
        final t = (i - secondStrike) / sampleRate;
        final env = math.exp(-2.6 * t);
        final s1 = math.sin(2 * math.pi * f * t);
        final s2 = 0.35 * math.sin(2 * math.pi * (f * 2.4) * t);
        sample = (s1 + s2) * env * 0.88;
      } else {
        final t = i / sampleRate;
        final env = math.exp(-4.0 * t);
        final s1 = math.sin(2 * math.pi * f * t);
        final s2 = 0.35 * math.sin(2 * math.pi * (f * 2.4) * t);
        sample = (s1 + s2) * env * 0.85;
      }
      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Preset 5: Beep Digital Klasik (Pola 5 pulsa pulsa frekuensi tinggi standar)
  Uint8List _createDigitalBeepWav(int sampleRate) {
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
      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Preset 6: Nada Lembut (Dua nada lembut tenang cocok untuk kafe santai)
  Uint8List _createGentleWav(int sampleRate) {
    const durationSeconds = 1.6;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);

    const f1 = 698.46; // F5
    const f2 = 880.00; // A5
    final secondNote = (sampleRate * 0.35).round();

    for (var i = 0; i < sampleCount; i++) {
      var sample = 0.0;
      if (i >= secondNote) {
        final t = (i - secondNote) / sampleRate;
        final attack = math.min(1.0, t * 40.0);
        final env = attack * math.exp(-2.4 * t);
        sample = math.sin(2 * math.pi * f2 * t) * env * 0.85;
      } else {
        final t = i / sampleRate;
        final attack = math.min(1.0, t * 40.0);
        final env = attack * math.exp(-3.5 * t);
        sample = math.sin(2 * math.pi * f1 * t) * env * 0.80;
      }
      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Preset 7: Alarm Siaga (Sirene pulsa tegas untuk area dapur/kasir ramai)
  Uint8List _createUrgentWav(int sampleRate) {
    const durationSeconds = 1.4;
    const pulseCount = 6;
    final sampleCount = (sampleRate * durationSeconds).round();
    final pcmBytes = ByteData(sampleCount * 2);
    final pulseDuration = (sampleRate * 0.14).round();
    final gapDuration = (sampleRate * 0.04).round();
    final stride = pulseDuration + gapDuration;

    for (var i = 0; i < sampleCount; i++) {
      final pulseIndex = i ~/ stride;
      final pos = i % stride;
      var sample = 0.0;
      if (pulseIndex < pulseCount && pos < pulseDuration) {
        final t = pos / sampleRate;
        final freq = pulseIndex.isEven ? 1174.66 : 1567.98;
        final attack = math.min(1.0, pos / 80.0);
        final release = math.min(1.0, (pulseDuration - pos) / 100.0);
        final env = attack * release;
        sample = math.sin(2 * math.pi * freq * t) * env * 0.95;
      }
      pcmBytes.setInt16(
        i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }

    return _wrapPcmToWav(pcmBytes, sampleRate);
  }

  /// Membungkus PCM 16-bit Mono ke format file WAV
  Uint8List _wrapPcmToWav(ByteData pcmBytes, int sampleRate) {
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
    wav.setUint32(16, 16, Endian.little); // Chunk size
    wav.setUint16(20, 1, Endian.little); // Format: PCM
    wav.setUint16(22, 1, Endian.little); // Channels: Mono (1)
    wav.setUint32(24, sampleRate, Endian.little); // Sample rate
    wav.setUint32(28, sampleRate * 2, Endian.little); // Byte rate (SampleRate * 1 channel * 2 bytes)
    wav.setUint16(32, 2, Endian.little); // Block align (1 channel * 2 bytes)
    wav.setUint16(34, 16, Endian.little); // Bits per sample: 16
    writeAscii(36, 'data');
    wav.setUint32(40, pcmBytes.lengthInBytes, Endian.little);
    for (var i = 0; i < pcmBytes.lengthInBytes; i++) {
      wav.setUint8(44 + i, pcmBytes.getUint8(i));
    }
    return wav.buffer.asUint8List();
  }
}
