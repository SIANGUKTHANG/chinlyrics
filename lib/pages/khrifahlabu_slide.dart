import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LyricsViewer extends StatefulWidget {
  final String? title;
  final String? endingChorus;
  final String? verse1;
  final String? verse2;
  final String? verse3;
  final String? verse4;
  final String? verse5;
  final String? verse6;
  final String? verse7;
  final String? chorus;

  const LyricsViewer({
    super.key,
    this.title,
    this.endingChorus,
    this.verse1,
    this.verse2,
    this.verse3,
    this.verse4,
    this.verse5,
    this.verse6,
    this.verse7,
    this.chorus,
  });

  @override
  LyricsViewerState createState() => LyricsViewerState();
}

class LyricsViewerState extends State<LyricsViewer> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final FocusNode _focusNode = FocusNode(); // FocusNode to capture key events


  @override
  void initState() {
    super.initState();
    // Lock orientation to landscape when LyricsViewer is shown
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    // Optionally hide the status bar (if you want full-screen mode)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Request focus after the widget has been fully initialized
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  void dispose() {
    // Unlock orientation when the screen is disposed (when navigating away)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
 
    ]);
    // Optionally show the status bar again when leaving the page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the list of lyrics pages dynamically
    List<Widget> lyricsPages = [];

    // Check if verse and chorus should be displayed together
    if (widget.verse1 != null) {
      lyricsPages.add(_buildVerse(widget.title,'Title', context));
      lyricsPages.add(_buildVerse(widget.verse1,'verse', context));
      if (widget.chorus != null) lyricsPages.add(_buildChorus(context));
    }
    if (widget.verse2 != null || widget.verse2 != '') {
      lyricsPages.add(_buildVerse(widget.verse2,'verse', context));
      if (widget.chorus != null ) lyricsPages.add(_buildChorus(context));
    }
    if (widget.verse3 != null || widget.verse3 != '') {
      lyricsPages.add(_buildVerse(widget.verse3,'verse', context));
      if (widget.chorus != null) lyricsPages.add(_buildChorus(context));
    }
    if (widget.verse4 != null || widget.verse4 != '') {
      lyricsPages.add(_buildVerse(widget.verse4,'verse', context));
      if (widget.chorus != null) lyricsPages.add(_buildChorus(context));
    }
    if (widget.verse5 != null || widget.verse5 != '') {
      lyricsPages.add(_buildVerse(widget.verse5,'verse', context));
      if (widget.chorus != null) lyricsPages.add(_buildChorus(context));
    }
    if (widget.verse6 != null || widget.verse6 != '') {
      lyricsPages.add(_buildVerse(widget.verse6,'verse', context));
      if (widget.chorus != null) lyricsPages.add(_buildChorus(context));
    }
    if (widget.verse7 != null|| widget.verse7 != '') {
      lyricsPages.add(_buildVerse(widget.verse7,'verse', context));
      if (widget.chorus != null) lyricsPages.add(_buildChorus(context));
    }

    if(widget.endingChorus !=null || widget.endingChorus !=''){
      lyricsPages.add(_buildVerse(widget.endingChorus,'Ending', context));
    }

    return Scaffold(

      body: Column(
        children: [

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: (KeyEvent event) {
                  // Handle key events for navigation
                  if (event.runtimeType == KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      // Move to next page
                      if (_currentPage < lyricsPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      // Move to previous page
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                      // Move to next page
                      if (_currentPage < lyricsPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                      // Move to previous page
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: lyricsPages.length,

                  onPageChanged: (int index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: lyricsPages[index],
                    );
                  },
                ),
              ),
            ),
          ),
          // Display how many slides are left
          Text(
            ' ${_currentPage+1} / ${lyricsPages.length}',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  double getFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.04; // 5% of screen width
  }

  Widget _buildVerse(String? verse,String? type, BuildContext context) {
    if (verse == null || verse == '') return Container();

    String cleanLyrics = removeChords(verse);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           Text('( $type )',style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.orange),),
            Text(
              cleanLyrics,
              style: GoogleFonts.actor(
                fontSize: getFontSize(context),
                color: Colors.white70,
               fontWeight: FontWeight.w700
              ),

              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChorus(BuildContext context) {
    if (widget.chorus == null || widget.chorus == '') return Container();

    String cleanChorus = removeChords(widget.chorus!);

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text('( chorus )',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.orange),),

            Text(
              cleanChorus,
              style: GoogleFonts.actor(
                  fontSize: getFontSize(context),
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,

              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  String removeChords(String text) {
    // Removes [C], [Am], [G#], [Fmaj7], [Dsus4], etc.
    final RegExp chordPattern = RegExp(r'\[[^\]]+\]');
    return text.replaceAll(chordPattern, '').trim();
  }

}
