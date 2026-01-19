import 'dart:io';
import 'media_service.dart';
import 'media_desktop_service.dart';

MediaService getMediaService() {
  // Solo Desktop por ahora
  return MediaDesktopService();
}
