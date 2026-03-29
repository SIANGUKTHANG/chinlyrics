import 'package:flutter/material.dart';

import '../json_helper.dart';
import 'hlabu_detail.dart';

class KhrihfaHlaBu extends StatefulWidget {
  const KhrihfaHlaBu({super.key});

  @override
  State<KhrihfaHlaBu> createState() => _KhrihfaHlaBuState();
}

class _KhrihfaHlaBuState extends State<KhrihfaHlaBu> {
  List d = [];
  List data = [];
  final TextEditingController _filter = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    setState(() {
      loading = true;
    });
    try {
      List<dynamic> jsonData = await JsonHelper().loadKhrihfaHlaBu();
      setState(() {
        d = jsonData;
        data = jsonData;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("JSON Laak lio ah palhnak: $e");
    }
  }

  void _filterJsonData(String searchTerm) {
    setState(() {
      d = data.where((element) {
        final name = (element['fields']['title'] ?? '').toString().toLowerCase();
        final searchLower = searchTerm.toLowerCase();
        return name.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
//backgroundColor: Colors.grey.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white,),
        title: Text('Khrihfa Hlabu'),
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0,vertical: 3),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(11),
              ),
              child: TextField(
                controller: _filter,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                onChanged: _filterJsonData,
                decoration: InputDecoration(
                  hintText: 'Hla min kawl...',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  // Ca a tial lio ahcun X (Clear) button a lang lai
                  suffixIcon: _filter.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _filter.clear();
                      _filterJsonData('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          // ================= 2. HLA LIST =================
          Expanded(
            child: d.isEmpty
            // Kawlmi a hmuh lo tikah langhter dingmi (Empty State)
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search_off, size: 60, color: Colors.white24),
                  SizedBox(height: 15),
                  Text(
                    'Hla na kawlmi a um lo.',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
            // Hla pawl mawi tein langhternak
                : ListView.builder(
              physics: const BouncingScrollPhysics(), // Scroll tuah tikah a mawi deuh nakhnga
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              itemCount: d.length,
              itemBuilder: (context, index) {
                var fields = d[index]['fields'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    // Hla icon mawi te
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.music_note, color: Colors.greenAccent, size: 20),
                    ),
                    title: Text(
                      fields['title'] ?? 'No Title',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () {

                      Navigator.push(context, MaterialPageRoute(builder: (context)=>
                          HlaBuDetail(
                            title: fields['title'],
                            zate: fields['zate'],
                            verse1: fields['v1'],
                            verse2: fields['v2'],
                            verse3: fields['v3'],
                            verse4: fields['v4'],
                            verse5: fields['v5'],
                            verse6: fields['v6'],
                            verse7: fields['v7'],
                            chorus: fields['cho'],
                          )));


                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}