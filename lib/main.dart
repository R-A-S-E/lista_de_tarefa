import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController(); //formulario
  List _toDoList = []; //lista
  Map<String, dynamic> _lastRemoved; //recuperar removido
  int _lastRemovedPos; //posição da remoção

//para recuperar oq foi gravado
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  //para salvar os dados do map
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  //ordenação pelo bool
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Tarefas"),
          backgroundColor: Colors.black38,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    //formulario
                    child: TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.black)),
                    ),
                  ),
                  //butão
                  ElevatedButton(
                    onPressed: _addToDo,
                    child: Text(
                      "ADD",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.black38,
                    ),
                  )
                ],
              ),
            ),
            //para utilizar só que está na tela
            Expanded(
                //ultização do refresh para ordenar
                child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            )),
          ],
        ));
  }

  //function para widget que vão ser listado
  Widget buildItem(context, index) {
    //em função de excluir o objeto
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction:
          DismissDirection.startToEnd, //de onde deslizar para excluir o objeto
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]), //listagem dos objetos
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"]
              ? Icons.check
              : Icons.error), //icones para true or false
        ),
        //para salvar que está true or false
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      //desfazer a excluição do objeto
      onDismissed: (direction) {
        //É feito um armazenamento no mapa(para poder excluir)onde faz aparecer um barra de mensagem
        //onde dura 4 segundos para desfazer o processo de excluição
        setState(() {
          //processo de armazenamento
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          //listagem da mensagem
          final snack = SnackBar(
            content: Text("Tarefa \'${_lastRemoved["title"]}\' removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                //se for pressionado desfaz
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            //tem duração de 4 seg e depois desaparece
            duration: Duration(seconds: 4),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  //diretorio de json offline para armazenamento
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  //save do diretorio offline
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  //leitura do diretorio offline
  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
