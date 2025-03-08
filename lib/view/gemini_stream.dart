import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/src/fading_circle.dart';
import 'package:untitled/view/my_streaming_text_markdown.dart';

import '../database/chat.dart';
import '../database/database_helper.dart';
import '../database/gemini_adapter.dart';
class GeminiStream extends StatelessWidget {
  const GeminiStream({super.key, required this.text, required this.scrollController});
  final String text;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    GeminiAdapter adapter = Provider.of<GeminiAdapter>(context);

    return FutureBuilder<Candidates?>(
      future: adapter.updateListChatContentType(prompt: text), // yield* Gemini.instance.chats([prompt1, prompt2, ...])
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: const Center(child:SpinKitFadingCircle(color: Colors.black,)));
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(child: const Center(child: Text('Chats not send')));
        } else if (!snapshot.hasData) {
          return SliverToBoxAdapter(child: const Center(child: Text('Chats not received'),));
        } else{
          final result = snapshot.data!.output!;
          adapter.updateListChatContentType(prompt: text, output: result);
          if(snapshot.data!.finishReason == 'STOP') context.read<DatabaseHelper>().addChat(Chat(text, result));
          return SliverToBoxAdapter(

            child: MyStreamingTextMarkdown(markdownContent: result, scrollController: scrollController)
          );


        }
      },
    );

  }

}
