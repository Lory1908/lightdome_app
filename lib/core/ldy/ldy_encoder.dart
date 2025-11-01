import 'dart:typed_data';

class LdyEncoder {
  static List<int> encode({required int sampleRateHz, required List<int> y1023}) {
    final frames = y1023.length;
    final header = BytesBuilder();
    // Magic "LDY1"
    header.add([0x4C, 0x44, 0x59, 0x31]);
    // sr (uint16 LE)
    header.add(_u16le(sampleRateHz.clamp(0, 0xFFFF)));
    // frames (uint32 LE)
    header.add(_u32le(frames));
    // reserved (uint16 0)
    header.add(_u16le(0));

    final data = BytesBuilder();
    data.add(header.toBytes());
    for (final y in y1023) {
      final v = y.clamp(0, 1023);
      data.add(_u16le(v));
    }
    return data.toBytes();
  }

  static List<int> _u16le(int v) => [v & 0xFF, (v >> 8) & 0xFF];
  static List<int> _u32le(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
}

