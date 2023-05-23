import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/grocery_item.dart';
import '../screens/new_item_screen.dart';
import '../data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final url = Uri.https(
        'grocerylist-d72bb-default-rtdb.firebaseio.com', 'shopping-list.json');

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });

        return;
      }

      final Map<String, dynamic> listData = jsonDecode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries.firstWhere(
            (catItem) => catItem.value.title == item.value['category']);
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category.value));
      }
      setState(() {
        groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
        context, MaterialPageRoute(builder: (ctx) => const NewItemScreen()));

    // loadItems(); this get request can be replaced simply by passing the data through the navigation. pop context and receiving it as a newItem

    if (newItem == null) {
      return;
    } else {
      setState(() {
        groceryItems.add(newItem);
      });
    }
  }

  void _deleteItem(GroceryItem item) async {
    final index = groceryItems.indexOf(item);

    setState(() {
      groceryItems.remove(item);
    });

    final url = Uri.https('grocerylist-d72bb-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text(
        'No Grocery Items Found.Start adding some!',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );

    if (_isLoading) {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groceryItems.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: ((context, i) => Dismissible(
              direction: DismissDirection.endToStart,
              key: ValueKey(groceryItems[i]),
              onDismissed: (direction) {
                _deleteItem(groceryItems[i]);
              },
              child: ListTile(
                title: Text(groceryItems[i].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: groceryItems[i].category.color,
                ),
                trailing: Text(groceryItems[i].quantity.toString()),
              ),
            )),
      );
    }

    if (_error != null) {
      mainContent = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,
            )
          ],
          title: const Text('Your Groceries'),
        ),
        body: mainContent);
  }
}
