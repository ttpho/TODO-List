import 'package:flutter/material.dart';

abstract class TextItem {
  String title;
  final int createDate = DateTime.now().millisecondsSinceEpoch;
}

abstract class CheckItem extends TextItem {
  bool isChecked = false;
}

class BaseReorderableList extends StatefulWidget {
  final List<TextItem> listCheckItem;
  final Function onChanged;
  final bool hasDismissible;

  BaseReorderableList(
      {Key key,
      @required this.listCheckItem,
      this.onChanged,
      this.hasDismissible = false})
      : super(key: key);

  @override
  BaseReorderableListState createState() => BaseReorderableListState();
}

class BaseReorderableListState extends State<BaseReorderableList> {
  List<TextItem> _listCheckItem;
  var _length = 0;
  TextItem _itemRemoved;
  int _indexItemRemoved = -1;

  @override
  void initState() {
    super.initState();
    _length = widget.listCheckItem.length;
    _listCheckItem = widget.listCheckItem;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      children: _listCheckItem
          .map((item) => widget.hasDismissible
              ? _makeDismissible(item, new Key(item.hashCode.toString()))
              : _makeItem(item, new Key(item.hashCode.toString())))
          .toList(),
      onReorder: (int start, int current) {
        _onReorder(
            start,
            current,
            () => setState(() {
                  if (widget.onChanged == null) return;
                  widget.onChanged(_listCheckItem);
                }));
      },
    );
  }

  Widget _makeItem(final TextItem item, final Key key) => (item is CheckItem)
      ? _makeCheckboxListTile(item, key)
      : _makeText(item, key);

  Widget _makeCheckboxListTile(final CheckItem item, final Key key) {
    return CheckboxListTile(
      key: key,
      value: item.isChecked,
      secondary: Icon(Icons.drag_handle),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(item.title),
      onChanged: (bool value) {
        if (value == item.isChecked) return;
        item.isChecked = value;
        setState(() {});
      },
    );
  }

  Widget _makeText(final TextItem item, final Key key) => ListTile(
        key: key,
        title: Text(item.title),
        trailing: Icon(Icons.drag_handle),
      );

  _onReorder(final int start, final int current, final Function onCompleted) {
    if (current > _length || start == current) return;

    // dragging from top to bottom
    if (start < current) {
      final int end = current - 1;
      final TextItem startItem = _listCheckItem[start];
      int i = 0;
      int local = start;
      do {
        if (local + 1 >= _length) return;
        _listCheckItem[local] = _listCheckItem[++local];
        i++;
      } while (i < end - start);
      _listCheckItem[end] = startItem;

      onCompleted();
      return;
    }

    // dragging from bottom to top
    if (start > current) {
      final TextItem startItem = _listCheckItem[start];
      for (int i = start; i > current; i--) {
        _listCheckItem[i] = _listCheckItem[i - 1];
      }
      _listCheckItem[current] = startItem;
    }
    onCompleted();
  }

  Widget _makeDismissible(final TextItem item, final Key key) => Dismissible(
        key: Key("Dismissible" + key.toString()),
        onDismissed: (direction) {
          _itemRemoved = item;
          _indexItemRemoved = _listCheckItem.lastIndexOf(item);
          setState(() {
            _listCheckItem.remove(item);
          });
          Scaffold.of(context).showSnackBar(_makeSnackBar(item));
        },
        background: Container(
          color: Theme.of(context).accentColor,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                "Remove",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        child: _makeItem(item, key),
      );

  Widget _makeSnackBar(final TextItem item) {
    final snackBar = SnackBar(
      content: Text(item.title + " is removed"),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (_itemRemoved == null || _indexItemRemoved == -1) return;
          setState(() {
            _listCheckItem.insert(_indexItemRemoved, _itemRemoved);
          });
        },
      ),
    );

    return snackBar;
  }
}
