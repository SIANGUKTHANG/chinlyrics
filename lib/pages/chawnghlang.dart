import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../json_helper.dart';
import 'chawnghlang_detail.dart';

class ChawngHlang extends StatefulWidget {
  const ChawngHlang({Key? key}) : super(key: key);

  @override
  State<ChawngHlang> createState() => _ChawngHlangState();
}

class _ChawngHlangState extends State<ChawngHlang> {
  bool loading = false;

  List d = [];

  @override
  void initState() {
    _loadJsonData();
    super.initState();
  }

  _loadJsonData() async {
    setState(() {
      loading= true;
    });
    List<dynamic> jsonData = await JsonHelper().loadChawngHlang();
    setState(() {
      d = jsonData;
      loading =  false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        leading: const SizedBox(width: 1,),
        title: Text('Chawnghlang Relnak',
            style: GoogleFonts.aleo(
              fontSize: 16,
              letterSpacing: 1,
              color: Colors.white,

            )),

        centerTitle: true,
      ),
      body: loading?
      const Center(child: CircularProgressIndicator(),):
      Column(
        children: [
Expanded(
            child: ListView.builder(
                itemCount: d.length,
                itemBuilder: (context, index) {

                  return  ListTile(
                    onTap: (){
                      Get.to(ChawngHlangDetail(
                        title: d[index]['fields']['title'],
                        h1: d[index]['fields']['h1'],
                        h2: d[index]['fields']['h2'],
                        h3: d[index]['fields']['h3'],
                        h4: d[index]['fields']['h4'],
                        h5: d[index]['fields']['h5'],
                        h6: d[index]['fields']['h6'],
                        h7: d[index]['fields']['h7'],
                        h8: d[index]['fields']['h8'],
                        h9: d[index]['fields']['h9'],
                        h10: d[index]['fields']['h10'],
                        z1: d[index]['fields']['z1'],
                        z2: d[index]['fields']['z2'],
                        z3: d[index]['fields']['z3'],
                        z4: d[index]['fields']['z4'],
                        z5: d[index]['fields']['z5'],
                        z6: d[index]['fields']['z6'],
                        z7: d[index]['fields']['z7'],
                        z8: d[index]['fields']['z8'],
                        z9: d[index]['fields']['z9'],
                        z10: d[index]['fields']['z10'],
                      ));
                    },
                    title: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        d[index]['fields']['title'],
                        style:
                        GoogleFonts.vastShadow(fontSize: 12,color: Colors.white70,letterSpacing: -1),
                      ),
                    ),
                  );
                }),
          ),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }
}
