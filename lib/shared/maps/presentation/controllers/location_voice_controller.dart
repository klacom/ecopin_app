import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

enum VoiceAvailability { ready, permissionDenied, unavailable }

abstract interface class LocationVoiceBackend {
  Future<VoiceAvailability> prepare({
    required void Function(String) onStatus,
    required void Function(String, bool) onError,
  });
  Future<void> listen(void Function(String) onWords);
  Future<void> stop();
  Future<void> release();
}

class DeviceLocationVoice implements LocationVoiceBackend {
  final SpeechToText _speech = SpeechToText();
  void Function(String)? _status;
  void Function(String, bool)? _error;
  bool _released = false, _prepared = false;
  void _onStatus(String status) {
    if (!_released) _status?.call(status);
  }

  void _onError(SpeechRecognitionError error) {
    if (!_released) _error?.call(error.errorMsg, error.permanent);
  }

  @override
  Future<VoiceAvailability> prepare({
    required void Function(String) onStatus,
    required void Function(String, bool) onError,
  }) async {
    _status = onStatus;
    _error = onError;
    final ready = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    _prepared = ready;
    if (_released) {
      if (ready) await _speech.cancel();
      return VoiceAvailability.unavailable;
    }
    // The installed SDK initializes once. Rebind its public listeners when
    // search is reopened, since later initialize calls return immediately.
    _speech.statusListener = _onStatus;
    _speech.errorListener = _onError;
    if (ready) return VoiceAvailability.ready;
    return await _speech.hasPermission
        ? VoiceAvailability.unavailable
        : VoiceAvailability.permissionDenied;
  }

  @override
  Future<void> listen(void Function(String) onWords) async {
    await _speech.listen(
      onResult: (result) {
        if (!_released) onWords(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
  @override
  Future<void> release() async {
    _released = true;
    if (_speech.statusListener == _onStatus) _speech.statusListener = null;
    if (_speech.errorListener == _onError) _speech.errorListener = null;
    _status = null;
    _error = null;
    if (_prepared) await _speech.cancel();
  }
}

class LocationVoiceController extends ChangeNotifier {
  LocationVoiceController(this.backend, this.onWords);
  final LocationVoiceBackend backend;
  final void Function(String) onWords;
  bool busy = false, listening = false, canOpenSettings = false;
  bool _disposed = false, _acceptWords = false;
  String? error;
  void ignoreResults() => _acceptWords = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _status(String status) {
    if (_disposed) return;
    if (status == 'done' || status == 'notListening') listening = false;
    if (status == 'listening') listening = true;
    _changed();
  }

  void _error(String code, bool permanent) {
    if (_disposed) return;
    canOpenSettings = code.toLowerCase().contains('permission');
    error = canOpenSettings
        ? 'Microphone or speech access is denied. Type a place or check device permissions.'
        : 'Voice search could not hear a place. Try again or type your search.';
    if (permanent) listening = false;
    _changed();
  }

  Future<void> toggle() async {
    if (busy || _disposed) return;
    final stopping = listening;
    busy = true;
    error = null;
    canOpenSettings = false;
    _changed();
    try {
      if (listening) {
        await backend.stop();
        if (!_disposed) listening = false;
      } else {
        final available = await backend.prepare(
          onStatus: _status,
          onError: _error,
        );
        if (_disposed) return;
        if (available != VoiceAvailability.ready) {
          canOpenSettings = available == VoiceAvailability.permissionDenied;
          error = canOpenSettings
              ? 'Microphone or speech access is denied. Type a place or check device permissions.'
              : 'Voice search is unavailable on this device. You can type a place instead.';
          return;
        }
        _acceptWords = true;
        listening = true;
        await backend.listen((words) {
          if (!_disposed && _acceptWords) onWords(words);
        });
      }
    } catch (_) {
      if (!_disposed) {
        if (!stopping) {
          try {
            await backend.stop();
            if (!_disposed) listening = false;
          } catch (_) {
            /* Keep the listening state until the device confirms stop. */
          }
        }
        if (!_disposed) {
          error = listening
              ? 'Could not stop voice search. Try stopping again or close search.'
              : 'Voice search is unavailable. You can type a place instead.';
        }
      }
    } finally {
      if (!_disposed) {
        busy = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _acceptWords = false;
    unawaited(backend.release().catchError((_) {}));
    super.dispose();
  }
}
