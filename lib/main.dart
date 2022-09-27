import 'package:crclib/catalog.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRC Calculator',
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

  calculateCrc(List<XFile> files) {
    // status = [];
    for (var l in files) {
      setState(() {
        bars.add(FileReadProgress(file: l));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              'Drop the file here',
            ),
            // Expanded(
            //   child:
            AspectRatio(
              aspectRatio: 1.0,
              child: DropTarget(
                  onDragDone: (detail) {
                    setState(() {
                      // _list.addAll(detail.files);
                    });
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
                      child: const Center(child: Text("Drop here")))),
            ),
            Column(
              // shrinkWrap: true,
              children: bars,
              // )
            ),
            OutlinedButton(
              onPressed: bars.isNotEmpty
                  ? () {
                      // Respond to button press
                      setState(() {
                        bars.clear();
                      });
                    }
                  : null,
              child: const Text("Clear"),
            )
          ],
        ),
      ),
    );
  }
}

class FileReadProgress extends StatefulWidget {
  final XFile file;
  const FileReadProgress({super.key, required this.file});

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
    var value = await Crc32Xz().bind(file.openRead()).single;

    // var value = crc32.single;

    setState(() {
      result = 'CRC32: ${value.toRadixString(16).toUpperCase()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(widget.file.name),
        ),
        Expanded(
            child: result == null
                ? LinearProgressIndicator(semanticsLabel: widget.file.name)
                : Text(result!))
      ],
    );
  }
}
