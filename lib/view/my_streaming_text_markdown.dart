import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';



class MyStreamingTextMarkdown extends StatefulWidget {
  final String markdownContent;
  final ScrollController scrollController;
  const MyStreamingTextMarkdown({super.key, required this.markdownContent, required this.scrollController});

  @override
  State<MyStreamingTextMarkdown> createState() =>
      _MyStreamingTextMarkdownState();
}

class _MyStreamingTextMarkdownState extends State<MyStreamingTextMarkdown> {
  String displayedText = '';
  late Timer _textTimer;
  late Timer _scrollTimer;
  int _currentIndex = 0;
  final MarkdownStyleSheet _myMarkdownStyleSheet = MarkdownStyleSheet(
     h1: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
     p: TextStyle(color: Colors.white),
     codeblockDecoration: BoxDecoration(
       color: Color.fromARGB(128, 186, 181, 186),
       borderRadius: BorderRadius.circular(20.0)
     ),
  );



  @override
  void initState() {
    super.initState();
    _startTextStream();

    _scrollToBottom();
  }

  void _startTextStream() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_currentIndex < widget.markdownContent.length) {
        setState(() {
          displayedText += widget.markdownContent[_currentIndex];
          _currentIndex++;
        });
        _scrollToBottom();
      }
      else {
        _textTimer.cancel();
      }
    });
  }

  void _scrollToBottom(){


    //
    _scrollTimer = Timer.periodic(Duration(milliseconds: 10),
    (timer) {
      //TODO: Use animateTo and other animation curves

     WidgetsBinding.instance.addPostFrameCallback((_){
      if (widget.scrollController.position.pixels <
          widget.scrollController.position.maxScrollExtent) {
        widget.scrollController
            .jumpTo(widget.scrollController.position.maxScrollExtent);
      } else {
        _scrollTimer.cancel();
      }
      });
    }
    );

  }



  @override
  void dispose() {
    _textTimer.cancel();
    //! COMMENT OUT THESE TWO LINES if things go wrong
    _scrollTimer.cancel();
    widget.scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('This widget is being built $_currentIndex times and Scroll position pixels are ${widget.scrollController.position.pixels} and MaxScrollExtent is ${widget.scrollController.position.maxScrollExtent}');
    }
    //TODO: USE PAGEVIEW widget to display this UI
    return  ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter:ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: MarkdownBody(
          data:displayedText, styleSheet: _myMarkdownStyleSheet,),),
    );
  }
}
