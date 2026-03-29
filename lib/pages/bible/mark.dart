import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MarkPage extends StatelessWidget {
  const MarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Ka Mark Mi Pawl", style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      // ValueListenableBuilder hman tikah Hive ah thlennak a um paoh ah a thar in a lang colh lai
      body: ValueListenableBuilder(
        valueListenable: Hive.box('marksBox').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text("Mark tuahmi a um rih lo.", style: TextStyle(color: Colors.white54)),
            );
          }

          // Data lak le reverse tuah (A thar bik a cunglei ah a lang nakhnga)
          List marks = box.values.toList().reversed.toList();
          List keys = box.keys.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            physics: const BouncingScrollPhysics(),
            itemCount: marks.length,
            itemBuilder: (context, index) {
              var mark = marks[index];
              var key = keys[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cauk, Dal le Cang
                        Text(
                          "${mark['book']} ${mark['chapter']}:${mark['verse']}",
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        // Hloh khawhnak (Delete)
                        GestureDetector(
                          onTap: () {
                            box.delete(key);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Delete tuah a si cang."), backgroundColor: Colors.redAccent, duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Hla Bia (Bible text)
                    Text(
                      mark['text'],
                      style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}