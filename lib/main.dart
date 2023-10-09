import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("note");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive DB Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final titleController = TextEditingController();
  final noteController = TextEditingController();

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    refreshItem();
  }

  final NoteBox = Hive.box("note");

  void refreshItem() {
    final data = NoteBox.keys.map((key) {
      final item = NoteBox.get(key);
      return {"key": key, "title": item["title"], "note": item["note"]};
    }).toList();

    setState(() {
      items = data.reversed.toList();
      print("_________*******${items.length}*******___________");
    });
  }

  Future<void> createItem(Map<String, dynamic> newItem) async {
    await NoteBox.add(newItem);
    // print("-----------***********data count : ${NoteBox.length}*******-----------");
    refreshItem();
  }

  Future<void> updateItem(int itemKey, Map<String,dynamic> item)async{
    await NoteBox.put(itemKey,item);
    refreshItem();
  }

  Future<void> deleteItem(int itemKey) async{
    await NoteBox.delete(itemKey);
    refreshItem();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Center(child: Text("Note Lost in Void")))
    );
  }

  void showForm(BuildContext ctx, int? itemKey) async {

    if(itemKey != null ){
      final existingItem =
          items.firstWhere((element) => element["key"]== itemKey);
      titleController.text=existingItem['title'];
      noteController.text=existingItem['note'];
    }
    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 15,
                left: 15,
                right: 15,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Title",
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: "Note",
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {

                      if(titleController.text.isEmpty && noteController.text.isEmpty){
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(' Error'),
                                content: Text('Both Title & Note can\'t be empty'),
                                actions: <Widget>[

                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); //close Dialog
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            });
                      }else{
                        if(itemKey == null)
                          createItem({
                            "title": titleController.text,
                            "note": noteController.text
                          });

                        if(itemKey != null)
                          updateItem(itemKey,{
                            "title": titleController.text,
                            "note": noteController.text
                          });
                        titleController.text = "";
                        noteController.text = "";
                        Navigator.of(context).pop();
                      }


                    },
                    child: Text(itemKey == null ? "Create New" : "Update"),
                  ),
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Note X"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final currentItem = items[index];
          return Card(
            color: Colors.deepOrange.shade100,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(
                currentItem['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(currentItem['note'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => showForm(context, currentItem["key"]),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => deleteItem(currentItem["key"]),
                    icon: const Icon(Icons.delete),
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(context, null),
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
