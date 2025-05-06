import 'package:flutter/material.dart';
import 'package:harmoniglow/provider/app_provider.dart';
import 'package:provider/provider.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  SettingViewState createState() => SettingViewState();
}

class SettingViewState extends State<SettingView> {
  AppProvider appProvider = AppProvider();

  @override
  void initState() {
    // Initialize the countdown value from the app provider
    appProvider = Provider.of<AppProvider>(context, listen: false);

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dark Mode',
                    style: TextStyle(fontSize: 18),
                  ),
                  Switch(
                    value: context.watch<AppProvider>().isDarkMode,
                    onChanged: (value) {
                      appProvider.setDarkMode(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Countdown Adjustment
              const Text(
                'Adjust Countdown',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      appProvider.setCountdownValue(false);
                    },
                  ),
                  Text(
                    '${context.watch<AppProvider>().countdownValue} seconds',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      appProvider.setCountdownValue(true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
