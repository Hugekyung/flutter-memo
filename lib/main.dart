import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

var logger = Logger();

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
  void _deleteMemo(Memo memo) {
    _showDeleteConfirmationDialog(context, memo);
  }

  // * 메모 업데이트
  void _editMemo(Memo memo) async {
    final Memo? editedMemo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MemoComposeScreen(memo: memo)),
    );

    if (editedMemo != null) {
      setState(() {
        // * 기존 메모 목록에서 동일한 메모를 찾고, 인덱스 추출
        final index = memos.indexWhere((element) => element == memo);
        if (index != -1) {
          memos[index] = editedMemo;
          _saveMemos(); // 메모가 수정될 때마다 저장
        }
      });
    }
  }

  // * 메모 삭제 여부 모달
  void _showDeleteConfirmationDialog(BuildContext context, Memo memo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Warning',
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
                _deleteConfirmed(memo);
                Navigator.of(context).pop('deleted');
              },
              child: const Text('deleted'),
            ),
          ],
        );
      },
    );
  }

  void _deleteConfirmed(Memo memo) {
    setState(() {
      logger.d('삭제 전 !!!');
      for (int i = 0; i < memos.length; i++) {
        final m = memos[i];
        logger.d(m.title);
      }

      for (int i = 0; i < memos.length; i++) {
        final m = memos[i];
        if (m.title == memo.title && m.content == memo.content) {
          memos.remove(m);
        }
      }

      logger.d('삭제 후 !!!');

      for (int i = 0; i < memos.length; i++) {
        final m = memos[i];
        logger.d(m.title);
      }
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedMemos.keys.map((key) {
            final memosOnDate = groupedMemos[key]!;
            final formattedDate = formatDate(key);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: memosOnDate
                      .map((memo) => ListTile(
                            title: Text(
                              memo.title.length > 20
                                  ? '${memo.title.substring(0, 21)}...'
                                  : memo.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () => _editMemo(memo),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteMemo(memo),
                            ),
                          ))
                      .toList(),
                ),
              ],
            );
          }).toList(),
        ),
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

// * 날짜 포맷 함수
String formatDate(String dateKey) {
  final dateParts = dateKey.split('-');
  final year = dateParts[0];
  final month = dateParts[1];
  final day = dateParts[2];
  return '$year년 $month월 $day일';
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
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            TextField(
              controller: _memoContent,
              maxLines: 10,
              decoration: const InputDecoration(hintText: 'Content'),
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
      'date': date
          .toIso8601String(), // ! Memo 데이터를 JsonEncoding을 하기 위해 DateTime의 타입을 String으로 변경
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
