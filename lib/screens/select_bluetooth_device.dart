import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:gameplayground/models/bluetooth_manager.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:provider/provider.dart';

import 'main_menu.dart';

class SelectBluetoothDevicePage extends StatefulWidget {
  final String title;

  SelectBluetoothDevicePage({Key key, this.title}) : super(key: key);

  @override
  _SelectBluetoothDevicePageState createState() =>
      _SelectBluetoothDevicePageState();
}

class _SelectBluetoothDevicePageState extends State<SelectBluetoothDevicePage> {
  static final String _labelScanAgain = 'Scan Again';
  static final String _textPageTitle = 'Connect to Surface EMG';
  static final String _textSearchingForDevices =
      'Scanning for suitable devices.';
  static final String _textNoDevicesFound = 'No Surface EMG devices found.';
  static final double _fontSizeMessages = 24.0;

  BluetoothManager _bluetoothManager;
  Future<List<ScanResult>> _scanResults;

  void initState() {
    super.initState();
    print('initState called.');
    _bluetoothManager =
        Provider.of<SessionDataModel>(context, listen: false).bluetoothManager;
    _scanResults = _bluetoothManager.scanForAvailableSurfaceEmgDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_textPageTitle),
        centerTitle: true,
        leading: BackButton(onPressed: () async {
          await _bluetoothManager.stopScan();
          _scanResults = null;
          Navigator.pop(context);
        }),
      ),
      body: Center(
        child: FutureBuilder(
            future: _scanResults, builder: _availableDevicesBuilder),
      ),
    );
  }

  Widget _availableDevicesBuilder(
      BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      if (snapshot.data.isNotEmpty) {
        return Column(children: [
          Expanded(
              child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _BluetoothDeviceListItem(
                      snapshot.data[index].device.name,
                      snapshot.data[index].rssi);
                }, childCount: snapshot.data.length),
              )
            ],
            scrollDirection: Axis.vertical,
          )),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[_buildScanAgainButton(), SizedBox(width: 30)]),
        ]);
      } else {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_textNoDevicesFound,
                  style: TextStyle(fontSize: _fontSizeMessages)),
              SizedBox(height: 20),
              SizedBox(height: 50, child: _buildScanAgainButton()),
            ]);
      }
    }

    // Show a spinning progress indicator and a message if still searching for
    // bluetooth devices.
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(_textSearchingForDevices,
          style: TextStyle(fontSize: _fontSizeMessages)),
      SizedBox(height: 20),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
              height: 40, width: 40, child: CircularProgressIndicator()))
    ]);
  }

  FloatingActionButton _buildScanAgainButton() {
    return FloatingActionButton.extended(
      label: Text(_labelScanAgain),
      onPressed: () {
        setState(() {
          _bluetoothManager.stopScan();
          _scanResults = _bluetoothManager.scanForAvailableSurfaceEmgDevices();
        });
      },
    );
  }
}

class _BluetoothDeviceListItem extends StatelessWidget {
  final String _deviceName;
  final int _rssi;

  _BluetoothDeviceListItem(this._deviceName, this._rssi);

  @override
  Widget build(BuildContext context) {
    ColorScheme contextColorScheme = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
            color: contextColorScheme.background,
            child: ListTile(
              dense: false,
              isThreeLine: false,
              leading: Icon(Icons.bluetooth, size: 36),
              onTap: () async {
                await Provider.of<SessionDataModel>(context, listen: false)
                    .handleDeviceName(_deviceName);
                print('device name handled.');
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MainMenuPage()));
              },
              title: Text(
                _deviceName,
                style: TextStyle(
                    color: contextColorScheme.onBackground, fontSize: 24),
              ),
              subtitle: Text('Signal Strength: ${_rssiToSignalQuality(_rssi)}'),
            )));
  }
}

String _rssiToSignalQuality(int rssi) {
  if (rssi < -80) {
    return 'Poor';
  }

  if (rssi < -70) {
    return 'Fair';
  }

  if (rssi < -60) {
    return 'Good';
  }

  return 'Excellent';
}
