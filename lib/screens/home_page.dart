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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: BlocBuilder<BluetoothBloc, BluetoothStateC>(
        builder: (context, bluetoothState) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.05),
              _buildConnectionStatus(context, bluetoothState),
              SizedBox(height: screenHeight * 0.02),
              _buildNavigationCards(context, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, BluetoothStateC state) =>
      InkWell(
        onTap: () {
          if (state.isConnected) {
            context
                .read<BluetoothBloc>()
                .add(DisconnectFromDeviceEvent(state.connectedDevice!));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FindDevicesScreen(),
              ),
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: state.isConnected ? Colors.green : Colors.red,
              size: 30,
            ),
            const SizedBox(width: 8),
            Text(
              state.isConnected
                  ? 'Connected to ${state.connectedDevice?.advName ?? 'Unknown Device'}'
                  : 'Disconnected',
              style: TextStyle(
                fontSize: 18,
                color: state.isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      );

  Widget _buildNavigationCards(BuildContext context, double screenHeight) =>
      Column(
        children: [
          _buildCard(
            context,
            'Training',
            'Train with your own music',
            screenHeight,
            const TrainingPage(),
          ),
          _buildCard(
            context,
            'Songs',
            'Discover and train with your favorite songs',
            screenHeight,
            const SongPage(),
          ),
          _buildCard(
            context,
            'Shuffle Mode',
            'Train with random music types',
            screenHeight,
            const ShuffleMode(),
          ),
          _buildCard(
            context,
            'Settings',
            '',
            screenHeight,
            const RgbLedsScreen(),
          ),
        ],
      );

  Widget _buildCard(
    BuildContext context,
    String title,
    String subtitle,
    double screenHeight,
    Widget destination,
  ) =>
      Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          ),
          child: Container(
            padding: EdgeInsets.all(screenHeight * 0.02),
            width: double.infinity,
            height: screenHeight * 0.18,
            decoration: _buildCardDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  BoxDecoration _buildCardDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Colors.blueAccent,
            Colors.cyanAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      );
}
