import 'package:flutter/material.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';

class SendData {
  Future<void> sendLongData(BluetoothBloc bloc, List<int> data) async {
    final device = bloc.state.connectedDevice;
    int mtuSize = 20;
    try {
      mtuSize = await device!.mtu.first - 5;
    } catch (error) {
      debugPrint('Error fetching MTU size, using default 20 bytes: $error');
    }

    for (int offset = 0; offset < data.length; offset += mtuSize) {
      final int end =
          (offset + mtuSize < data.length) ? offset + mtuSize : data.length;
      final List<int> chunk = data.sublist(offset, end);

      try {
        // Ensure the characteristic supports writing
        if (bloc.state.characteristic!.properties.write) {
          await bloc.state.characteristic!.write(chunk);
          debugPrint('Chunk sent successfully, offset: $offset');
        } else {
          debugPrint('Error: Characteristic does not support writing.');
        }
      } catch (error) {
        debugPrint('Error sending chunk at offset $offset: $error');
      }
    }
  }

  Future<void> sendHexData(BluetoothBloc bloc, List<int> data) async {
    final device = bloc.state.connectedDevice;
    final characteristic = bloc.state.characteristic;

    if (device == null || characteristic == null) {
      debugPrint('Error: No connected device or characteristic is null.');
      return;
    }

    try {
      await characteristic.write(data,
          withoutResponse: characteristic.properties.writeWithoutResponse);
      debugPrint('Data sent successfully.');
    } catch (error) {
      debugPrint('Error sending data: $error');
    }
  }
}
