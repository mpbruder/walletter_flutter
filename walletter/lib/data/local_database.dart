import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:walletter/model/transactionModel.dart';

class DatabaseLocalServer {
  /**
   * Criando Singletion
   * 
   * Apenas um objeto da classe pode ser instanciado, ou seja, ela sabe tudo o que acontecerá no DB.
   */
  static DatabaseLocalServer helper = DatabaseLocalServer._createInstance();
  DatabaseLocalServer._createInstance();

  static Database _database;

  String transactionTable = "transactions_table";
  String colId = "id";
  String colType = "type";
  String colValue = "value";
  String colDate = "date";
  String colDescription = "description";

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future<Database> initializeDatabase() async {
    // Salvar DB na memoria interna
    Directory directory = await getApplicationDocumentsDirectory();
    // Nome e caminho do Arquivo SQLite
    String path = directory.path + "transactions.db";

    Database transactionsDatabase = await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
    return transactionsDatabase;
  }

  //  CREATE TABLE DB
  _createDb(Database db, int newVersion) async {
    await db.execute(
      "CREATE TABLE $transactionTable ($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colValue TEXT, $colDate TEXT, $colDescription TEXT)",
    );
  }

  // INSERT ON DB
  Future<int> insertTransaction(TransactionForm income) async {
    Database db = await this.database;
    int result = await db.insert(transactionTable, income.toMap());
    notify();
    return result;
  }

  // QUERY: Retorna tudo que tem no banco.
  getTransactionList() async {
    Database db = await this.database;
    var transactionsMapList =
        await db.rawQuery("SELECT * FROM $transactionTable");
    List<TransactionForm> transactionsList = [];
    List<int> idList = [];
    for (int i = 0; i < transactionsMapList.length; i++) {
      TransactionForm transaction =
          TransactionForm.fromMap(transactionsMapList[i]);
      transactionsList.add(transaction);
      idList.add(transactionsMapList[i]["id"]);
    }
    return [transactionsList, idList];
  }

  // DELETE
  deleteTransaction(int transactionId) async {
    Database db = await this.database;
    int result = await db.rawDelete(
      "DELETE FROM $transactionTable WHERE $colId=$transactionId",
    );
    notify();
    return result;
  }

  /**
   * STREAM -> Notifica quem quiser ouvir
   */

  notify() async {
    if (_controller != null) {
      var response = await getTransactionList();
      _controller.sink.add(response);
    }
  }

  Stream get stream {
    if (_controller == null) {
      _controller = StreamController();
    }
    return _controller.stream.asBroadcastStream();
  }

  dispose() {
    if (!_controller.hasListener) {
      _controller.close();
      _controller = null;
    }
  }

  static StreamController _controller;
}