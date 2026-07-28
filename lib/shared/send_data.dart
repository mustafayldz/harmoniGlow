import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:flutter/foundation.dart';

class SendData {
  Future<void> sendHexData(BluetoothBloc bloc, List<int> payload) async {
    final device = bloc.state.connectedDevice;
    final characteristic = bloc.state.characteristic;

    if (device == null || characteristic == null) {
      debugPrint('❌ Error: No connected device or characteristic is null.');
      return;
    }

    try {
      final fullPacket = [payload.length, ...payload];
      if (kDebugMode) {
        final hexString = fullPacket
            .map(
              (e) => '0x${e.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            )
            .toList();
        debugPrint('📤 Sending data: $hexString');
      }

      await characteristic.write(
        fullPacket,
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );
      if (kDebugMode) debugPrint('✅ Data sent successfully.');
    } catch (error) {
      debugPrint('❗ Error sending data: $error');
    }
  }
}
