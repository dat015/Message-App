 import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: SafeArea(
      child: Scaffold(
          // appBar: AppBar(
          //   backgroundColor: Colors.red,
          //   title: Text(
          //     'Hello world',
          //     style: TextStyle(color : Colors.white, fontSize: 20.0),
          //   ),
          //
          // ),
          // body:const Center(
          //     child: Text('Hello world'))
            body:Center(
              child: MyWidget2(false),
            )
        ),
    ),
    debugShowCheckedModeBanner: false,
  ));
}


class MyWidget extends StatelessWidget{
  final bool loading;
  MyWidget(this.loading);

  @override
  Widget build(BuildContext context) {
    if(loading){
      return const CircularProgressIndicator();
    }
    else{
      return Text('Loaded');
    }
  }

}

class MyWidget2 extends StatefulWidget{
  final bool loading;

  const MyWidget2(this.loading);

  @override
  State<StatefulWidget> createState() {
    return MyWidget2State();
  }

}

class MyWidget2State extends State<MyWidget2>{
  @override
  void initSate(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.loading){
      return CircularProgressIndicator();
    }else{
      return Text('stateFul');
    }
  }

}