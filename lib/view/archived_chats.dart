import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../database/chat.dart';
import '../database/database_helper.dart';
class ArchivedChats extends StatelessWidget {
   ArchivedChats({super.key});
   final MarkdownStyleSheet _myMarkdownStyleSheet = MarkdownStyleSheet(
    h1: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
    p: TextStyle(color: Colors.white),
    codeblockDecoration: BoxDecoration(
        color: Color.fromARGB(128, 186, 181, 186),
        borderRadius: BorderRadius.circular(20.0)
    ),
  );
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Chat>>(
      future: context.read<DatabaseHelper>().retrieveChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: Center(child: const CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(child: const Center(child: Text('Snapshot Error : Something must have happened')));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(child: const Center(child: Text('No Chats available'),));
        } else{
          final chats = snapshot.data!;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: chats.length,
            (context, index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(

                        child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10,sigmaY: 10),
                            child: Text(chats[index].prompt, style: TextStyle(color: Colors.white),))),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaY: 20.0,sigmaX: 20.0),
                        child: MarkdownBody(data: chats[index].output, styleSheet: _myMarkdownStyleSheet,),

                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          );

        }
      },
    );

  }
}