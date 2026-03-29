import 'package:flutter/material.dart';
import '../json_helper.dart';
import 'chawnghlang_detail.dart';

class ChawngHlang extends StatefulWidget {
  const ChawngHlang({super.key});

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

  Future<void> _loadJsonData() async {
    setState(() => loading = true);
    try {
      List<dynamic> jsonData = await JsonHelper().loadChawngHlang();
      setState(() => d = jsonData);
    } catch (e) {
      debugPrint("Error loading JSON: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
 return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Appbar rong phih
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.pinkAccent.withOpacity(0.15),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chawnghlang Relnak',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.pinkAccent,
          strokeWidth: 3,
        ),
      )
          : ListView.builder(
          physics: const BouncingScrollPhysics(), // Scroll a nuam deuh nakhnga
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          itemCount: d.length,
          itemBuilder: (context, index) {
            final fields = d[index]['fields'];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                    color: Colors.pinkAccent.withOpacity(0.1),
                    width: 1
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.pinkAccent.withOpacity(0.1),
                  highlightColor: Colors.pinkAccent.withOpacity(0.05),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChawngHlangDetail(
                              title: fields['title'],
                              h1: fields['h1'], h2: fields['h2'], h3: fields['h3'],
                              h4: fields['h4'], h5: fields['h5'], h6: fields['h6'],
                              h7: fields['h7'], h8: fields['h8'], h9: fields['h9'],
                              h10: fields['h10'],
                              z1: fields['z1'], z2: fields['z2'], z3: fields['z3'],
                              z4: fields['z4'], z5: fields['z5'], z6: fields['z6'],
                              z7: fields['z7'], z8: fields['z8'], z9: fields['z9'],
                              z10: fields['z10'],
                            )
                        )
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Hmai i Icon mawi te
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(

                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                )
                              ]
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded, // Caauk icon
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Ca (Title)
                        Expanded(
                          child: Text(
                            fields['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),

                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }
}