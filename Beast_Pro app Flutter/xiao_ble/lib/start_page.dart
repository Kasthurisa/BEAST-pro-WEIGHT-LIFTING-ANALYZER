import 'dart:ui';

import 'package:battery_indicator/battery_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:xiao_ble/time_text_input_formatter.dart';

import 'analysis_screen.dart';
import 'loading_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool startTimer = false;
  bool? isConnected;

  String weight = '';
  String sets = '';
  String reps = '';
  String restTime = '';

  Stream<List<int>>? batteryStream;
  bool showBattery = false;
  bool _isProgressShow = false;

  @override
  void initState() {
    setState(() {
      _isProgressShow = true;
    });
    super.initState();
    widget.device.disconnect();
    widget.device.connect();
    Future.delayed(const Duration(seconds: 5), () {
      _initiateServices();
      setState(() {
        _isProgressShow = false;
      });
    });
  }

  Future<void> _initiateServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == 'e23602cb-de45-424f-9cd3-d7ae8880873f') {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() ==
              'e7b37a22-cfe0-4331-92ea-176c95432cd6') {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            batteryStream = characteristic.value;
            setState(() {
              showBattery = true;
            });
          }
        }
      }
    }
  }

  int _batteryDataParser(List<int> dataFromDevice) {
    return dataFromDevice[0];
  }

  @override
  Widget build(BuildContext context) {
    return _isProgressShow
        ? const LoadingPage()
        : Scaffold(
            appBar: AppBar(
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.navigate_before,
                  color: Color(0xFFFF9F03),
                  size: 50.0,
                ),
              ),
              title: Text(
                widget.device.name,
                style: const TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              actions: [
                showBattery
                    ? StreamBuilder<List<int>>(
                        stream: batteryStream,
                        builder: (BuildContext context,
                            AsyncSnapshot<List<int>> snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Error');
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.active) {
                            int currentValue =
                                _batteryDataParser(snapshot.data!);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                                vertical: 12.5,
                              ),
                              child: BatteryIndicator(
                                batteryLevel: currentValue,
                                batteryFromPhone: false,
                                showPercentNum: true,
                                mainColor: const Color(0xFFFF9F03),
                                style: BatteryIndicatorStyle.values[1],
                                colorful: true,
                                ratio: 4,
                              ),
                            );
                          } else {
                            return const Text('Stream Error');
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (_validate()) {
                  if (isConnected!) {
                    setState(() {
                      startTimer = true;
                    });
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Error"),
                        content: const Text("Please connect the device"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: const Text("OK"),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start"),
              backgroundColor: const Color(0xFFFF9F03),
            ),
            body: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: <Widget>[
                          StreamBuilder<BluetoothDeviceState>(
                            stream: widget.device.state,
                            initialData: BluetoothDeviceState.connecting,
                            builder: (c, snapshot) => ListTile(
                              leading: (snapshot.data ==
                                      BluetoothDeviceState.connected)
                                  ? const Icon(Icons.bluetooth_connected)
                                  : const Icon(Icons.bluetooth_disabled),
                              title: Text(
                                  'Device is ${snapshot.data.toString().split('.')[1]}'),
                              trailing: StreamBuilder<bool>(
                                stream: widget.device.isDiscoveringServices,
                                initialData: false,
                                builder: (c, snapshot) => IndexedStack(
                                  index: snapshot.data! ? 1 : 0,
                                  children: <Widget>[
                                    StreamBuilder<BluetoothDeviceState>(
                                      stream: widget.device.state,
                                      initialData:
                                          BluetoothDeviceState.connecting,
                                      builder: (c, snapshot) {
                                        VoidCallback? onPressed;
                                        String text;
                                        switch (snapshot.data) {
                                          case BluetoothDeviceState.connected:
                                            isConnected = true;
                                            onPressed = () {
                                              widget.device.disconnect();
                                              Navigator.pop(context);
                                            };
                                            text = 'DISCONNECT';
                                            break;
                                          case BluetoothDeviceState
                                              .disconnected:
                                            isConnected = false;
                                            onPressed =
                                                () => widget.device.connect();
                                            text = 'CONNECT';
                                            break;
                                          default:
                                            onPressed = null;
                                            text = snapshot.data
                                                .toString()
                                                .substring(21)
                                                .toUpperCase();
                                            break;
                                        }
                                        return TextButton(
                                            onPressed: onPressed,
                                            child: Text(
                                              text,
                                              style: const TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFFF9F03),
                                              ),
                                            ));
                                      },
                                    ),
                                    const IconButton(
                                      icon: SizedBox(
                                        width: 18.0,
                                        height: 18.0,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.grey),
                                        ),
                                      ),
                                      onPressed: null,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            weight = value;
                                          });
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          label: Text('Weight'),
                                          suffix: Text('Kg'),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              width: 3,
                                              color: Color(0xFFFF9F03),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15.0),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            restTime = value;
                                          });
                                        },
                                        keyboardType: TextInputType.datetime,
                                        inputFormatters: <TextInputFormatter>[
                                          TimeTextInputFormatter() // This input formatter will do the job
                                        ],
                                        decoration: const InputDecoration(
                                          suffix: Text('hh:mm:ss'),
                                          label: Text('Rest Time'),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              width: 3,
                                              color: Color(0xFFFF9F03),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            sets = value;
                                          });
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          label: Text('Sets'),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              width: 3,
                                              color: Color(0xFFFF9F03),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15.0),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            reps = value;
                                          });
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          label: Text('Reps'),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              width: 3,
                                              color: Color(0xFFFF9F03),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50.0),
                          startTimer
                              ? Column(
                                  children: [
                                    const Text(
                                      'Ready',
                                      style: TextStyle(
                                        fontSize: 75.0,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF9F03),
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    TimerCountdown(
                                      spacerWidth: 3,
                                      timeTextStyle: const TextStyle(
                                        fontSize: 75,
                                      ),
                                      format: CountDownTimerFormat.secondsOnly,
                                      endTime: DateTime.now().add(
                                        const Duration(seconds: 10),
                                      ),
                                      enableDescriptions: false,
                                      onEnd: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AnalysisScreen(
                                            device: widget.device,
                                            weight: weight,
                                            sets: sets,
                                            reps: reps,
                                            restTime: restTime,
                                          );
                                        })).then((value) {
                                          setState(() {
                                            startTimer = false;
                                          });
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  bool _validate() {
    if (weight == '' || !isNumeric(weight)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Please input a weight"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      );
      return false;
    } else if (restTime == '') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Please input a rest time"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      );
      return false;
    } else if (sets == '' || !isNumeric(sets)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Please input number of sets"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      );
      return false;
    } else if (reps == '' || !isNumeric(reps)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Please input number of reps"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      );
      return false;
    } else {
      if (double.parse(weight) < 0 || double.parse(weight) > 100) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Weight should not exceed 100kg"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        );
        return false;
      } else if (parseDuration(restTime) > const Duration(minutes: 8)) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Rest time should not exceed 8 minutes"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        );
        return false;
      } else if (double.parse(sets) < 0 || double.parse(sets) > 4) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Number of sets should not exceed 4"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        );
        return false;
      } else if (double.parse(reps) < 0 || double.parse(reps) > 10) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Number of reps should not exceed 10"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        );
        return false;
      } else {
        return true;
      }
    }
  }
}

bool isNumeric(String s) {
  return double.tryParse(s) != null;
}

Duration parseDuration(String s) {
  int hours = 0;
  int minutes = 0;
  int micros;
  List<String> parts = s.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}
