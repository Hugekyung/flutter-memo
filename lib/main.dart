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
  List<List<String>> memos = []; // * 메모를 저장하는 리스트

  // * 메모 추가
  void _addMemo(List<String> memo) {
    if (memo[0].isNotEmpty) {
      // * 제목이 공백이 아닐 경우 메모 생성
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
    _showDeleteConfirmationDialog(context, index);
  }

  // * 메모 업데이트
  void _editMemo(int index) async {
    final editedMemo = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MemoComposeScreen(memo: memos[index])),
    );
    if (editedMemo != null) {
      setState(() {
        memos[index] = editedMemo;
      });
    }
  }

  // * 메모 삭제 여부 모달
  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('경고'),
          content: const Text('정말로 이 메모를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _deleteConfirmed(index);
                Navigator.of(context).pop();
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _deleteConfirmed(int index) {
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
              child: const Icon(Icons.check),
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
            title: Text(memos[index][0]),
            onTap: () => _editMemo(index),
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
            MaterialPageRoute(builder: (context) => const MemoComposeScreen()),
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

class MemoComposeScreen extends StatefulWidget {
  final List<String>? memo;

  const MemoComposeScreen({super.key, this.memo});

  @override
  _MemoComposeScreenState createState() => _MemoComposeScreenState();
}

class _MemoComposeScreenState extends State<MemoComposeScreen> {
  final TextEditingController _memoTitle = TextEditingController();
  final TextEditingController _memoContent = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.memo != null) {
      _memoTitle.text = widget.memo!.isNotEmpty ? widget.memo![0] : '';
      _memoContent.text = widget.memo!.isNotEmpty ? widget.memo![1] : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo != null ? 'Edit Memo' : 'Quick Memo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _memoTitle,
              maxLines: 1,
              decoration: const InputDecoration(hintText: '제목'),
            ),
            TextField(
              controller: _memoContent,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '내용을 적어주세요'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final newMemo = [_memoTitle.text, _memoContent.text];
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
