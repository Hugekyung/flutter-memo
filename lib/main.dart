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
      title: 'Good Memos',
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
  Map<String, List<Memo>> groupedMemos = {};
  List<Memo> memos = []; // * 메모를 저장하는 리스트
  Memo? deletedMemo;

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

      // 날짜별로 그룹화해서 저장합니다.
      groupedMemos = {};
      for (var memo in memos) {
        final String groupedKey =
            '${memo.date.year.toString()}-${memo.date.month.toString()}-${memo.date.day.toString()}';
        groupedMemos[groupedKey] = groupedMemos[memo.date] ?? [];
        groupedMemos[groupedKey]!.add(memo);
      }
    }
  }

  void _saveMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> memosString =
        memos.map((memo) => jsonEncode(memo.toMap())).toList();
    prefs.setStringList('memos', memosString);
  }

  // * 메모 추가
  void _addMemo(String title, String content, DateTime date) {
    if (title.isNotEmpty) {
      setState(() {
        final memo = Memo(title: title, content: content, date: date);
        final String groupedKey =
            '${memo.date.year.toString()}-${memo.date.month.toString()}-${memo.date.day.toString()}';
        List<Memo> memosOnDate =
            groupedMemos[date] ?? []; // * 해당 날짜로 그룹화된 메모 리스트
        memosOnDate.add(memo); // * 날짜별 메모 리스트에 저장
        groupedMemos[groupedKey] = memosOnDate; // * 그룹화된 메모 리스트에 저장
        memos.add(memo); // * 전체 날짜 메모 리스트에 저장
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
          title: const Text(
            '경고',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to delete this memo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop('cancel');
              },
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteConfirmed(index);
                Navigator.of(context).pop('deleted');
              },
              child: const Text('deleted'),
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
          title: const Text('There is no content.'),
          content: const Text('Please enter the memo content.'),
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
        title: const Text('HeyMemo'),
      ),
      body: ListView.builder(
        itemCount: memos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              memos[index].title.length > 20
                  ? '${memos[index].title.substring(0, 21)}...'
                  : memos[index].title,
              style:
                  const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
            ),
            onTap: () => _editMemo(index),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
              ),
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
            _addMemo(memo.title, memo.content, memo.date);
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
  late DateTime
      _writedDate; // ! late키워드는 값의 초기화를 뒤로 미루지만, 개발자가 null을 실수로 사용하는것을 막아준다

  @override
  void initState() {
    super.initState();
    _writedDate = widget.memo?.date ?? DateTime.now();
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
              maxLines: 10,
              decoration: const InputDecoration(hintText: '내용을 적어주세요'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final Memo newMemo = Memo(
                  title: _memoTitle.text,
                  content: _memoContent.text,
                  date: _writedDate,
                );
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
  DateTime date;

  Memo({required this.title, required this.content, required this.date});

  // `Memo` 인스턴스를 Map으로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
    };
  }

  // Map으로부터 `Memo` 인스턴스를 생성하는 팩토리 메서드
  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
        title: map['title'],
        content: map['content'],
        date: map['date'] != null
            ? DateTime.parse(map['date'])
            : DateTime.now() // date가 null인 경우 현재 시간으로 초기화;
        );
  }
}
