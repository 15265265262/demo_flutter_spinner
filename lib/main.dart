import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinner/flutter_spinner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String data0 = 'no data',data1 = 'no data',data2 = 'no data';

  List<String> provinces = ['广东省','湖南省'];

  List<List<String>> citys = [
    ['佛山','深圳','广州'],
    ['长沙','张家界','郴州']];

  Map<String,List<String>> areas = {
    '0-0': ['a1','b1'],
    '0-1': ['c1','d1'],
    '0-2': ['e1','f1'],
    '1-0': ['a2','b2'],
    '1-1': ['c2','d2'],
    '1-2': ['e2','f2'],
  };

  int provincesCode = 0;
  int citysCode = 0;
  StreamController<int> streamController = StreamController.broadcast();

  Widget spinnerView(int i,List<String> list){
    return Spinner(
        id: i,
        height: 50.0,
        controller: streamController,
        alignment: Alignment.centerLeft,
        min: list.length * 50.0,
        max: 6 * 50.0,
        color: Colors.grey,
        opacity: 0.5,
        spinnerBarBuilder: (_,animation){
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(i == 0 ? data0 : i == 1 ? data1: data2)
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: RotationTransition(
                        turns: animation,
                        child: const Icon(Icons.arrow_drop_down,color: Colors.black,size: 28.0),
                      )
                  )
              )
            ],
          );
        },
        spinnerListBuilder: (_,state){
          return Material(
              child: ListView.separated(
                  padding: EdgeInsets.only(top: 0.0),
                  itemCount: list.length,
                  itemBuilder: (context,index){
                    return Ink(
                        color: Color(0xFFF4F4F4),
                        child: InkWell(
                            onTap: (){
                              state.handleTap();
                              streamController.sink.add(i);
                              setState(() {
                                switch(i){
                                  case 0:
                                    provincesCode = index;
                                    data0 = list[index];
                                    break;
                                  case 1:
                                    citysCode = index;
                                    data1 = list[index];
                                    break;
                                  case 2:
                                    data2 = list[index];
                                    break;
                                }
                              });
                            },
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              child: Text(list[index]),
                            )
                        )
                    );
                  },
                  separatorBuilder:  (context,index){
                    return Divider(height: 1.0,color: Colors.grey);
                  }
              )
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView(
            children: [
              Container(
                height: 150,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        for (int i = 0,size = 3;i<size;i++)
                          Expanded(
                            child: spinnerView(i,i == 0 ? provinces : i == 1? citys[provincesCode] : areas['$provincesCode-$citysCode']),
                          )
                      ],
                    )
                ),
              ),
              Container(
                height: 800,
                color: Colors.green,
              )
            ]
        )
    );
  }

  @override
  void dispose() {
    streamController?.close();
    super.dispose();
  }
}