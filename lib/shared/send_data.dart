import 'package:flutter/material.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';

class SendData {
  Future<void> sendHexData(BluetoothBloc bloc, List<int> payload) async {
    final device = bloc.state.connectedDevice;
    final characteristic = bloc.state.characteristic;

    if (device == null || characteristic == null) {
      debugPrint('❌ Error: No connected device or characteristic is null.');
      return;
    }

    try {
      final fullPacket = [payload.length, ...payload]; // ✅ başa uzunluk eklendi

      final hexString = fullPacket
          .map((e) => '0x${e.toRadixString(16).padLeft(2, '0').toUpperCase()}')
          .toList();
      debugPrint('📤 Sending data: $hexString');

      await characteristic.write(fullPacket);
      debugPrint('✅ Data sent successfully.');
    } catch (error) {
      debugPrint('❗ Error sending data: $error');
    }
  }
}
