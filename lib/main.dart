// ignore_for_file: prefer_const_constructors

import "package:flutter/material.dart";
import "dart:io";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "dart:ffi";
import "package:ffi/ffi.dart";

typedef DecodeWrapperC = Pointer<Utf8> Function(
    Pointer<Pointer<Utf8>> input, int length);
typedef DecodeWrapperDart = Pointer<Utf8> Function(
    Pointer<Pointer<Utf8>> input, int length);

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
  bool isConnected = false;
  Socket? m_socket;

  void updateServerData(String newData) {
    setState(() {
      serverData = newData;
    });
  }

  void switchConnectionStatus() {
    setState(() {
      isConnected = !isConnected;
    });
  }

  connect(String ip, String username, int port) async {
    try {
      print("Connecting to server...");
      m_socket = await Socket.connect(ip, port);
      print("Connected to server!");

      m_socket!.write("CONNECTED|PH0NE|" + username);

      m_socket!.listen(
        (data) {
          if (String.fromCharCodes(data) == "Username taken") {
            m_socket!.close();
          }
          updateServerData("\n" + String.fromCharCodes(data));
          print(isConnected);
        },
        onDone: () {
          print("Server closed the connection.");
        },
        onError: (error) {
          print("Error: $error");
          m_socket!.close();
        },
      );
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  void addButton(String serverName, String ip, String username, int port) {
    setState(() {
      dynamicButtons.add(
        DynamicButton(
          label: serverName,
          onPressed: () {
            showInputDialogServerOptions(
                context, serverName, ip, username, port);
          },
        ),
      );
    });
  }

  void removeButton(String serverName) {
    setState(() {
      dynamicButtons.removeWhere((button) => button.label == serverName);
    });
  }

  void showInputDialogServerOptions(BuildContext context, String serverName,
      String ip, String username, int port) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Server Options"),
              actions: <Widget>[
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(isConnected ? "Disconnect" : "Connect"),
                  onPressed: () {
                    setStateDialog(() {
                      switchConnectionStatus();
                    });

                    if (isConnected) {
                      connect(ip, username, port);
                    } else if (!isConnected) {
                      m_socket!.write("CL0SE|CONNECTION|PHONE");
                      m_socket!.close();
                    }
                  },
                ),
                TextButton(
                  child: Text("Remove"),
                  onPressed: () {
                    removeButton(serverName);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showInputDialogAddServer(BuildContext context) {
    String serverName = "";
    String ip = "";
    String username = "";
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
                TextField(
                  onChanged: (value) {
                    username = value;
                  },
                  decoration: InputDecoration(hintText: "Server Username"),
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
                  addButton(serverName, ip, username, port);
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
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor: Colors.grey[100],
          children: [
            SpeedDialChild(
              onTap: () => showInputDialogAddServer(context),
              child: Icon(Icons.add),
            ),
            SpeedDialChild(
              onTap: () => updateServerData(""),
              child: Icon(Icons.clear_all),
            ),
          ],
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
