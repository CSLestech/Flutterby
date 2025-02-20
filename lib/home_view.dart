import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'about_page.dart';
import 'history_page.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  File? _pickedImage;
  String? _prediction;
  final ImagePicker _picker = ImagePicker();
  final List<String> _history = [];
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chicken Defect Classification"),
        centerTitle: true,
      ),
      drawer: Container(
        width: 250, // Adjust the width as needed
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.purple,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/ui/chickog.png', // Replace with your app logo path
                      height: 80,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Check A Doodle Doo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('History'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HistoryPage(history: _history)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              const Divider(),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: (_pickedImage == null && _prediction == null)
          ? const Center(
              child: Text(
                "Select or Take an Image",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_prediction != null)
                  Text(
                    'Prediction: $_prediction',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  )
                else
                  const Text("Unable to classify the image.",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageSourceDialog,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Take a Picture"),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text("Select from Gallery"),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _prediction = null; // Reset prediction
      });
      _classifyImage(_pickedImage!);
    }
  }

  Future<void> _classifyImage(File image) async {
    const String serverUrl =
        'http://192.168.1.10:5000/predict'; // Remove extra period

    // Encode the image to base64
    final bytes = await image.readAsBytes();
    final String base64Image = base64Encode(bytes);

    // Create JSON payload
    final Map<String, String> payload = {"image": base64Image};

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        // Check if the prediction is inside the response correctly
        setState(() {
          _prediction = result['prediction']?.toString();
          _addToHistory(_prediction!);
        });
      } else {
        _logger.e('Error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error: $e');
    }
  }

  void _addToHistory(String prediction) {
    setState(() {
      if (_history.length >= 5) {
        _history.removeAt(0); // Remove the oldest entry
      }
      _history.add(prediction);
    });
  }
}
