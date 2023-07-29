import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeMOMO',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MemoListScreen(),
    );
  }
}

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  _MemoListScreenState createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  List<String> memos = [];

  void _addMemo(String memo) {
    setState(() {
      memos.add(memo);
    });
  }

  void _deleteMemo(int index) {
    setState(() {
      memos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeMoMo'),
      ),
      body: ListView.builder(
        itemCount: memos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(memos[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteMemo(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final memo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MemoComposeScreen()),
          );
          if (memo != null) {
            _addMemo(memo);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MemoComposeScreen extends StatelessWidget {
  final TextEditingController _memoController = TextEditingController();

  MemoComposeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Memo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _memoController,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Write something...'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final newMemo = _memoController.text;
                Navigator.pop(context, newMemo);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
