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