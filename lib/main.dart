import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'chat_database.db');
  print('Path : $path ');
  final dbHelper = DatabaseHelper();
  await dbHelper.open(path);


  Chat chat = Chat('prompt', 'output');
  dbHelper.addChat(chat);

  final providers = [
    Provider<DatabaseHelper>(create: (context) => dbHelper),
    Provider<GeminiAdapter>(create: (context) => GeminiAdapter())
  ];
  MultiProvider multiProvider = MultiProvider(providers: providers, child: const MyApp(),);
  runApp(multiProvider);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(appBar: AppBar(), body: const GeminiHomePage(),)

    );
  }
}



class GeminiHomePage extends StatefulWidget {
  const GeminiHomePage({super.key});

  @override
  State<GeminiHomePage> createState() => _GeminiHomePageState();
}

class _GeminiHomePageState extends State<GeminiHomePage> {
  static bool buttonPressed  = false;

  bool onPressed(){
    setState(() {
      buttonPressed = true;
    });
    print('Button pressed');
    return buttonPressed;
  }

  final AppBarTheme appBarTheme =  const AppBarTheme(color: Colors.lightBlue);

  final TextEditingController _controller = TextEditingController();

  final IconData icon = Icons.send_rounded;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: LoadingChats()),
        if(buttonPressed) Expanded(child: GeminiStream(text: _controller.text)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _controller)),
              IconButton(
                  onPressed: () {
                    buttonPressed = onPressed();
                    _controller.clear();
                  },
                  icon: Icon(icon)
              )
            ],
          ),
        )
      ],
    );
  }
}

class GeminiStream extends StatelessWidget {
  const GeminiStream({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    GeminiAdapter adapter = Provider.of<GeminiAdapter>(context);
    var completeText = '';
    return StreamBuilder<Candidates>(
      stream: adapter.sendChats(text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child:SpinKitFadingCircle(color: Colors.black,));
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Error receiving stream'),);
        } else{
          Candidates candidates = snapshot.data!;
          final listOfJsonObjects = candidates.content!.parts!.map((textPart) => Part.toJson(textPart)).toList(); // [Map<S,D>,Map<S,D>,...]
          final partialText = listOfJsonObjects.map((jsonTextPart) => jsonTextPart['text']).toList().join();
          completeText = completeText + partialText;
          return StreamingTextMarkdown(text: completeText, typingSpeed: const Duration(milliseconds: 10));
        }
      },
    );

  }
}

class LoadingChats extends StatelessWidget {
  const LoadingChats({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Chat>>(
      future: context.read<DatabaseHelper>().retrieveChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Chats available'),);
        } else{
          final chats = snapshot.data!;
          return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return Column(
                    children: [
                      Text(chats[index].prompt),
                      Text(chats[index].output)
                    ]
                );
              },
          );
        }
      },
    );

  }
}


class Chat{
  final String prompt;
  final String output;
  Chat(this.prompt,this.output);

  Map<String, String> toMap(){
    return {
      'prompt': prompt,
      'output': output
    };
  }
  factory Chat.fromMap(Map<String, Object?> map){
    final chat = Chat(map['prompt']!.toString(), map['output']!.toString());
    return chat;
  }
}

class DatabaseHelper{
   late Database db;
   DatabaseHelper();



    Future<void> open(String path) async{
     db = await openDatabase(
         path,
         version: 1,
         onCreate: (Database db, int version) async {
           await db.execute('CREATE TABLE chats (id INTEGER PRIMARY KEY AUTOINCREMENT, prompt TEXT NOT NULL, output TEXT NOT NULL)');
           print('Table chats created');
     }
     );
     print('database opened');

    }

    Future deleteDatabase(String path) async{
      await databaseFactory.deleteDatabase(path);
    }

    Future addChat(Chat chat) async{
      return await db.insert('chats', chat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    Future removeChats([int? id]) async {
      return await db.delete('chats');
    }
    Future<List<Chat>> retrieveChats([int? id]) async {
      final futureMaps = await db.query('chats');
      final List<Chat> futureChats = futureMaps.map((chat) => Chat.fromMap(chat)).toList();
      return futureChats;
    }

}

class GeminiAdapter{
  static const api = 'AIzaSyB_eeE981hsvnZPE_HR03J7gRDmfYyvA3I';
  GeminiAdapter._();
  static late GeminiAdapter _instance;
  dynamic _response;
  final List<Content> chats = [];



  factory GeminiAdapter(){
      Gemini.init(apiKey: api);
      print('Gemini Initiated');
      _instance = GeminiAdapter._();
      return _instance;
  }
  get response{
    return _response;
  }
  void onError(error){
    throw GeminiException('Exception $error thrown by Gemini');
  }

  Future<void> sendPrompt(String prompt) async{
    _response = await Gemini.instance.prompt(parts: [Part.text(prompt)])
    .then(onError: onError, (value) => value!.output,);

  }
  Stream<Candidates> sendChats(String text, {Uint8List? bytes}) async*{
    Content content = Content(parts: [Part.text(text), if(bytes != null) Part.bytes(bytes)]);
    chats.add(content);
    yield* Gemini.instance.streamChat(chats);
  }
  void clearChats(){chats.clear();}


}


