import 'dart:typed_data';

import 'package:flutter_gemini/flutter_gemini.dart';
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
    print('Content object created');
    print(chats.length);
    yield* Gemini.instance.streamChat(chats);
  }
  void clearChats(){
    chats.clear();
  }
  Future<Candidates?> updateListChatContentType({required String prompt, String? output, Uint8List? bytes}) async{
    Content userContent = Content(parts: [Part.text(prompt), if(bytes != null) Part.bytes(bytes)], role: 'user');
    chats.add(userContent);
    if(output != null) {
      Content modelContent = Content(
          parts: [Part.text(output), if (bytes != null) Part.bytes(bytes)],
          role: 'model');
      chats.add(modelContent);
    }


    return  Gemini.instance.chat(chats);
  }


}