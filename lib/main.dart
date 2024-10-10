import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:async'; // Add this import
import 'service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'PDF Analyzer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic>? _analysisResults;
  bool _isLoading = false;
  Stopwatch _stopwatch = Stopwatch(); 
  Timer? _timer; 
  String _elapsedTime = '0.0'; 

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsedTime = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  Future<void> _uploadPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        _isLoading = true;
        _startTimer();
      });
      try {
        final response = await ApiService.analyzePDF(file.path!);
        setState(() {
          _analysisResults = json.decode(response);
          _isLoading = false;
          _stopTimer();
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _stopTimer(); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Elapsed time: $_elapsedTime seconds'),
                ],
              ),
            )
          : _analysisResults == null
              ? Center(child: Text('Upload a PDF to analyze'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Name: ${_analysisResults!['patientName']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 20),
                        Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              children: ['Parameter', 'Optimal Range', 'Patient Value']
                                  .map((e) => TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(e, style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            ..._analysisResults!['parameters'].map<TableRow>((param) {
                              return TableRow(
                                children: [param['name'], param['optimalRange'], param['patientValue']]
                                    .map((e) => TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(e),
                                          ),
                                        ))
                                    .toList(),
                              );
                            }).toList(),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Additional Information:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 10),
                        ..._analysisResults!['additionalInfo'].map<Widget>((info) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text('• $info'),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _uploadPDF, // Disable button while loading
        child: Icon(Icons.upload_file),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}