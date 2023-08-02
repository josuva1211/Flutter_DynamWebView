import "dart:io";

import "package:flutter/material.dart";
//import "package:dio/dio.dart";
import "package:path_provider/path_provider.dart";
//import 'package:flutter_archive/flutter_archive.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late bool _downloading;
  String _dir = "";
  late List<String> _files, _tempFiles;
  String _zipPath = 'files/Zip.zip';
  String _localZipFileName = 'apps.zip';

  @override
  void initState() {
    super.initState();
    _files = [];
    _tempFiles = [];
    _downloading = false;
    _initDir();
  }

  _initDir() async {
    if (_dir == "") {
      _dir = (await getApplicationDocumentsDirectory())!.path;
    }
  }

  Future<File> _downloadFile(String url, String fileName) async {
    var req = await http.Client().get(Uri.parse(url));
    var file = File('$_dir/$fileName');
    return file.writeAsBytes(req.bodyBytes);
  }

  Future<void> _downloadZip() async {
    setState(() {
      _downloading = true;
    });

    _files.clear();
    _tempFiles.clear();

    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref(_zipPath);

    // Get the download URL of the zip file
    String downloadURL = await ref.getDownloadURL();

    // Get the application's local directory
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create a reference to the local file system path where you want to save the zip file
    File localFile = File('${appDocDir.path}/example.zip');

    // Download the zip file to the local file system
    await ref.writeToFile(localFile);

    print('Zip file downloaded successfully! Saved to: ${localFile.path}');

    String unzipPath = appDocDir.path;
    List<int> bytes = localFile.readAsBytesSync();
    Archive archive = ZipDecoder().decodeBytes(bytes);

    // Directory appSupportDirectory = await getApplicationDocumentsDirectory();
    // String appSupportPath = appSupportDirectory.path;

    // print('App Support Directory: $appSupportPath');

    // var zippedFile = await _downloadFile(_zipPath, _localZipFileName);
    // await unarchiveAndSave(zippedFile);

    // setState(() {
    //   _files.addAll(_tempFiles);
    //   _downloading = false;
    // });
  }

  unarchiveAndSave(var zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$_dir/${file.name}';
      if (file.isFile) {
        var outFile = File(fileName);
        //print('File:: ' + outFile.path);
        _tempFiles.add(outFile.path);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ElevatedButton(
              onPressed: () {
                print("Download");
                _downloadZip();
              },
              child: Text("Download"))),
    );
  }
}
