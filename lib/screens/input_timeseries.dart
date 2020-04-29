import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class InputTimeseriesPage extends StatefulWidget {
  final String title;

  InputTimeseriesPage({Key key, this.title}) : super(key: key);

  @override
  _InputTimeseriesPageState createState() => _InputTimeseriesPageState();
}

class _InputTimeseriesPageState extends State<InputTimeseriesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input Timeseries"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Empty Page'),
            SizedBox(
                height: 250,
                width: 250,
                child: charts.LineChart(_createFakeData())),
          ],
        ),
      ),
    );
  }
}

List<charts.Series<OrderedPair, int>> _createFakeData() {
  final data = [
    new OrderedPair(0, 1),
    new OrderedPair(1, 5),
    new OrderedPair(2, 4),
    new OrderedPair(3, 7)
  ];

  return [
    charts.Series<OrderedPair, int>(
        id: 'fake_data',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (OrderedPair pair, _) => pair.xValue,
        measureFn: (OrderedPair pair, _) => pair.yValue,
        data: data)
  ];
}

class OrderedPair {
  final int xValue;
  final int yValue;

  OrderedPair(this.xValue, this.yValue);
}
