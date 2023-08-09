import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:archive/archive.dart'; // Import the webview_flutter package
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class MyWebView extends StatefulWidget {
  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Webview Example'),
      ),
      body: WebView(
        initialUrl: 'about:blank',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) async {
          _webViewController = controller;
          await downloadAndUnzipFile();
        },
      ),
    );
  }

  Future<void> downloadAndUnzipFile() async {
    String zipFilePath =
        'files/course-project-1.zip'; // Replace with your zip file path

    try {
      firebase_storage.Reference ref =
          firebase_storage.FirebaseStorage.instance.ref(zipFilePath);

      String downloadURL = await ref.getDownloadURL();

      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/webparts.zip');

      // Download the zip file to the local file system
      await ref.writeToFile(localFile);

      print('Zip file downloaded successfully! Saved to: ${localFile.path}');

      // Unzip the file
      String unzipPath =
          appDocDir.path; // Unzip to the app's documents directory
      List<int> bytes = localFile.readAsBytesSync();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      String url = '';

      for (ArchiveFile file in archive) {
        String fileName = '${unzipPath}/${file.name}';
        if (file.isFile) {
          File outFile = File(fileName);
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content);

          // If the current file is "index.html", load it into the WebView
          if (file.name == 'course-project-1/index.html') {
            // url = Uri.file(fileName).toString();

            // final uri = Uri.directory(Uri.file(fileName).toString());
            // final uriString =
            //     uri.toString().substring(0, uri.toString().length - 1);

            /// Remove final slash symbol

            _webViewController.loadFile('${outFile.path}');
          }
        }
      }

      print('Zip file extracted successfully!');
    } catch (e) {
      print('Error downloading/unzipping file: $e');
    }
  }
}
