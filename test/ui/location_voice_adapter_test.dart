import 'package:ecopin_app/shared/maps/presentation/controllers/location_voice_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'reopening search rebinds the initialized SDK and releases old listeners',
    () async {
      const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return call.method == 'initialize' ||
                    call.method == 'has_permission'
                ? true
                : null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final firstStatuses = <String>[], secondStatuses = <String>[];
      final first = DeviceLocationVoice();
      expect(
        await first.prepare(onStatus: firstStatuses.add, onError: (_, _) {}),
        VoiceAvailability.ready,
      );
      SpeechToText().statusListener!('listening');
      await first.release();
      expect(SpeechToText().statusListener, isNull);
      final second = DeviceLocationVoice();
      expect(
        await second.prepare(onStatus: secondStatuses.add, onError: (_, _) {}),
        VoiceAvailability.ready,
      );
      SpeechToText().statusListener!('done');
      expect(firstStatuses, ['listening']);
      expect(secondStatuses, ['done']);
      expect(calls.where((call) => call == 'initialize'), hasLength(1));
      await second.release();
      expect(SpeechToText().statusListener, isNull);
      expect(SpeechToText().errorListener, isNull);
    },
  );
}
