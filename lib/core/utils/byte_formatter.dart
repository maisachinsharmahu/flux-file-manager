import 'dart:math';

class ByteFormatter {
  static String format(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (log(bytes) / log(1024)).floor();
    final value = bytes / pow(1024, i);
    return '${value.toStringAsFixed(i == 0 ? 0 : 2)} ${suffixes[i]}';
  }
}
