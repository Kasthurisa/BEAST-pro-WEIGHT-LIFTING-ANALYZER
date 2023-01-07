import 'dart:async';

import 'package:battery_indicator/battery_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:sizer/sizer.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    Key? key,
    required this.device,
    required this.weight,
    required this.sets,
    required this.reps,
    required this.restTime,
  }) : super(key: key);

  final BluetoothDevice device;
  final String weight;
  final String sets;
  final String reps;
  final String restTime;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    _initiateServices();
  }

  @override
  void dispose() {
    super.dispose();
    sub!.cancel();
  }

  List<List<int>> allRepList = [];
  List<bool> breakBools = [];
  List<Duration> timeList = [];

  Stream<List<int>>? batteryStream;
  Stream<List<int>>? dataStream;

  String bestTime = '';
  String totalTime = '';

  bool showBattery = false;

  int currentCard = 0;
  int i = 0;
  int j = 1;
  int pageNumber = 0;
  int setsDone = 0;
  int repsDone = 0;

  PageController pageController = PageController(viewportFraction: 0.95);

  StreamSubscription? sub;

  Future<void> _initiateServices() async {
    for (int i = 0;
        i < int.parse(widget.sets) + (int.parse(widget.sets) - 1);
        i++) {
      setState(() {
        breakBools.add(false);
      });
    }

    for (int i = 0;
        i < int.parse(widget.sets) + (int.parse(widget.sets) - 1);
        i++) {
      setState(() {
        allRepList.add([]);
      });
    }

    List<BluetoothService> services = await widget.device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == 'e23602cb-de45-424f-9cd3-d7ae8880873f') {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() ==
              '12506959-e034-4177-a9e0-fcad73e79792') {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            dataStream = characteristic.value;
            setState(() {});
          }
        }
      }
    }

    sub = dataStream!.listen((event) {
      if ((allRepList.length) > i) {
        setState(() {
          allRepList[i].add(_dataParser(event));
          repsDone++;
        });
        setTimeList(_dataParser(event));
        if (allRepList[i].length % int.parse(widget.reps) == 0) {
          setsDone++;
          sub!.pause();
          setState(() {
            if ((allRepList.length) > j) {
              breakBools[j] = true;
            }
            i = i + 2;
            j = j + 2;
            currentCard++;
          });
          if (pageNumber < allRepList.length) {
            pageController.animateTo(95.w * currentCard,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn);
          }
        }
      } else {
        sub!.pause();
      }
    });

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

  int _dataParser(List<int> dataFromDevice) {
    List<int> tempList = dataFromDevice.reversed.toList();
    String tempHex = '';
    for (var element in tempList) {
      tempHex += element.toRadixString(16);
    }
    return int.parse(tempHex, radix: 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text(
          'Bench Press',
          style: TextStyle(
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
                    if (snapshot.connectionState == ConnectionState.active) {
                      int currentValue = _batteryDataParser(snapshot.data!);
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
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: int.parse(widget.sets) + (int.parse(widget.sets) - 1),
              controller: pageController,
              onPageChanged: (int page) {
                setState(() {
                  pageNumber = page + 1;
                });
              },
              itemBuilder: (context, int setCount) {
                if (setCount % 2 == 0) {
                  return Container(
                    margin: const EdgeInsets.all(15.0),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          spreadRadius: 0.5,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    height: 50.h,
                    width: 90.w,
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25.0, vertical: 10.0),
                      physics: const BouncingScrollPhysics(),
                      reverse: true,
                      itemCount: allRepList[setCount].length,
                      itemBuilder: (context, int repCount) {
                        List<int> data = [];
                        data.addAll(allRepList[setCount]);
                        List values = [];
                        String time = '';
                        String velocity = '';
                        if (data[repCount].toString().length == 5) {
                          time =
                              '00:0${data[repCount].toString().substring(0, 1)}';
                          velocity =
                              '${data[repCount].toString().substring(1, 3)}.${data[repCount].toString().substring(3)}';
                        }
                        if (data[repCount].toString().length == 6) {
                          time =
                              '00:${data[repCount].toString().substring(0, 2)}';
                          velocity =
                              '${data[repCount].toString().substring(2, 4)}.${data[repCount].toString().substring(4)}';
                        }
                        if (data[repCount].toString().length == 7) {
                          time =
                              '0${data[repCount].toString().substring(0, 1)}:${data[repCount].toString().substring(1, 3)}';
                          velocity =
                              '${data[repCount].toString().substring(3, 5)}.${data[repCount].toString().substring(5)}';
                        }
                        if (data[repCount].toString().length == 8) {
                          time =
                              '${data[repCount].toString().substring(0, 2)}:${data[repCount].toString().substring(2, 4)}';
                          velocity =
                              '${data[repCount].toString().substring(4, 6)}.${data[repCount].toString().substring(6)}';
                        }
                        values.add(time);
                        values.add(velocity);
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${repCount + 1}.',
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      values[0],
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                                  ],
                                ),
                                const VerticalDivider(
                                  thickness: 2,
                                  width: 15.0,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 15.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${double.parse(values[1]).toStringAsFixed(2)} m/s',
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3.0),
                                    Container(
                                      width: getBarLength(values[1]),
                                      height: 7.5,
                                      decoration: BoxDecoration(
                                        color: getBarColor(values[1]),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.all(15.0),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Color(0xFFFF9F03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          spreadRadius: 0.5,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    height: 50.h,
                    width: 85.w,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Rest',
                            style: TextStyle(
                              fontSize: 50.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          breakBools[setCount]
                              ? TimerCountdown(
                                  spacerWidth: 3,
                                  timeTextStyle: const TextStyle(
                                    fontSize: 50,
                                    color: Colors.white,
                                  ),
                                  format:
                                      CountDownTimerFormat.hoursMinutesSeconds,
                                  endTime: DateTime.now().add(
                                    parseDuration(widget.restTime),
                                  ),
                                  colonsTextStyle: const TextStyle(
                                    fontSize: 50,
                                  ),
                                  enableDescriptions: false,
                                  onEnd: () {
                                    setState(() {
                                      breakBools[setCount] = false;
                                      currentCard++;
                                    });
                                    if (pageNumber < allRepList.length) {
                                      pageController.animateTo(
                                          95.w * currentCard,
                                          duration:
                                              const Duration(milliseconds: 500),
                                          curve: Curves.easeIn);
                                    }
                                    sub!.resume();
                                  },
                                )
                              : currentCard > setCount
                                  ? const Text(
                                      'Finished',
                                      style: TextStyle(
                                        fontSize: 50.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(top: 15.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 0.5,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 30.0, horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'BEST',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          bestTime != '' ? bestTime : '--:--',
                          style: const TextStyle(
                            fontSize: 25.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        const Text(
                          'TOTAL TIME',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          totalTime != '' ? totalTime : '--:--',
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'SETS',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          '$setsDone-${widget.sets}x',
                          style: const TextStyle(
                            fontSize: 25.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        const Text(
                          'TOTAL REPS',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          '${repsDone}x',
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'LOAD',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          '${widget.weight} kg',
                          style: const TextStyle(
                            fontSize: 25.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        const Text(
                          'REPETITIONS',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          '$repsDone/${int.parse(widget.sets) * int.parse(widget.reps)}x',
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void setTimeList(int s) {
    String time = '';
    if (s.toString().length == 5) {
      time = '00:0${s.toString().substring(0, 1)}';
    }
    if (s.toString().length == 6) {
      time = '00:${s.toString().substring(0, 2)}';
    }
    if (s.toString().length == 7) {
      time = '0${s.toString().substring(0, 1)}:${s.toString().substring(1, 3)}';
    }
    if (s.toString().length == 8) {
      time = '${s.toString().substring(0, 2)}:${s.toString().substring(2, 4)}';
    }
    timeList.add(parseDuration(time));
    bestTime = timeList
        .reduce((value, element) => value < element ? value : element)
        .toString()
        .substring(2, 7);
    totalTime = timeList.reduce((a, b) => a + b).toString().substring(2, 7);
  }

  double getBarLength(String v) {
    double velocity = double.parse(double.parse(v).toStringAsFixed(2));
    if (velocity > 0.75) {
      return 50.w;
    } else if (velocity > 0.5) {
      return 30.w;
    } else {
      return 15.w;
    }
  }

  Color getBarColor(String v) {
    double velocity = double.parse(double.parse(v).toStringAsFixed(2));
    if (velocity > 0.75) {
      return const Color(0xFFFF9F03);
    } else if (velocity > 0.5) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int seconds;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    seconds = (int.parse(parts[parts.length - 1]));
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }
}
