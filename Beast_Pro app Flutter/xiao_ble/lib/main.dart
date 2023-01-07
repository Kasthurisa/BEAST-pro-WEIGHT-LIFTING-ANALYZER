import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:xiao_ble/start_page.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) => runApp(FlutterBlueApp()));
  runApp(FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (BuildContext context, Orientation orientation,
          DeviceType deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          color: const Color(0xFFFF9F03),
          theme: ThemeData(
            textTheme: GoogleFonts.robotoTextTheme(),
          ),
          home: StreamBuilder<BluetoothState>(
              stream: FlutterBlue.instance.state,
              initialData: BluetoothState.unknown,
              builder: (c, snapshot) {
                final state = snapshot.data;
                if (state == BluetoothState.on) {
                  return FindDevicesScreen();
                }
                return BluetoothOffScreen(state: state);
              }),
        );
      },
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF9F03),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF444654),
      appBar: AppBar(
        title: const Text(
          'Find Your Device',
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 10.0),
                    StreamBuilder<List<ScanResult>>(
                      stream: FlutterBlue.instance.scanResults,
                      initialData: const [],
                      builder: (c, snapshot) => Column(
                        children: snapshot.data!
                            .map((result) => ListTile(
                                title: Text(
                                  result.device.name == ""
                                      ? "No Name "
                                      : result.device.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.bluetooth_audio_outlined,
                                  color: Colors.white,
                                ),
                                onTap: () {
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    result.device.connect();
                                    Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                      return StartPage(device: result.device);
                                    }));
                                  });
                                }))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFF444654),
                      backgroundImage: AssetImage(
                        'assets/splash_img1.png',
                      ),
                      radius: 75,
                    ),
                    CircleAvatar(
                      backgroundColor: Color(0xFF444654),
                      backgroundImage: AssetImage(
                        'assets/splash_img2.png',
                      ),
                      radius: 75,
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Weight Lifting Analyzer',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.black54,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
                backgroundColor: const Color(0xFFFF9F03),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: const Duration(seconds: 4)),
                child: const Icon(Icons.search));
          }
        },
      ),
    );
  }
}
