import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsbSerialExample extends StatefulWidget {
  @override
  _UsbSerialExampleState createState() => _UsbSerialExampleState();
}

class _UsbSerialExampleState extends State<UsbSerialExample> {
  static const platform = MethodChannel('com.example.usb/serial');

  String _usbPath = 'Unknown';

  Future<void> _getUsbPath() async {
    String usbPath;
    try {
      final String result = await platform.invokeMethod('getUsbPath');
      usbPath = 'USB Path: $result';
    } on PlatformException catch (e) {
      usbPath = "Failed to get USB path: '${e.message}'.";
    }

    setState(() {
      _usbPath = usbPath;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUsbPath();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Serial Example'),
      ),
      body: Center(
        child: Text(_usbPath),
      ),
    );
  }
}
