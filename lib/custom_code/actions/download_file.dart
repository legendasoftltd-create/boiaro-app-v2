// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom actions

import 'dart:async';
import 'package:dio/dio.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

final Dio dio = Dio();
// bool loading = false;
// double progress = 0;

Future downloadFile(String url, String fileName) async {
  // setState(() {
  // loading = true;
  // progress = 0;
  // });
  FFAppState().update(() {
    FFAppState().loading = true;
    FFAppState().progress = 0.0;
  });
  bool downloaded = await savePdf(url, fileName);

  if (downloaded) {
    print("File Downloaded");
  } else {
    print("Problem Downloading File");
  }
  // setState(() {
//  loading = false;
  // });
  FFAppState().update(() {
    FFAppState().loading = false;
    // FFAppState().progress = 0.0;
  });
}

Future savePdf(String url, String fileName) async {
  Directory? directory;
  try {
    if (Platform.isAndroid) {
      // if (await _requestPermission(Permission.storage)) {
      directory = await getApplicationDocumentsDirectory();

      String newPath = "";
      print(directory);
      List<String> paths = directory!.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/Ebook";
      directory = Directory(newPath);
      // } else {
      //   return false;
      // }
    } else {
      if (await _requestPermission(Permission.photos)) {
        directory = await getTemporaryDirectory();
      } else {
        return false;
      }
    }
    File saveFile = File(directory.path + "/$fileName");
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    if (await directory.exists()) {
      await dio.download(url, saveFile.path,
          onReceiveProgress: (value1, value2) {
        FFAppState().update(() {
          //  FFAppState().loading = false;
          FFAppState().progress = value1 / value2;
        });
        // setState(() {
        //  FFAppState().progress = value1 / value2;
        // });
      });
      if (Platform.isIOS) {
        //   await ImageGallerySaver.saveFile(saveFile.path,
        //     isReturnPathOfIOS: true);
      }
      return true;
    }
    return false;
  } catch (e) {
    print("Error saving PDF: $e");
    return false;
  }
}

Future<bool> _requestPermission(Permission permission) async {
  Completer<bool> completer = Completer<bool>();

  void request() async {
    if (await permission.isGranted) {
      completer.complete(true);
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        completer.complete(true);
      } else {
        completer.complete(false);
      }
    }
  }

  request();
  return completer.future;
}

// Future<bool> _requestPermission(Permission permission) async {
//   if (await permission.isGranted) {
//     return true;
//   } else {
//     var result = await permission.request();
//     if (result == PermissionStatus.granted) {
//       return true;
//     }
//   }
//   return false;
// }
