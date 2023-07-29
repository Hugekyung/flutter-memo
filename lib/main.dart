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
      theme: ThemeData(primarySwatch: Colors.indigo),
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
  List<String> memos = []; // * 메모를 저장하는 리스트

  // * 메모 추가
  void _addMemo(String memo) {
    if (memo.isNotEmpty) {
      // * 값이 공백이 아닐 경우 메모 생성
      setState(() {
        memos.add(memo);
      });
    } else {
      // * 값이 공백이면 에러 모달
      _showErrorDialog(context);
    }
  }

  // * 메모 삭제
  void _deleteMemo(int index) {
    setState(() {
      memos.removeAt(index);
    });
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('내용이 없어요.'),
          content: const Text('메모 내용을 입력해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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
          final String memo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MemoComposeScreen()),
          );
          _addMemo(memo);
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
        title: const Text('Quick Memo'),
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
