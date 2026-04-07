import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Generates mechanical robot sound effects as WAV files at runtime.
/// No external assets needed — pure math synthesis.
class SoundGenerator {
  static Future<String> generateServoSound() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/servo_sound.wav');
    if (await file.exists()) return file.path;

    // Generate a short mechanical servo whirr (0.4 seconds)
    const sampleRate = 44100;
    const duration = 0.4;
    const numSamples = (sampleRate * duration) ~/ 1;
    final samples = Int16List(numSamples);
    final rng = Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Servo motor whine — rising frequency sweep
      final freq = 200 + 800 * (t / duration);
      final motor = sin(2 * pi * freq * t) * 0.3;
      // Gear clicking
      final clickRate = 60.0;
      final click = ((t * clickRate) % 1.0 < 0.05) ? 0.5 : 0.0;
      // Mechanical noise
      final noise = (rng.nextDouble() - 0.5) * 0.15;
      // Envelope: quick attack, sustain, quick release
      double env = 1.0;
      if (t < 0.02) env = t / 0.02;
      if (t > duration - 0.05) env = (duration - t) / 0.05;

      final sample = ((motor + click + noise) * env * 32767).clamp(-32767, 32767).toInt();
      samples[i] = sample;
    }

    final wavBytes = _encodeWav(samples, sampleRate);
    await file.writeAsBytes(wavBytes);
    return file.path;
  }

  static Future<String> generateClampSound() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/clamp_sound.wav');
    if (await file.exists()) return file.path;

    const sampleRate = 44100;
    const duration = 0.2;
    const numSamples = (sampleRate * duration) ~/ 1;
    final samples = Int16List(numSamples);
    final rng = Random(99);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Sharp metallic clank
      final impact = sin(2 * pi * 1200 * t) * exp(-t * 30) * 0.7;
      // Rattle
      final rattle = sin(2 * pi * 3500 * t) * exp(-t * 50) * 0.3;
      // Noise burst
      final noise = (rng.nextDouble() - 0.5) * exp(-t * 20) * 0.4;

      final sample = ((impact + rattle + noise) * 32767).clamp(-32767, 32767).toInt();
      samples[i] = sample;
    }

    final wavBytes = _encodeWav(samples, sampleRate);
    await file.writeAsBytes(wavBytes);
    return file.path;
  }

  static Future<String> generatePlaceSound() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/place_sound.wav');
    if (await file.exists()) return file.path;

    const sampleRate = 44100;
    const duration = 0.35;
    const numSamples = (sampleRate * duration) ~/ 1;
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Heavy thud
      final thud = sin(2 * pi * 80 * t) * exp(-t * 12) * 0.6;
      // Metal ring
      final ring = sin(2 * pi * 2000 * t) * exp(-t * 25) * 0.25;
      // Confirmation ping
      final ping = sin(2 * pi * 800 * t) * exp(-t * 8) * 0.3;

      final sample = ((thud + ring + ping) * 32767).clamp(-32767, 32767).toInt();
      samples[i] = sample;
    }

    final wavBytes = _encodeWav(samples, sampleRate);
    await file.writeAsBytes(wavBytes);
    return file.path;
  }

  static Uint8List _encodeWav(Int16List samples, int sampleRate) {
    final byteData = ByteData(44 + samples.length * 2);
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = samples.length * 2;

    // RIFF header
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, 36 + dataSize, Endian.little);
    byteData.setUint8(8, 0x57);  // W
    byteData.setUint8(9, 0x41);  // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E

    // fmt chunk
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // (space)
    byteData.setUint32(16, 16, Endian.little); // chunk size
    byteData.setUint16(20, 1, Endian.little);  // PCM
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }
}
