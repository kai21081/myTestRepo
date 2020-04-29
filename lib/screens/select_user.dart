import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:provider/provider.dart';
import 'package:gameplayground/models/users.dart';

import 'main_menu.dart';

class SelectUserPage extends StatefulWidget {
  const SelectUserPage();

  @override
  State createState() => _SelectUserPageState();
}

class _SelectUserPageState extends State<SelectUserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UW Surface EMG Game', style: TextStyle(fontSize: 28)),
        centerTitle: true,
      ),
      body: _buildBodyCustomScrollView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
              context,
              MaterialPageRoute(
                  builder: (context) => _NewUserDialogue(),
                  fullscreenDialog: true));
//          showModalBottomSheet<void>(
//              context: context,
//              builder: (context) => _buildModalBottomSheet(context));
        },
        icon: const Icon(Icons.add),
        label: Text('New User'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  CustomScrollView _buildBodyCustomScrollView() {
    return CustomScrollView(
      slivers: [
        Consumer<SessionDataModel>(builder: (context, sessionDataModel, child) {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _UserListItem(sessionDataModel.getUsers()[index]);
            }, childCount: sessionDataModel.getUsers().length),
          );
        })
      ],
    );
  }
}

class _NewUserDialogue extends StatefulWidget {
  @override
  _NewUserDialogueState createState() => _NewUserDialogueState();
}

class _NewUserDialogueState extends State<_NewUserDialogue> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MediaQuery.removePadding(
        context: context,
        child: Scaffold(
            appBar: AppBar(title: Text('Add New User')),
            body: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _NewUserForm())));
  }
}

class _NewUserForm extends StatefulWidget {
  @override
  _NewUserFormState createState() {
    return _NewUserFormState();
  }
}

class _NewUserFormState extends State<_NewUserForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            TextFormField(
                textCapitalization: TextCapitalization.words,
                cursorColor: theme.cursorColor,
                validator: (value) {
                  return value.isEmpty ? 'Please enter some text.' : null;
                },
                decoration: InputDecoration(
                    filled: true,
                    icon: const Icon(Icons.person),
                    labelText: "User ID *'"),
                onSaved: (value) {
                  Provider.of<SessionDataModel>(context, listen: false)
                      .createUser(value);
                }),
            SizedBox(height: 24),
            FloatingActionButton.extended(
                label: Text('Save'),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    Navigator.pop(context);
                  }
                }),
          ],
        ));
  }
}

class _UserListItem extends StatelessWidget {
  final User _user;
  final _deleteFormKey = GlobalKey<FormState>();

  _UserListItem(this._user);

  @override
  Widget build(BuildContext context) {
    ColorScheme contextColorScheme = Theme.of(context).colorScheme;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
            color: contextColorScheme.background,
            child: ListTile(
              dense: false,
              isThreeLine: true,
              leading: Icon(Icons.android, size: 36),
              onTap: () {
                Provider.of<SessionDataModel>(context, listen: false)
                    .setUser(_user.id);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MainMenuPage()));
              },
              onLongPress: () {
                showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                          title: Text('Delete user ${_user.id}?'),
                          content: Form(
                              key: _deleteFormKey,
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                cursorColor: Theme.of(context).cursorColor,
                                validator: (value) {
                                  return value != '12345'
                                      ? 'Incorrect Password'
                                      : null;
                                },
                                decoration: InputDecoration(
                                    filled: true,
                                    icon: const Icon(Icons.lock),
                                    labelText: 'Admin Password'),
                              )),
                          actions: <Widget>[
                            FlatButton(
                                child: Text('Delete'),
                                onPressed: () {
                                  if (_deleteFormKey.currentState.validate()) {
                                    Provider.of<SessionDataModel>(context,
                                            listen: false)
                                        .deleteUser(_user.id);
                                    Navigator.of(context).pop();
                                  }
                                }),
                            FlatButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                })
                          ]);
                    });
              },
              title: Text(
                _user.id,
                style: TextStyle(
                    color: contextColorScheme.onBackground, fontSize: 24),
              ),
              subtitle:
                  Text('High Score: ${_user.highScore}\nLast Activity: Today'),
            )));
  }
}
