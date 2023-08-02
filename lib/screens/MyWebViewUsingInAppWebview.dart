import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:archive/archive.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MyWebViewUsingInAppWebview extends StatelessWidget {
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
        'files/forms-td-practice.zip'; // Replace with your zip file path

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
          if (file.name == 'forms-td-practice/forms-td-practice/index.html') {
            webViewController.loadFile(assetFilePath: '${outFile.path}');
          }
        }
      }

      print('Zip file extracted successfully!');
    } catch (e) {
      print('Error downloading/unzipping file: $e');
    }
  }
}
