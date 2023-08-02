import 'package:flutter/material.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadAssetsDemo extends StatefulWidget {
  DownloadAssetsDemo() : super();

  final String title = "Download & Extract ZIP Demo";

  @override
  DownloadAssetsDemoState createState() => DownloadAssetsDemoState();
}

class DownloadAssetsDemoState extends State<DownloadAssetsDemo> {
  //
  late bool _downloading;
  String _dir = "";
  late List<String> _images, _tempImages;
  String _zipPath = 'http://coderzheaven.com/youtube_flutter/images.zip';
  String _localZipFileName = 'images.zip';

  @override
  void initState() {
    super.initState();
    _images = [];
    _tempImages = [];
    _downloading = false;
    _initDir();
  }

  _initDir() async {
    if (_dir == "") {
      _dir = (await getApplicationDocumentsDirectory()).path;
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

    _images.clear();
    _tempImages.clear();

    var zippedFile = await _downloadFile(_zipPath, _localZipFileName);
    await unarchiveAndSave(zippedFile);

    setState(() {
      _images.addAll(_tempImages);
      _downloading = false;
    });
  }

  unarchiveAndSave(var zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$_dir/${file.name}';
      if (file.isFile) {
        var outFile = File(fileName);
        //print('File:: ' + outFile.path);
        _tempImages.add(outFile.path);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
  }

  buildList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _images.length,
        itemBuilder: (BuildContext context, int index) {
          return Image.file(
            File(_images[index]),
            fit: BoxFit.fitWidth,
          );
        },
      ),
    );
  }

  progress() {
    return Container(
      width: 25,
      height: 25,
      padding: EdgeInsets.fromLTRB(0.0, 20.0, 10.0, 20.0),
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          _downloading ? progress() : Container(),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              _downloadZip();
            },
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            buildList(),
          ],
        ),
      ),
    );
  }
}
