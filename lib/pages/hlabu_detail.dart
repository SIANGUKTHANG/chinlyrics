import 'package:flutter/material.dart';

class HlaBuDetail extends StatefulWidget {
  final String? title;
  final String? zate;
  final String? verse1, verse2, verse3, verse4, verse5, verse6, verse7;
  final String? chorus;

  const HlaBuDetail({
    super.key,
    this.title,
    this.verse1, this.verse2, this.verse3, this.verse4, this.verse5, this.verse6, this.verse7,
    this.chorus,
    this.zate,
  });

  @override
  State<HlaBuDetail> createState() => _HlaBuDetailState();
}

class _HlaBuDetailState extends State<HlaBuDetail> {
  double _fontSize = 20.0; // A tlangpi font size

  void _showFontSizeSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 90,
              right: 15,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ]),
                  child: StatefulBuilder(builder: (context, setPopupState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Cafang Ngan/Hme",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.text_fields,
                                color: Colors.white54, size: 14),
                            Expanded(
                              child: Slider(
                                value: _fontSize,
                                min: 12.0,
                                max: 36.0,
                                activeColor: Colors.blueAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (value) {
                                  setPopupState(() => _fontSize = value);
                                  setState(() => _fontSize = value);
                                },
                              ),
                            ),
                            const Icon(Icons.text_fields,
                                color: Colors.white, size: 24),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    List<String?> verses = [
      widget.verse1, widget.verse2, widget.verse3, widget.verse4,
      widget.verse5, widget.verse6, widget.verse7,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: Text(widget.title ?? 'Hla',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size, color: Colors.white70),
            onPressed: _showFontSizeSettings,
          ),
        ],
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
          child: SizedBox(
            width: double.infinity,
            child: widget.zate != null && widget.zate!.isNotEmpty
                ? Text(
              widget.zate!,
              style: TextStyle(fontSize: _fontSize, color: Colors.white.withOpacity(0.9), height: 1.7),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildLyrics(verses, widget.chorus),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLyrics(List<String?> verses, String? chorus) {
    List<Widget> widgets = [];
    int verseCount = 1;

    for (var verse in verses) {
      if (verse != null && verse.trim().isNotEmpty) {
        // --- Verse Section ---
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$verseCount. ",
                    style: TextStyle(color: Colors.deepPurpleAccent, fontSize: _fontSize - 2, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(verse.trim(),
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: _fontSize, height: 1.6)),
                ),
              ],
            ),
          ),
        );

        // --- Chorus Section ---
        if (chorus != null && chorus.trim().isNotEmpty) {
          widgets.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 10, bottom: 25, top: 5),
              padding: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 2.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CHO:",
                      style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(chorus.trim(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: _fontSize,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      )),
                ],
              ),
            ),
          );
        } else {
          widgets.add(const SizedBox(height: 15));
        }
        verseCount++;
      }
    }
    widgets.add(const SizedBox(height: 60)); // Tanglei ah hmun awng
    return widgets;
  }
}