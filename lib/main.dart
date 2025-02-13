// ignore_for_file: prefer_const_constructors

import "package:flutter/material.dart";
import "dart:io";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "utilities.dart";

final GlobalKey<AppState> appStateKey = GlobalKey<AppState>();

void main() => runApp(MaterialApp(
      home: App(),
    ));

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  TextEditingController _textFieldController = TextEditingController();

  List<DynamicButton> dynamicButtons = [];
  List<String> friends = [];
  List<String> friendNames = [];
  List<String> data = [];
  List<int> serverDataIndex = [];
  List<DynamicButton> serverData = [];
  bool isConnected = false;
  Socket? m_socket;

  void updateServerData(List<DynamicButton> newData) {
    setState(() {
      serverData = newData;
    });
  }

  void switchConnectionStatus() {
    setState(() {
      isConnected = !isConnected;
    });
  }

  void closeSocket() {
    if (m_socket != null) {
      m_socket!.write("CL0SE|CONNECTION|PHONE");
      m_socket!.close();
      print("Socket closed.");
    }
  }

  connect(String ip, String username, int port) async {
    try {
      print("Connecting to server...");
      m_socket = await Socket.connect(ip, port);
      print("Connected to server!");
      String nick = "";

      m_socket!.write("CONNECTED|PH0NE|" + username);

      m_socket!.listen(
        (data) {
          String formatedData = String.fromCharCodes(data);
          String finalData = "";
          bool foundHash = false;

          if (formatedData == "Username taken") {
            closeSocket();
          }

          for (var i = 0; i < formatedData.length; i++) {
            if (formatedData[i] == "|") {
              finalData = formatedData.substring(0, i);

              for (var ii = 0; ii < friends.length; ii++) {
                if (friends[ii] ==
                    formatedData.substring(i + 1, formatedData.length)) {
                  nick = friendNames[ii];
                  foundHash = true;
                  break;
                }
              }

              break;
            }
          }

          if (foundHash) {
            print(finalData);
            print(nick);
            addMsg(nick, finalData, serverData.length);
          }
        },
        onDone: () {
          print("Server closed the connection.");
          m_socket!.write("CL0SE|CONNECTION|PHONE");
          closeSocket();
        },
        onError: (error) {
          print("Error: $error");
          m_socket!.write("CL0SE|CONNECTION|PHONE");
          closeSocket();
        },
      );
    } catch (e) {
      print("Connection failed: $e");
      closeSocket();
    }
  }

  void addMsg(String nickname, String msg, int index) {
    setState(() {
      serverData.add(
        DynamicButton(
          label: nickname,
          onPressed: () {
            showMsgOptions(context, msg, index);
          },
        ),
      );
    });
  }

  void addServer(String serverName, String ip, String username, int port) {
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

  void showMsgOptions(BuildContext context, String msg, int index) {
    String result = "";
    bool isDecoded = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(isDecoded ? "Message" : "Message Options"),
            content:
                SingleChildScrollView(child: isDecoded ? Text(result) : null),
            actions: <Widget>[
              if (!isDecoded) ...[
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Delete"),
                  onPressed: () {
                    updateServerData([...serverData]..removeAt(index));
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Decode"),
                  onPressed: () {
                    isDecoded = false;

                    try {
                      List<String> input = msg.split(',');

                      for (int i = 0; i < input.length; i++) {
                        if (input[i].isNotEmpty) {
                          input[i] = input[i].substring(1);
                        }

                        if (i == input.length - 1) {
                          input[i] = input[i].trimLeft();
                        }
                      }
                      for (var i = 0; i < input.length; i++) {
                        print(input[i]);
                      }
                      setState(() {
                        result = utilityDecode(input);
                        isDecoded = true;
                      });
                    } catch (e) {
                      setState(() {
                        isDecoded = true;
                      });
                      result = "Something went wrong";
                      print(e);
                    }
                  },
                ),
              ],
              if (isDecoded)
                TextButton(
                  child: Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
            ],
          );
        });
      },
    );
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
          title: Text("Enter Data"),
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
                  addServer(serverName, ip, username, port);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showFriendList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Whitelist"),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: _textFieldController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: "Each hash in new line",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                _textFieldController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Ok"),
              onPressed: () {
                friends.clear();
                friendNames.clear();
                bool brokenOutOf = false;

                List<String> tempList = _textFieldController.text
                    .split(RegExp(r'\r?\n'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                for (int i = 0; i < tempList.length; i++) {
                  for (int ii = 0; ii < tempList[i].length; ii++) {
                    if (tempList[i][ii] == "/") {
                      friends.add(tempList[i].substring(0, ii));
                      friendNames.add(tempList[i].substring(ii + 1));
                      // print("${friends[i]}, ${friendNames[i]}");
                      brokenOutOf = true;
                      break;
                    }
                  }
                  if (!brokenOutOf) {
                    friends.add(tempList[i]);
                    friendNames.add("Message${serverData.length}");
                  }
                  brokenOutOf = false;
                }
                Navigator.of(context).pop();
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
                child: Column(
                  children: serverData,
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
              onTap: () => setState(() {
                serverData.clear();
              }),
              child: Icon(Icons.clear_all),
            ),
            SpeedDialChild(
              onTap: () => showFriendList(context),
              child: Icon(Icons.person_add_alt_1_rounded),
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
