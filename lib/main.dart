import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _todoList = [];

  final _todoController = TextEditingController();

  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos;

  @override
  void initState(){
    super.initState();
    _readData().then((data){
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }


  void _addTodo(){
   setState(() {
     Map<String, dynamic> newToDo = Map();
     newToDo["title"] = _todoController.text;
     _todoController.text = "";
     newToDo["ok"] = false;

     _todoList.add(newToDo);
     _saveData();
   });
  }

  Future<Null> _refresh() async {
    // Faz esperar 1 segundo
    await Future.delayed(Duration(seconds: 1));

    setState(() {

    _todoList.sort((a,b){
      if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
    });
    _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                //Com o expanded evitamos o erro de "largura infinita"
                //E fazemos com que nosso TextField ocupe a maior quantidade de area possivel
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  onPressed: _addTodo,
                  color: Colors.blueAccent,
                  child: Text("Adicionar"),
                  textColor: Colors.white,
                )
              ],
            ),
          ),
          Expanded(
            // ListView é um widget que podemos fazer uma lista
            //o builder, é um construtor que vai permitir criar essa lista
            //Conforme com rodando ela, só cria elementos conforme são mostrados
            child: RefreshIndicator(onRefresh: _refresh,
                child:  ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItem))
          )
        ],
      ),
    );
  }

Widget buildItem(BuildContext context, int index) {
    //Reponsavel por poder arrastar o widget para o lado
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ?
          Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _todoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida !"),
            action: SnackBarAction(label: "Desfazer",
                onPressed: (){
              setState(() {
                _todoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
                }
                ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });

      },
    );
}


  //Sempre que tratamos de gravar ou ler dados, precisamos usar o async e await
  //Pois não ocorre automaticamente, é necessário esperar um pouco

  Future<File> _getFile() async {
    // Vai pegar o diretorio onde posso armazenar
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {

    // Converte o dado para json
    String data = json.encode(_todoList);
    //Pego o arquivo
    final file = await _getFile();
    return file.writeAsString(data);// E escrevo no arquivo
  }

  Future<String> _readData() async {
    try{
      final file = await _getFile();

      //Faço uma leitura do meu arquivo como string
      return file.readAsString();
    }catch (err){
      return null;
    }
  }


}


