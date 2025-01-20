// ignore_for_file: prefer_const_constructors

import "package:flutter/material.dart";
import "dart:io";

bool isConnected = true;
final GlobalKey<AppState> appStateKey = GlobalKey<AppState>();

void main() => runApp(MaterialApp(
      home: App(),
    ));

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  List<DynamicButton> dynamicButtons = [];
  List<String> data = [];
  String serverData = "";

  void updateServerData(String newData) {
    setState(() {
      serverData = newData;
    });
  }

  connect(String ip, int port) async {
    try {
      print("Connecting to server...");
      final socket = await Socket.connect(ip, port);
      print("Connected to server!");

      socket.write("CONNECTED|PH0NE");

      socket.listen(
        (data) {
          updateServerData("\n" + String.fromCharCodes(data));

          if (!isConnected) {
            socket.write("CL0SE|CONNECTION|PHONE");
            socket.close();
          }
        },
        onDone: () {
          print("Server closed the connection.");
        },
        onError: (error) {
          print("Error: $error");
          socket.close();
        },
      );
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  void addButton(String serverName, String ip, int port) {
    setState(() {
      dynamicButtons.add(
        DynamicButton(
          label: serverName,
          onPressed: () {
            connect(ip, port);
          },
        ),
      );
    });
  }

  void showInputDialog(BuildContext context) {
    String serverName = "";
    String ip = "";
    int port = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter data"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    serverName = value;
                  },
                  decoration: InputDecoration(hintText: "Server Name"),
                ),
                TextField(
                  onChanged: (value) {
                    ip = value;
                  },
                  decoration: InputDecoration(hintText: "Server IP"),
                ),
                TextField(
                  onChanged: (value) {
                    port = int.parse(value);
                  },
                  decoration: InputDecoration(hintText: "Server Port"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Add"),
              onPressed: () {
                if (serverName.isNotEmpty && ip.isNotEmpty && port != 0) {
                  addButton(serverName, ip, port);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Haptic Crypt",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[900],
        ),
        body: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: dynamicButtons,
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Text(
                    serverData,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showInputDialog(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class DynamicButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  DynamicButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
