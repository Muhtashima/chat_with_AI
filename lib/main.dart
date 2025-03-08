import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:untitled/view/archived_chats.dart';
import 'package:untitled/view/gemini_stream.dart';
import 'database/gemini_adapter.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'chat_database.db');
  print('Path : $path ');
  final dbHelper = DatabaseHelper();
  await dbHelper.open(path);



  final providers = [
    Provider<DatabaseHelper>(create: (context) => dbHelper),
    // *to manage storage items
    Provider<GeminiAdapter>(create: (context) => GeminiAdapter())
    // *to keep up-to-date with chats or List<Contents>
  ];
  MultiProvider multiProvider = MultiProvider(
    providers: providers,
    child: MyApp(path: path),
  );
  runApp(multiProvider);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        //TODO: APPLY DARK MODE
      home: Scaffold(
      //TODO: BEAUTIFY APPBAR or USE SliverAppBar
      appBar: AppBar(
        leading: IconButton(
            onPressed: (){
              exit(0);
            },
            icon: const Icon(Icons.exit_to_app)),
        actions: [
          TextButton(
              onPressed: () {
                context.read<DatabaseHelper>().deleteDatabase(path);
              },
              child: Icon(Icons.clear))
        ],
      ),
      body: Stack(children: [
        Image.asset(
          'images/Plum_blossoms_China.jpg',
          fit: BoxFit.cover,
          height: double.infinity,
        ),
        const GeminiHomePage()
      ]
      ),
    ));
  }
}

class GeminiHomePage extends StatefulWidget {
  const GeminiHomePage({super.key});

  @override
  State<GeminiHomePage> createState() => _GeminiHomePageState();
}

class _GeminiHomePageState extends State<GeminiHomePage> {
  final AppBarTheme appBarTheme = const AppBarTheme(color: Colors.lightBlue);

  final TextEditingController _controller = TextEditingController();

  final _scrollController = ScrollController();

  IconData icon = Icons.send_rounded;

  var buttonPressed = false;

  var text = '';

  var finishReason = '';

  final archivedChats = <Widget>[];

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // Initially, only ArchivedChats are Loaded inside Column children
    // no real-time response from Gemini or GeminiStream widgets
    archivedChats.add(ArchivedChats());

    super.initState();
  }

  void addGeminiStreamWidget(String text) {
    archivedChats.add(GeminiStream(
      text: text,
      scrollController: _scrollController,
    ));
  }

  List<Widget> archivedChatsWithGeminiStreamWidgets() {
    return archivedChats;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            //TODO: USE ALIGNMENT ACCORDING TO model or user chats
            slivers: archivedChatsWithGeminiStreamWidgets(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          //TODO: BEAUTIFY THIS SECTION OF UI
          child: Row(
            children: [
              Expanded(child: TextField(controller: _controller)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      text = _controller.text;
                      addGeminiStreamWidget(text);
                      _controller.clear();
                    });
                  },
                  icon: Icon(icon)),
              IconButton(
                  onPressed: () {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  },
                  icon: Icon(Icons.arrow_downward))
            ],
          ),
        )
      ],
    );
  }
}
