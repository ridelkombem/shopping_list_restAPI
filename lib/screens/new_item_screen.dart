import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/categories.dart';
import '../models/grocery_item.dart';
import '../models/category.dart';


class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _form = GlobalKey<FormState>();
  final _quantityFocusNode = FocusNode();
  var _enteredQuantity = 1;
  var _enteredTitle = '';
  Category _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;


  void _saveItem() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    } else if (isValid) {
      _form.currentState!.save();
      setState(() {
        _isSending = true;
      });
    }

    final url = Uri.https(
        'grocerylist-d72bb-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _enteredTitle,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title
        }));

    // print(response.body);
    // print(response.statusCode);

    final Map<String, dynamic> resData = jsonDecode(response.body);

    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop(GroceryItem(
        id: resData['name'],
        name: _enteredTitle,
        quantity: _enteredQuantity,
        category: _selectedCategory));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a new item')),
      body: Form(
        key: _form,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              TextFormField(
                  maxLength: 50,
                  initialValue: _enteredTitle,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  onSaved: (newValue) {
                    _enteredTitle = newValue.toString();
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50) {
                      return 'Must be between 1 and 50 characters!';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_quantityFocusNode);
                  }),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                        initialValue: _enteredQuantity.toString(),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        focusNode: _quantityFocusNode,
                        onSaved: (newValue) {
                          _enteredQuantity = int.parse(newValue.toString());
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid quantity';
                          }
                          if (int.tryParse(value)! <= 0) {
                            return 'Please enter a number greater than 0';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {}),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                                value: category.value,
                                //for the category with the title and color
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: category.value.color,
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Text(category.value.title),
                                  ],
                                ))
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedCategory = value;
                          });
                        }),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: _isSending
                          ? null
                          : () {
                              _form.currentState!.reset();
                            },
                      child: const Text('Reset')),
                  ElevatedButton(
                      onPressed: _isSending ? null : _saveItem,
                      child: _isSending ? const SizedBox(height: 16,width: 16,child: CircularProgressIndicator(),) : const Text('Add Item'))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
