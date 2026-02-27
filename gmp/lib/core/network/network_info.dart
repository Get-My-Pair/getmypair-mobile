import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // For web platform, assume connected (browser handles network)
    // The actual API call will fail if there's no connection
    if (kIsWeb) {
      return true;
    }
    
    try {
      // Try to connect to Google's public DNS server (8.8.8.8) on port 53
      // This is a reliable way to check if the device has network connectivity
      final socket = await Socket.connect('8.8.8.8', 53)
          .timeout(const Duration(seconds: 3));
      await socket.close();
      return true;
    } catch (_) {
      // If socket connection fails, try DNS lookup as fallback
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }
}

