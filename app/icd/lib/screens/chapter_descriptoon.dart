import 'package:flutter/material.dart';



class ChapterDescripton extends StatelessWidget {
  final int  chapterNumber ;
  const ChapterDescripton({required this.chapterNumber , super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('Chapter Description'),
      ),

      
  
    );
  }
}