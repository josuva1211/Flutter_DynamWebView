import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:archive/archive.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebViewUsingString extends StatefulWidget {
  @override
  _MyWebViewUsingStringState createState() => _MyWebViewUsingStringState();
}

class _MyWebViewUsingStringState extends State<MyWebViewUsingString> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Webview Example'),
      ),
      body: WebView(
        initialUrl: 'about:blank',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) async {
          _controller.complete(webViewController);
          await _loadAndLoadHtml(webViewController);
        },
      ),
    );
  }

  Future<void> _loadAndLoadHtml(WebViewController webViewController) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/example.zip');

      // Download the zip file from Firebase Storage and save it locally
      await downloadFile(localFile);

      // Unzip the downloaded zip file
      await unzipFile(localFile, appDocDir);

      // Read the contents of index.html, CSS, and JS files
      // String indexHtmlContents = await getFileContents(
      //     '${appDocDir.path}/Webview/fitness-tracker/index.html');
      String cssContents = await getFileContents(
          '${appDocDir.path}/forms-td-practice/styles.897077e29848b68c.css');
      String mainjsContents = await getFileContents(
          '${appDocDir.path}/forms-td-practice/main.1b8b9af40a2b844d.js');
      String polyfillsjsContents = await getFileContents(
          '${appDocDir.path}/forms-td-practice/polyfills.86504faaa884e352.js');
      String runtimejsContents = await getFileContents(
          '${appDocDir.path}/forms-td-practice/runtime.cfe305ccd58dd19e.js');

      // Combine the contents into a single HTML string
      String combinedHtml = '''
        <!DOCTYPE html><html lang="en"><head>
          <meta charset="utf-8">
          <title>FormsTdPractice</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>html{font-family:sans-serif;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}@media print{*,:after,:before{color:#000!important;text-shadow:none!important;background:0 0!important;box-shadow:none!important}}*{box-sizing:border-box}:after,:before{box-sizing:border-box}html{font-size:10px;-webkit-tap-highlight-color:rgba(0,0,0,0)}body{font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size:14px;line-height:1.42857143;color:#333;background-color:#fff}</style>
          <style>$cssContents</style>
        </head>
        <body class="mat-typography">
          <app-root></app-root>
        <script type="module">$runtimejsContents</script>
        <script type="module">$polyfillsjsContents</script>
        <script type="module">$mainjsContents</script>

        </body></html>
      ''';

      // Load the combined HTML string into the WebView
      webViewController.loadUrl(Uri.dataFromString(
        combinedHtml,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString());
    } catch (e) {
      print('Error loading HTML files: $e');
    }
  }

  Future<void> downloadFile(File localFile) async {
    // Replace 'your_zip_file_path' with the actual path of the zip file in Firebase Storage
    String zipFilePath = 'files/forms-td-practice.zip';
    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref(zipFilePath);
    await ref.writeToFile(localFile);
  }

  Future<void> unzipFile(File localFile, Directory appDocDir) async {
    List<int> bytes = localFile.readAsBytesSync();
    Archive archive = ZipDecoder().decodeBytes(bytes);
    for (ArchiveFile file in archive) {
      String fileName = '${appDocDir.path}/${file.name}';
      if (file.isFile) {
        File outFile = File(fileName);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content);
      }
    }
  }

  Future<String> getFileContents(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }
}
