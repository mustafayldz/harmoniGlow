import 'package:flutter/material.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:provider/provider.dart';

/// 🧪 Debug widget for resetting session flags
class DebugSessionControls extends StatelessWidget {
  const DebugSessionControls({super.key});

  @override
  Widget build(BuildContext context) {
    // Debug modda değilse gösterme
    if (!const bool.fromEnvironment('dart.vm.product', defaultValue: true)) {
      return const SizedBox.shrink();
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧪 Debug Session Controls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(
                      userProvider.hasShownVersionCheckThisSession
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: userProvider.hasShownVersionCheckThisSession
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Version Check Shown'),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      userProvider.hasShownInitialAdThisSession
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: userProvider.hasShownInitialAdThisSession
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Initial Ad Shown'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () {
                    userProvider.resetSessionFlags();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session flags reset!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Reset Session Flags'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
