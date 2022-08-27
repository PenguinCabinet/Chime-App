import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:audioplayers/audioplayers.dart';
//import 'package:audio_in_app/audio_in_app.dart';
//import 'package:audioplayers_windows/*';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
//import 'package:window_size/window_size.dart';

void main() {
  //setWindowTitle("チャイムアプリ");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'チャイムアプリ',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'チャイムアプリ'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class alert_t {
  String text = "";
  TimeOfDay start_time = TimeOfDay.now();
  TimeOfDay end_time = TimeOfDay.now();
  alert_t(String t, TimeOfDay st, TimeOfDay et) {
    text = t;
    start_time = st;
    end_time = et;
  }

  alert_t.fromJson(Map<String, dynamic> json_data) {
    text = json_data["text"];
    final start_time_temp = json.decode(json_data["start_time"].toString());
    start_time =
        new TimeOfDay(hour: start_time_temp[0], minute: start_time_temp[1]);
    final end_time_temp = json.decode(json_data["end_time"].toString());
    end_time = new TimeOfDay(hour: end_time_temp[0], minute: end_time_temp[1]);
  }

  dynamic toJson() => {
        "text": text,
        "start_time": "[${start_time.hour},${start_time.minute}]",
        "end_time": "[${end_time.hour},${end_time.minute}]",
      };
}

String TimeOfDateToString(TimeOfDay v) {
  return "${v.hour.toString().padLeft(2, "0")}:${v.minute.toString().padLeft(2, "0")}";
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<alert_t> list_data = [];
  SharedPreferences? prefs;
  bool clock = true;
  //AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  AudioPlayer player = AudioPlayer();

  void alert_Play(TimeOfDay now) {
    list_data.forEach((e) {
      if (now == e.start_time) {
        print("スタートチャイム");
        player.play();
      }
      if (now == e.end_time) {
        print("終了チャイム");
        player.play();
      }
    });
  }

  bool Is_card_colored(alert_t a) {
    final now = TimeOfDay.now();
    final temp = 60 * now.hour + now.minute;
    final s_temp = 60 * a.start_time.hour + a.start_time.minute;
    final e_temp = 60 * a.end_time.hour + a.end_time.minute;
    return s_temp <= temp && temp <= e_temp;
  }

  void alert_Update() {
    final now_datetime = DateTime.now();
    if (now_datetime.second == 0) {
      final now = TimeOfDay.now();
      alert_Play(now);
      setState(() {
        clock = !clock;
      });
    }
    Future.delayed(Duration(seconds: 1), () {
      alert_Update();
    });
  }

  void _incrementCounter() async {
    final alert_t? alert = await Navigator.of(context).push(
      MaterialPageRoute<alert_t>(builder: (context) {
        return ListAddPage();
      }),
    );
    if (alert != null) {
      setState(() {
        list_data.add(alert);
        list_data.sort((a, b) => (60 * a.start_time.hour + a.start_time.minute)
            .compareTo(60 * b.start_time.hour + b.start_time.minute));
      });
      Future.delayed(Duration(seconds: 1), () async {
        await prefs?.setString("chime_app_data", json.encode(list_data));
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Future(() async {
      prefs = await (SharedPreferences.getInstance());
      /*
      chime_sound = AudioPlayer();
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.speech());
      await chime_sound!.setAudioSource(ConcatenatingAudioSource(children: [
        AudioSource.uri(Uri.parse('asset:///assets/Chime1.ogg'))
      ]));
      */
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.speech());
      await player.setAsset("assets/sounds/Chime1.ogg");
      setState(() {
        if (prefs != "") {
          final String list_str = prefs?.getString('chime_app_data') ?? '';
          if (list_str != "") {
            List<dynamic> temp = json.decode(list_str);
            list_data = temp.map((i) => new alert_t.fromJson(i)).toList();
          }
        }
      });
    });
    alert_Update();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      backgroundColor: Color.fromRGBO(0, 100, 0, 1),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView.builder(
          itemCount: list_data.length,
          itemBuilder: (context, index) {
            Color card_color = Colors.white;
            if (Is_card_colored(list_data[index])) {
              card_color = Colors.lightBlue;
            }
            return Card(
                margin: EdgeInsets.all(10),
                elevation: 10,
                color: card_color,
                shadowColor: Colors.black,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ListTile(
                          title: Text("${index + 1}:${list_data[index].text}")),
                      Container(
                        width: double.infinity,
                        child: Text(
                          "開始時刻${TimeOfDateToString(list_data[index].start_time)}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(""),
                              Text(
                                "終了時刻${TimeOfDateToString(list_data[index].end_time)}",
                                textAlign: TextAlign.left,
                                style: TextStyle(color: Colors.black87),
                              ),
                              Container(
                                  alignment: Alignment.topLeft,
                                  child: IconButton(
                                    onPressed: () async => {
                                      setState(() {
                                        list_data.removeAt(index);
                                        Future.delayed(Duration(seconds: 1),
                                            () async {
                                          await prefs?.setString(
                                              "chime_app_data",
                                              json.encode(list_data));
                                        });
                                      })
                                    },
                                    icon: Icon(Icons.clear),
                                  ))
                            ]),
                      ),
                    ]));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ListAddPage extends StatefulWidget {
  @override
  _ListAddPage createState() => _ListAddPage();
}

class _ListAddPage extends State<ListAddPage> {
  alert_t alert = new alert_t("", TimeOfDay.now(), TimeOfDay.now());

  void _handleText(String e) {
    setState(() {
      alert.text = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャイムの追加'),
      ),
      body: Container(
        padding: EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("", style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 8),
            TextButton(
              child: Text("開始時刻:${TimeOfDateToString(alert.start_time)}"),
              onPressed: () async {
                final timeOfDay = await showTimePicker(
                  context: context,
                  initialTime: alert.start_time,
                  initialEntryMode: TimePickerEntryMode.input,
                  /*
                  builder: (BuildContext context, Widget child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                  */
                );
                if (timeOfDay != null)
                  setState(() => {alert.start_time = timeOfDay});
              },
            ),
            TextButton(
              child: Text("終了時刻:${TimeOfDateToString(alert.end_time)}"),
              onPressed: () async {
                final timeOfDay = await showTimePicker(
                  context: context,
                  initialTime: alert.end_time,
                  initialEntryMode: TimePickerEntryMode.input,
                  /*
                  builder: (BuildContext context, Widget child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                  */
                );
                if (timeOfDay != null)
                  setState(() => {alert.end_time = timeOfDay});
              },
            ),
            TextField(
                style: TextStyle(color: Colors.black), onChanged: _handleText),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(alert);
                },
                child: Text('リスト追加', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Container(/* --- 省略 --- */),
          ],
        ),
      ),
    );
  }
}
