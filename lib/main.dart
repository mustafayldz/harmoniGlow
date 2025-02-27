import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/locator.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/bluetooth/bluetooth_off.dart';
import 'package:harmoniglow/screens/bluetooth/find_devices.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initializeDrumParts();
  setupLocator();
  runApp(const HarmoniGlow());
}

class HarmoniGlow extends StatelessWidget {
  const HarmoniGlow({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          // Provide BluetoothBloc
          BlocProvider<BluetoothBloc>(
            create: (context) => BluetoothBloc(),
          ),
          BlocProvider<DeviceBloc>(
            create: (context) => DeviceBloc(),
          ),
          RepositoryProvider<StorageService>(
            create: (context) => StorageService(),
          ),
        ],
        child: MaterialApp(
          color: Colors.lightBlue,
          debugShowCheckedModeBanner: false,
          home: StreamBuilder<BluetoothAdapterState>(
            stream: FlutterBluePlus.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state == BluetoothAdapterState.on) {
                return const FindDevicesScreen();
              }
              return BluetoothOffScreen(state: state);
            },
          ),
        ),
      );
}
