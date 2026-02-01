import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkBanner extends StatelessWidget {

  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
      stream: Connectivity().onConnectivityChanged,

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final result = snapshot.data;

        if (result == ConnectivityResult.none) {

          return Container(
            width: double.infinity,
            color: Colors.red,

            padding: const EdgeInsets.all(8),

            child: const Text(
              "Offline Mode",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
