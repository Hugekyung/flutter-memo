import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Memo> memos = []; // * 메모를 저장하는 리스트

  @override
  void initState() {
    super.initState();
    _loadMemos(); // * 앱 시작 시 저장된 메모 로드
  }

  void _loadMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? memosString = prefs.getStringList('memos');
    if (memosString != null) {
      setState(() {
        memos =
            memosString.map((json) => Memo.fromMap(jsonDecode(json))).toList();
      });
    }
  }

  void _saveMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> memosString =
        memos.map((memo) => jsonEncode(memo.toMap())).toList();
    prefs.setStringList('memos', memosString);
  }

  // * 메모 추가
  void _addMemo(String title, String content) {
    if (title.isNotEmpty) {
      setState(() {
        memos.add(Memo(title: title, content: content));
        _saveMemos();
      });
    } else if (title.isEmpty) {
      _showErrorDialog(context);
    }
  }

  // * 메모 삭제
  void _deleteMemo(int index) {
    _showDeleteConfirmationDialog(context, index);
  }

  // * 메모 업데이트
  void _editMemo(int index) async {
    final Memo? editedMemo = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MemoComposeScreen(memo: memos[index])),
    );

    if (editedMemo != null) {
      setState(() {
        memos[index] = editedMemo;
        _saveMemos(); // 메모가 수정될 때마다 저장
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
      _saveMemos();
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
          return Dismissible(
            key: Key(memos[index].title), // 유니크한 키로 메모의 내용을 사용합니다.
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _deleteMemo(index);
            },
            child: ListTile(
              title: Text(memos[index].title),
              onTap: () => _editMemo(index),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteMemo(index),
              ),
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
            _addMemo(memo.title, memo.content);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MemoComposeScreen extends StatefulWidget {
  final Memo? memo;

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
      _memoTitle.text = widget.memo!.title.isNotEmpty ? widget.memo!.title : '';
      _memoContent.text =
          widget.memo!.content.isNotEmpty ? widget.memo!.content : '';
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
                final Memo newMemo =
                    Memo(title: _memoTitle.text, content: _memoContent.text);
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

class Memo {
  String title;
  dynamic content;

  Memo({required this.title, required this.content});

  // `Memo` 인스턴스를 Map으로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }

  // Map으로부터 `Memo` 인스턴스를 생성하는 팩토리 메서드
  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      title: map['title'],
      content: map['content'],
    );
  }
}
