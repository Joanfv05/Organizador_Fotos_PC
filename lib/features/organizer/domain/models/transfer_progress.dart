// transfer_progress.dart - Versión mejorada
class TransferProgress {
  final int current;
  final int total;
  final String currentFile;
  final TransferType type;
  final double? filePercentage;
  final String? sourcePath;
  final String? destinationPath;
  final int? fileSizeKB;
  final DateTime? startTime;
  final DateTime? currentTime;

  TransferProgress({
    required this.current,
    required this.total,
    required this.currentFile,
    required this.type,
    this.filePercentage,
    this.sourcePath,
    this.destinationPath,
    this.fileSizeKB,
    this.startTime,
    this.currentTime,
  });

  double get percentage {
    if (total == 0) return 0;

    if (filePercentage != null) {
      final baseProgress = (current - 1) / total * 100;
      final fileProgress = (filePercentage! / 100) * (100 / total);
      return baseProgress + fileProgress;
    }

    return (current / total) * 100;
  }

  String get statusText {
    switch (type) {
      case TransferType.pull:
        return 'Descargando desde el dispositivo';
      case TransferType.push:
        return 'Subiendo al dispositivo';
      case TransferType.organizing:
        return 'Organizando archivos';
      case TransferType.scanning:
        return 'Buscando archivos';
    }
  }

  String get detailedInfo {
    if (sourcePath != null && destinationPath != null) {
      return 'De: ${sourcePath!.split('/').last}\nA: ${destinationPath!.split('/').last}';
    } else if (sourcePath != null) {
      return 'Desde: ${sourcePath!.split('/').last}';
    } else if (destinationPath != null) {
      return 'Hacia: ${destinationPath!.split('/').last}';
    }
    return '';
  }

  String get fileInfo {
    final sizeInfo = fileSizeKB != null ? ' (${fileSizeKB}KB)' : '';
    return '$currentFile$sizeInfo';
  }

  String? get timeInfo {
    if (startTime != null && currentTime != null) {
      final duration = currentTime!.difference(startTime!);
      final seconds = duration.inSeconds;
      if (seconds > 0) {
        final speed = current > 0 ? seconds / current : 0;
        final remaining = total - current;
        final etaSeconds = (remaining * speed).toInt();

        if (etaSeconds > 0) {
          final etaMinutes = (etaSeconds / 60).ceil();
          return 'Tiempo restante: ~${etaMinutes} min';
        }
      }
    }
    return null;
  }
}

enum TransferType {
  pull,
  push,
  organizing,
  scanning,
}