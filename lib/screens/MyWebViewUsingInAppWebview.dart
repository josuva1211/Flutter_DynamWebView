import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:archive/archive.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final InAppLocalhostServer localhostServer = InAppLocalhostServer();

class MyWebViewUsingInAppWebview extends StatefulWidget {
  @override
  State<MyWebViewUsingInAppWebview> createState() =>
      _MyWebViewUsingInAppWebviewState();
}

class _MyWebViewUsingInAppWebviewState
    extends State<MyWebViewUsingInAppWebview> {
  final InAppLocalhostServer localhostServer = InAppLocalhostServer();

  @override
  void initState() {
    super.initState();
    _startServerAndLoadHtml();
  }

  Future<void> _startServerAndLoadHtml() async {
    await localhostServer.start();
  }

  @override
  void dispose() {
    localhostServer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Webview Example'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse('about:blank')),
        onWebViewCreated: (InAppWebViewController webViewController) async {
          // webViewController.webView?.options.javaScriptEnabled = true;
          await downloadAndUnzipFile(webViewController);
        },
      ),
    );
  }

  Future<void> downloadAndUnzipFile(
      InAppWebViewController webViewController) async {
    String zipFilePath =
        'files/course-project-1.zip'; // Replace with your zip file path

    try {
      firebase_storage.Reference ref =
          firebase_storage.FirebaseStorage.instance.ref(zipFilePath);

      String downloadURL = await ref.getDownloadURL();

      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/example.zip');

      // Download the zip file to the local file system
      await ref.writeToFile(localFile);

      print('Zip file downloaded successfully! Saved to: ${localFile.path}');

      // Unzip the file
      String unzipPath =
          appDocDir.path; // Unzip to the app's documents directory
      List<int> bytes = localFile.readAsBytesSync();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      for (ArchiveFile file in archive) {
        String fileName = '${unzipPath}/${file.name}';
        if (file.isFile) {
          File outFile = File(fileName);
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content);

          // If the current file is "index.html", load it into the WebView
          if (file.name == 'course-project-1/index.html') {
            webViewController.loadUrl(
                urlRequest: URLRequest(
                    url: Uri.parse("http://localhost:8080${outFile.path}")));
          }
        }
      }

      print('Zip file extracted successfully!');
    } catch (e) {
      print('Error downloading/unzipping file: $e');
    }
  }
}
