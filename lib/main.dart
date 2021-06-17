import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lazy Load ScrollablePositionedList Example',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: LazyLoadSPL(),
    );
  }
}

class LazyLoadSPL extends StatefulWidget {
  const LazyLoadSPL({ Key? key }) : super(key: key);

  @override
  _LazyLoadSPLState createState() => _LazyLoadSPLState();
}

class _LazyLoadSPLState extends State<LazyLoadSPL> {
  List<Map> _items = [];

  int _page = 1;
  int _limit = 10;
  List<Map> _loadedItems = [];

  bool _isLoading = false;

  ItemScrollController _itemScrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await _loadAllData();
      _loadPerPage();
      _setListener();
    });
  }

  Future<void> _loadAllData() async {
    // load dummy data from asset
    // contains 100 items of dummy post
    String data = await DefaultAssetBundle.of(context).loadString("assets/data.json");
    final result = json.decode(data);

    if (result is List) {
      _items = result.map((item) => item as Map).toList();
    }
  }

  void _setListener() {
    _itemPositionsListener.itemPositions.addListener(() {
      final value = _itemPositionsListener.itemPositions.value;

      int count = _loadedItems.length;
      ItemPosition last = value.last;
      print('Count: $count, Last: ${last.index}');

      bool isAtBottom = last.index == count - 1;

      // load data from the next page if at the bottom
      if (isAtBottom) {
        _loadPerPage();
      }
    });
  }

  // lazy load data per page
  // from _items to _loadedItems
  void _loadPerPage() {
    if (!_isLoading) {
      _isLoading = true;

      int start = (_page - 1) * _limit;
      int end = _page * _limit;
      List<Map> _pageItems = _items.sublist(start, end);

      setState(() {
        _loadedItems.addAll(_pageItems);
      });

      _isLoading = false;
      _page = _page + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loadedItems.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ScrollablePositionedList.builder(
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                itemCount: _loadedItems.length,
                itemBuilder: (_, i) => Card(
                  margin: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 18,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8, 
                      horizontal: 12,
                    ),
                    title: Text(_loadedItems[i]['title']),
                    subtitle: Text(_loadedItems[i]['body']),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Scroll to Index 6'),
        onPressed: () {
          _itemScrollController.scrollTo(
            index: 6, 
            duration: Duration(milliseconds: 250),
          );
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
