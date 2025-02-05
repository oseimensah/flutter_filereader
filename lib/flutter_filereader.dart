import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_filereader/filereader.dart';

class FileReaderView extends StatefulWidget {
  final String filePath; //local path
  final Function(bool) openSuccess;
  final Widget loadingWidget;
  final Widget unSupportFileWidget;

  FileReaderView(
      {Key key,
      this.filePath,
      this.openSuccess,
      this.loadingWidget,
      this.unSupportFileWidget})
      : super(key: key);

  @override
  _FileReaderViewState createState() => _FileReaderViewState();
}

class _FileReaderViewState extends State<FileReaderView> {
  FileReaderState _status = FileReaderState.LOADING_ENGINE;
  String filePath;

  @override
  void initState() {
    super.initState();
    filePath = widget.filePath;
    File(filePath).exists().then((exists) {
      if (exists) {
        _checkOnLoad();
      } else {
        _setStatus(FileReaderState.FILE_NOT_FOUND);
      }
    });
  }

  _checkOnLoad() {
    FileReader.instance.engineLoadStatus((success) {
      if (success) {
        _setStatus(FileReaderState.ENGINE_LOAD_SUCCESS);
      } else {
        _setStatus(FileReaderState.ENGINE_LOAD_FAIL);
      }
    });
  }

  _setStatus(FileReaderState status) {
    _status = status;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (_status == FileReaderState.LOADING_ENGINE) {
        return _loadingWidget();
      } else if (_status == FileReaderState.UNSUPPORT_FILE) {
        return _unSupportFile();
      } else if (_status == FileReaderState.ENGINE_LOAD_SUCCESS) {
        if (Platform.isAndroid) {
          return _createAndroidView();
        } else {
          return _createIosView();
        }
      } else if (_status == FileReaderState.ENGINE_LOAD_FAIL) {
        return _enginLoadFail();
      } else if (_status == FileReaderState.FILE_NOT_FOUND) {
        return _fileNotFoundFile();
      } else {
        return _loadingWidget();
      }
    } else {
      return Center(child: Text("Unsupported platform"));
    }
  }

  Widget _unSupportFile() {
    return widget.unSupportFileWidget ??
        Center(
          child: Text(
              "Does not support opening ${_fileType(filePath)} Type of file"),
        );
  }

  Widget _fileNotFoundFile() {
    return Center(
      child: Text("File does not exist"),
    );
  }

  Widget _enginLoadFail() {
    //Most likely the problem of abi
    //It is also possible that the download was successful the first time, but the loading was unsuccessful
    return Center(
      child: Text("The engine failed to load, please exit and try again"),
    );
  }

  Widget _loadingWidget() {
    return widget.loadingWidget ??
        Center(
          child: CupertinoActivityIndicator(),
        );
  }

  Widget _createAndroidView() {
    return AndroidView(
        viewType: "FileReader",
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: StandardMessageCodec());
  }

  _onPlatformViewCreated(int id) {
    FileReader.instance.openFile(id, filePath, (success) {
      if (!success) {
        _setStatus(FileReaderState.UNSUPPORT_FILE);
      }
      widget.openSuccess?.call(success);
    });
  }

  Widget _createIosView() {
    return UiKitView(
      viewType: "FileReader",
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParamsCodec: StandardMessageCodec(),
    );
  }

  String _fileType(String filePath) {
    if (filePath == null || filePath.isEmpty) {
      return "";
    }
    int i = filePath.lastIndexOf('.');
    if (i <= -1) {
      return "";
    }
    return filePath.substring(i + 1);
  }
}
