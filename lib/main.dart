import 'package:air_brother/air_brother.dart';
import 'package:flutter/material.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo-Air-Brother-Prime',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Air Brother Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> _scannedFiles = [];

  int _counter = 0;

  /// We'll use this to scan for our devices.
  Future<List<Connector>> _fetchDevices = AirBrother.getNetworkDevices(5000);

  /// Connectors is how we communicate with the scanner. Given a connector
  /// we request a scan from it.
  /// Connectors can be retrieved using AirBrother.getNetworkDevices(timeout_millis);
  void _scanFiles(Connector connector) async {
    // This is the list where the paths for the scanned files will be placed.
    List<String> outScannedPaths = [];
    // Scan Parameters are used to configure your scanner.
    ScanParameters scanParams = ScanParameters();
    // In this case we want a scan in a paper of size A6
    scanParams.documentSize = MediaSize.A6;
    // When a scan is completed we get a JobState which could be an error if
    // something failed.
    JobState jobState = await connector.performScan(scanParams, outScannedPaths);
    print ("JobState: $jobState");
    print("Files Scanned: $outScannedPaths");

    // This is how we tell Flutter to refresh so it can use the scanned files.
    setState(() {
      _scannedFiles = outScannedPaths;
    });
  }


  @override
  Widget build(BuildContext context) {

    Widget body;

    // If we have some files scanned, let's display the.
    if (_scannedFiles.isNotEmpty) {
      body = ListView.builder(
          itemCount: _scannedFiles.length,
          itemBuilder: (context ,index) {
            return GestureDetector(
                onTap: () {
                  setState(() {
                    _scannedFiles = [];
                  });
                },
                // The _scannedFiles list contains the path to each image so let's show it.
                child: Image.file(File(_scannedFiles[index])));
          });
    }
    else {

      // If we don't have any files then will allow the user to look for a scanner
      // to scan.
      body = Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder(
          future: _fetchDevices,
          builder: (context, AsyncSnapshot<List<Connector>>snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Searching for scanners in your network.");
            }

            if (snapshot.hasData) {
              List<Connector> connectors = snapshot.data!;

              if (connectors.isEmpty) {
                return Text("No Scanners Found");
              }
              return ListView.builder(
                  itemCount: connectors.length,
                  itemBuilder: (context ,index) {
                    return ListTile(title: Text(connectors[index].getModelName()),
                      subtitle: Text(connectors[index].getDescriptorIdentifier()),
                      onTap: () {
                        // Once the user clicks on one of the scanners let's perform the scan.
                        _scanFiles(connectors[index]);
                      },);
                  });
            }
            else {
              return Text("Searching for Devices");
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Add your onPressed code here!
            _fetchDevices = AirBrother.getNetworkDevices(5000);
          });
        },
        tooltip: 'Find Scanners',
        child: Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
