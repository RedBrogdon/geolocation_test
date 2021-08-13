import 'dart:async';

import 'package:flutter/material.dart';

import 'settings_controller.dart';
import 'package:geolocator/geolocator.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatefulWidget {
  const SettingsView({Key? key, required this.controller}) : super(key: key);

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  var permissionStatus = Geolocator.checkPermission();

  var latitude = 0.0;
  var longitude = 0.0;
  var accuracy = 0.0;

  String get location => 'Lat: $latitude, Long: $longitude, Acc: $accuracy';

  StreamSubscription<Position>? subscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from the dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<ThemeMode>(
              // Read the selected themeMode from the controller
              value: widget.controller.themeMode,
              // Call the updateThemeMode method any time the user selects a theme.
              onChanged: widget.controller.updateThemeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light Theme'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark Theme'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enable location:'),
                const SizedBox(width: 16),
                Switch(
                  value: widget.controller.locationEnabled,
                  onChanged: (value) {
                    widget.controller.updateLocationEnabled(value);
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: permissionStatus,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('There was an error!');
                } else if (!snapshot.hasData) {
                  return const Text('Waiting for permission status...');
                } else {
                  final status = snapshot.data!;
                  return Text('$status');
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Request permission'),
              onPressed: () => setState(
                () {
                  permissionStatus = Geolocator.requestPermission();
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Get Location'),
              onPressed: () async {
                late final String message;

                try {
                  final position = await Geolocator.getCurrentPosition();
                  message = 'Lat: ${position.latitude}, '
                      'Long: ${position.longitude}, '
                      'Acc: ${position.accuracy}';
                } catch (ex) {
                  message = ex.toString();
                }

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(message),
                ));
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Stream Location'),
              onPressed: subscription == null
                  ? () {
                      final sub =
                          Geolocator.getPositionStream().listen((position) {
                        setState(() {
                          latitude = position.latitude;
                          longitude = position.longitude;
                          accuracy = position.accuracy;
                        });
                      });

                      setState(() => subscription = sub);
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                child: const Text('Stop streaming'),
                onPressed: subscription != null
                    ? () {
                        subscription?.cancel();
                        setState(() => subscription = null);
                      }
                    : null),
            const SizedBox(height: 16),
            ElevatedButton(
                child:
                    Text(subscription?.isPaused == true ? 'Unpause' : 'Pause'),
                onPressed: subscription != null
                    ? () {
                        final sub = subscription!;
                        if (sub.isPaused) {
                          setState(() => sub.resume());
                        } else {
                          setState(() => sub.pause());
                        }
                      }
                    : null),
            const SizedBox(height: 16),
            Text(location),
          ],
        ),
      ),
    );
  }
}
