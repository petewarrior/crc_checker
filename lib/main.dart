import 'dart:io';

import 'package:crclib/catalog.dart';
import 'package:crclib/crclib.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isolate/isolate.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // not running on the web!
    if (Platform.isWindows || Platform.isIOS || Platform.isLinux) {
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        // size: Size(720, 540),
        center: true,
        fullScreen: false,
        minimumSize: Size(720, 540),
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        // await windowManager.setAspectRatio(4 / 3);
        // await windowManager.setMaximizable(false);
        await windowManager.setTitle("CRC Checker");
      });
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRC Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'CRC Checker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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

class _MyHomePageState extends State<MyHomePage> {
  List<Widget> bars = [];

  bool _dragging = false;
  CrcService crcService = CrcService();

  calculateCrc(List<XFile> files) {
    // status = [];
    List<Widget> b = files
        .map((file) => FileReadProgress(file: file, crcService: crcService))
        .toList();
    // []..length = files.length;
    // for (var l in files) {
    //   b.add(FileReadProgress(
    //     file: l,
    //     crcService: crcService,
    //   ));
    // }

    setState(() {
      bars.addAll(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: [
            Expanded(
                child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // const Text(
                          //   'Drop the file here',
                          // ),
                          // Expanded(
                          //   child:
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: DropTarget(
                                onDragDone: (detail) {
                                  calculateCrc(detail.files);
                                },
                                onDragEntered: (detail) {
                                  setState(() {
                                    _dragging = true;
                                  });
                                },
                                onDragExited: (detail) {
                                  setState(() {
                                    _dragging = false;
                                  });
                                },
                                child: Container(
                                    height: double.infinity,
                                    width: double.infinity,
                                    color: _dragging
                                        ? Colors.blue.withOpacity(0.4)
                                        : Colors.black26,
                                    child: const Center(
                                        child: Text("Drop the files here")))),
                          ),
                          Container(
                              margin: const EdgeInsets.all(10),
                              child: OutlinedButton(
                                onPressed: bars.isNotEmpty
                                    ? () {
                                        // Respond to button press
                                        setState(() {
                                          bars.clear();
                                        });
                                      }
                                    : null,
                                child: const Text("Clear"),
                              )),
                          Text(crcService.balancer != null
                              ? 'Threads: ${crcService.balancer!.length}'
                              : ''),
                        ]))),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: bars,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileReadProgress extends StatefulWidget {
  final XFile file;
  final CrcService crcService;

  const FileReadProgress(
      {super.key, required this.file, required this.crcService});

  @override
  State<FileReadProgress> createState() => _FileReadProgressState();
}

class _FileReadProgressState extends State<FileReadProgress> {
  String? result;

  @override
  initState() {
    super.initState();
    processFile(widget.file);
  }

  processFile(XFile file) async {
    var startTime = DateTime.now().millisecondsSinceEpoch;
    // var value = await Crc32Xz().bind(file.openRead()).single;
    var value = await widget.crcService.calculateCrc(file);
    var endTime = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      result =
          'CRC32: ${value.toRadixString(16).padLeft(8, '0').toUpperCase()} ${(endTime - startTime).toString().padLeft(5, ' ')}ms';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: SelectableText(widget.file.name),
        ),
        Expanded(
            child: result == null
                ? LinearProgressIndicator(semanticsLabel: widget.file.name)
                : SelectableText(
                    result!,
                    style: GoogleFonts.inconsolata(),
                  ))
      ],
    );
  }
}

class CrcService {
  LoadBalancer? balancer;
  late int _threads;

  CrcService({int threads = 8}) {
    // initBalancer();
    _threads = threads;
  }

  get threads {
    return _threads;
  }

  Stream<int> getCurrentThreadCount() async* {}

  set threads(value) {
    // TODO restart balancer with new thread count
    _threads = value;
  }

  initBalancer() async {}

  Future<CrcValue> calculateCrc(XFile file) async {
    balancer ??= await LoadBalancer.create(_threads, IsolateRunner.spawn);
    return await balancer!.run(_calculate, file);
  }

  Future<CrcValue> _calculate(XFile file) async {
    return await Crc32Xz().bind(file.openRead()).single;
  }
}
