import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'check_list/BaseReorderableList.dart';
import 'dart:convert';

class StringCheckItem extends CheckItem {
  StringCheckItem(String title) {
    this.title = title;
    this.isChecked = false;
  }

  StringCheckItem.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    isChecked = json['isChecked'];
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isChecked': isChecked,
      'createDate': createDate,
    };
  }
}

enum KeySharedPreferences { string_todo_list }

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To do',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: MyHomePage(title: 'To do'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final List<StringCheckItem> _list = new List();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getListTodo()
        .then((List<StringCheckItem> localList) => _loadLocalList(localList));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      _setListTodo(_list).then((isSaved) => print(isSaved));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static Future<bool> _setListTodo(final List<StringCheckItem> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jsonStr = json.encode(list);
    final String key = KeySharedPreferences.string_todo_list.toString();
    return prefs.setString(key, jsonStr);
  }

  static Future<List<StringCheckItem>> _getListTodo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = KeySharedPreferences.string_todo_list.toString();
    final String jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) {
      return Future<List<StringCheckItem>>(() => List<StringCheckItem>());
    }

    return json
        .decode(jsonStr)
        .cast<Map<String, dynamic>>()
        .map<StringCheckItem>((json) => StringCheckItem.fromJson(json))
        .toList();
  }

  void _addNote() {
    setState(() {
      showDialog(context: context, builder: (_) => _createAddDialog());
    });
  }

  Widget _getBody() => _list.isEmpty
      ? Center(
    child: Text(
      "📌️",
      style: TextStyle(fontSize: 56.0),
    ),
  )
      : BaseReorderableList(
    listCheckItem: _list,
    hasDismissible: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _getBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _createAddDialog() {
    String noteAdded;
    return new AlertDialog(
      title: new Text("Add"),
      content: new TextField(
        decoration: new InputDecoration(hintText: "note"),
        onChanged: (String text) {
          noteAdded = text;
        },
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        new FlatButton(
            child: new Text("Add"),
            onPressed: () {
              if (noteAdded == null || noteAdded.isEmpty) {
                Navigator.pop(context);
                return;
              }
              setState(() {
                _list.insert(0, new StringCheckItem(noteAdded));
              });
            })
      ],
    );
  }

  _loadLocalList(final List<StringCheckItem> localList) {
    if (localList == null || localList.isEmpty) return;
    setState(() {
      //_list.clear();
      _list.addAll(localList);
    });
  }
}
