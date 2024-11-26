import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_event.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_state.dart';
import 'package:harmoniglow/screens/bluetooth/find_devices.dart';
import 'package:harmoniglow/screens/setting/rgb_leds.dart';
import 'package:harmoniglow/screens/shuffle/shuffle_mode.dart';
import 'package:harmoniglow/screens/songs/songs.dart';
import 'package:harmoniglow/screens/training/traning_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BluetoothBloc, BluetoothStateC>(
        builder: (context, bluetoothState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                _buildConnectionStatus(
                    bluetoothState), // Passing BluetoothState here
                const SizedBox(height: 16),
                _buildNotesInfo(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BluetoothStateC state) {
    final icon = Icon(
      state.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
      color: state.isConnected ? Colors.green : Colors.red,
      size: 30,
    );

    final text = Text(
      state.isConnected
          ? 'Connected to ${state.connectedDevice?.advName ?? 'Unknown Device'}'
          : 'Disconnected',
      style: TextStyle(
        fontSize: 18,
        color: state.isConnected ? Colors.green : Colors.red,
      ),
    );

    return InkWell(
      onTap: () {
        if (state.isConnected) {
          context
              .read<BluetoothBloc>()
              .add(DisconnectFromDeviceEvent(state.connectedDevice!));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FindDevicesScreen()),
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          text,
        ],
      ),
    );
  }

  Widget _buildNotesInfo() {
    final cardDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.8),
          Colors.cyanAccent.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 5,
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return Column(
      children: [
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainingPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              height: 150,
              decoration: cardDecoration,
              child: const Column(
                children: [
                  Text(
                    'Training',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Train with your own music',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SongPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              height: 150,
              decoration: cardDecoration,
              child: const Column(
                children: [
                  Text(
                    'Songs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Discover and train with your favorite songs',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShuffleMode(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              height: 150,
              decoration: cardDecoration,
              child: const Column(
                children: [
                  Text(
                    'Shuffle Mode',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Train with random music types',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RgbLedsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              height: 150,
              decoration: cardDecoration,
              alignment: Alignment.center,
              child: const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
