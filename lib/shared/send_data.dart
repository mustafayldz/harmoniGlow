import 'package:flutter/material.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';

class SendData {
  // Güncellenmiş Bluetooth gönderim fonksiyonu:
  Future<void> sendHexData(BluetoothBloc bloc, List<int> data) async {
    final device = bloc.state.connectedDevice;
    final characteristic = bloc.state.characteristic;

    if (device == null || characteristic == null) {
      debugPrint('❌ Error: No connected device or characteristic is null.');
      return;
    }

    try {
      final hexString = data
          .map((e) => '0x${e.toRadixString(16).padLeft(2, '0').toUpperCase()}')
          .toList();
      debugPrint('📤 Sending data: $hexString');
      await characteristic.write(data);
      debugPrint('✅ Data sent successfully.');
    } catch (error) {
      debugPrint('❗ Error sending data: $error');
    }
  }
}
