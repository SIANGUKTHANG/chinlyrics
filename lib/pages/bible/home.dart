import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive import tuah a hau
// Na data laaknak file taktak he va remh tthan te
import 'package:chinlyrics/pages/bible/service.dart';

import 'mark.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  BiblePageState createState() => BiblePageState();
}

class BiblePageState extends State<BiblePage> {
  List books = [];
  bool loading = false;

  Map? _selectedBook;
  int _selectedChapterIndex = 0;
  String? _selectedVerse;

  // ======== A THAR: MULTIPLE SELECT CAAH ========
  Set<String> _selectedMultiVerses = {};

  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    setState(() => loading = true);
    try {
      var bible = await BibleService.loadBible();
      setState(() {
        books = bible;
        if (books.isNotEmpty) {
          _selectedBook = books[0];
          _selectedChapterIndex = 0;
        }
        loading = false;
      });
    } catch (e) {
      print("Bible laaknak ah palhnak: $e");
      setState(() => loading = false);
    }
  }

  // ======== A THAR: HIVE AH SAVE TUAHNAK ========
  void _saveMarksToHive() {
    var box = Hive.box('marksBox');

    List chapters = _selectedBook!['chapters'];
    Map currentChapterData = chapters[_selectedChapterIndex];
    String chapterNumber = currentChapterData.keys.first;
    Map versesMap = currentChapterData[chapterNumber] as Map;

    for (String vKey in _selectedMultiVerses) {
      String verseText = versesMap[vKey] ?? "";
      String bookName = _selectedBook!['name'];

      // Unique ID pakhat kan pek lai (Tahchunhnak: Genesis_1_1)
      String uniqueId = "${bookName}_${chapterNumber}_$vKey";

      box.put(uniqueId, {
        'book': bookName,
        'chapter': chapterNumber,
        'verse': vKey,
        'text': verseText,
        'timestamp': DateTime.now().toIso8601String(), // Save tuah lio caan
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${_selectedMultiVerses.length} cang Mark tuah a si cang!"),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _selectedMultiVerses.clear(); // Save dih in thimmi phiat tthan
    });
  }

  // Font Size Settings Dialog (A hlan bantuk te khan)
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
    bool isMultiMode = _selectedMultiVerses.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // Multiple thim lio a si ahcun a nambat a lang lai
        title: Text(
          isMultiMode ? "${_selectedMultiVerses.length} Thimmi" : "Lai Bible Thiang",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: isMultiMode
            ? IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _selectedMultiVerses.clear()),
        )
            : null,
        actions: [
          // ======== MULTIPLE THIM LIO A SI AHCUN "MARK" BUTTON A LANG LAI ========
          if (isMultiMode)
            TextButton.icon(
              onPressed: _saveMarksToHive,
              icon: const Icon(Icons.bookmark_add, color: Colors.blueAccent),
              label: const Text("Mark", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.text_fields, color: Colors.white54),
              onPressed: () {
                 _showFontSizeSettings();
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmarks, color: Colors.white54),
              onPressed: () {
                // Mark Page ah kalnak
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MarkPage()));
              },
            ),
          ]
        ],
        // Bottom Dropdown (A hlan bantuk te khan)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                  bottom: BorderSide(color: Colors.white12, width: 1),
                )),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildBookDropdown()),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _buildChapterDropdown()),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _buildVerseDropdown()),
              ],
            ),
          ),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _selectedBook == null
          ? const Center(child: Text("Data a um lo", style: TextStyle(color: Colors.white54)))
          : _buildVersesList(),
    );
  }

  Widget _buildBookDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Map>(
        dropdownColor: Colors.grey[900],
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        value: _selectedBook,
        items: books.map<DropdownMenuItem<Map>>((book) {
          return DropdownMenuItem<Map>(
            value: book,
            child: Text(
              book['name'],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (Map? newBook) {
          if (newBook != null) {
            setState(() {
              _selectedBook = newBook;
              _selectedChapterIndex =
              0; // Cauk thar a si ahcun Dal 1nak ah a kir lai
              _selectedVerse = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildChapterDropdown() {
    if (_selectedBook == null) return const SizedBox();
    List chapters = _selectedBook!['chapters'] ?? [];

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        dropdownColor: Colors.grey[900],
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        value: _selectedChapterIndex,
        items: List.generate(chapters.length, (index) {
          // Dal nambat laknak
          String chapterNum = chapters[index].keys.first;
          return DropdownMenuItem<int>(
            value: index,
            child: Text(
              "Dal $chapterNum",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }),
        onChanged: (int? newIndex) {
          if (newIndex != null) {
            setState(() {
              _selectedChapterIndex = newIndex;
              _selectedVerse = null; // Dal thar a si ahcun verse thimmi phiat
            });
          }
        },
      ),
    );
  }

  Widget _buildVerseDropdown() {
    if (_selectedBook == null) return const SizedBox();
    List chapters = _selectedBook!['chapters'] ?? [];
    if (chapters.isEmpty) return const SizedBox();

    Map currentChapterData = chapters[_selectedChapterIndex];
    String chapterNumber = currentChapterData.keys.first;
    Map versesMap = currentChapterData[chapterNumber] as Map;
    List verseKeys = versesMap.keys.toList();

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        dropdownColor: Colors.grey[900],
        isExpanded: true,
        hint: const Text("Cang",
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        value: _selectedVerse,
        items: verseKeys.map<DropdownMenuItem<String>>((vKey) {
          return DropdownMenuItem<String>(
            value: vKey.toString(),
            child: Text(
              "Cang $vKey",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (String? newVerse) {
          setState(() {
            _selectedVerse = newVerse;
          });
        },
      ),
    );
  }

  // ================= CA RELNAK LIST (Remhmi) =================
  Widget _buildVersesList() {
    List chapters = _selectedBook!['chapters'] ?? [];
    if (chapters.isEmpty) return const Center(child: Text("Data a um lo"));

    Map currentChapterData = chapters[_selectedChapterIndex];
    String chapterNumber = currentChapterData.keys.first;
    Map versesMap = currentChapterData[chapterNumber] as Map;
    List verseKeys = versesMap.keys.toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemCount: verseKeys.length,
      itemBuilder: (context, index) {
        String verseNo = verseKeys[index];
        String verseText = versesMap[verseNo] ?? "";

        bool isSingleHighlighted = _selectedVerse == verseNo;
        // Hi cang hi Mark dingah thimmi chungah a tel maw?
        bool isMultiSelected = _selectedMultiVerses.contains(verseNo);

        return GestureDetector(
          onTap: () {
            setState(() {
              // Multiple thim lio a si ahcun, thimmi chap/hloh
              if (_selectedMultiVerses.isNotEmpty) {
                if (isMultiSelected) {
                  _selectedMultiVerses.remove(verseNo);
                } else {
                  _selectedMultiVerses.add(verseNo);
                }
              } else {
                // A hlan i single tap highlight tuahnak
                _selectedVerse = isSingleHighlighted ? null : verseNo;
              }
            });
          },
          // ======== SAUPI HMEH TIKAH MULTI-SELECT MODE ON ========
          onLongPress: () {
            setState(() {
              if (isMultiSelected) {
                _selectedMultiVerses.remove(verseNo);
              } else {
                _selectedMultiVerses.add(verseNo);
                _selectedVerse = null; // Single highlight phiat
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Multiple thim lio ahcun rong a dang in a lang lai (Tahchunhnak: BlueAccent)
              color: isMultiSelected
                  ? Colors.blueAccent.withOpacity(0.2)
                  : isSingleHighlighted
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMultiSelected
                    ? Colors.blueAccent.withOpacity(0.5)
                    : isSingleHighlighted
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "$verseNo    ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMultiSelected ? Colors.blueAccent : (isSingleHighlighted ? Colors.redAccent : Colors.blueAccent),
                        fontSize: _fontSize),
                  ),
                  TextSpan(
                    text: verseText,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: _fontSize + 2,
                        height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}