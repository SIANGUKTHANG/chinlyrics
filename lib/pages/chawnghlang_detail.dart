import 'package:flutter/material.dart';

import 'ChawngHlangSlide.dart';

class ChawngHlangDetail extends StatefulWidget {
  final title;
  final h1;
  final h2;
  final h3;
  final h4;
  final h5;
  final h6;
  final h7;
  final h8;
  final h9;
  final h10;

  final z1;
  final z2;
  final z3;
  final z4;
  final z5;
  final z6;
  final z7;
  final z8;
  final z9;
  final z10;

  const ChawngHlangDetail({
    Key? key,
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.h7,
    this.h8,
    this.h9,
    this.h10,
    this.z1,
    this.z2,
    this.z3,
    this.z4,
    this.z5,
    this.z6,
    this.z7,
    this.z8,
    this.z9,
    this.z10,
    this.title,
  }) : super(key: key);

  @override
  State<ChawngHlangDetail> createState() => _ChawngHlangDetailState();
}

class _ChawngHlangDetailState extends State<ChawngHlangDetail> {
  double fontSize = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(
          width: 1,
        ),
        title: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            widget.title,
            style:
                TextStyle(color: Colors.white, fontSize: 12, letterSpacing: -1),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.grey.shade900,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ChawngHlangSlide(
                    title: widget.title,
                    h1: widget.h1,
                    h2: widget.h2,
                    h3: widget.h3,
                    h4: widget.h4,
                    h5: widget.h5,
                    h6: widget.h6,
                    h7: widget.h7,
                    h8: widget.h8,
                    h9: widget.h9,
                    h10: widget.h10,
                    z1: widget.z1,
                    z2: widget.z2,
                    z3: widget.z3,
                    z4: widget.z4,
                    z5: widget.z5,
                    z6: widget.z6,
                    z7: widget.z7,
                    z8: widget.z8,
                    z9: widget.z9,
                    z10: widget.z10,
                  )));
        },
        icon: const Icon(
          Icons.slideshow,
          color: Colors.white,
        ),
        label: Text(
          'Slide',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onDoubleTap: () {
          if (fontSize == 35) {
            fontSize = fontSize - 20;
          } else {
            fontSize = fontSize + 5;
          }
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            children: [
              widget.h1 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h1,
                        style: TextStyle(
                            fontSize: fontSize, color: Colors.white70),
                      ),
                    ),
              widget.z1 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z1,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h2 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h2,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z2 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z2,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h3 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h3,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z3 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z3,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h4 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h4,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z4 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z4,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h5 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h5,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z5 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z5,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h6 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h6,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z6 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z6,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h7 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h7,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z7 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z7,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h8 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h8,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z8 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z8,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h9 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h9,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z9 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z9,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              widget.h10 == null
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        widget.h10,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              widget.z10 == null
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.only(
                          left: 12, bottom: 10, top: 4),
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        widget.z10,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
              const SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}
