

import 'dart:convert';

import 'package:clean_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test("Check Transponder Response ", () {
    final rawResponse = '''
    { 
      "transponders": [
         {
            "epc": "ASJA98A838382JSJJS",
            "rssi": -38,
            "timestamp": "2020-05-05T12:53:22.857+0000"
         },
         {
            "epc": "BB88327737223JJD",
            "rssi": -80,
            "timestamp": "2020-07-22T15:22:18.466+0000"
         }
      ]
    }
    ''';

    final response = TransponderResponse.fromJson(jsonDecode(rawResponse));
    final firstTransponder = response.transponders!.first;
    expect(firstTransponder.epc!, equals("ASJA98A838382JSJJS"));
    expect(firstTransponder.rssi!, equals(-38));
    expect(firstTransponder.timestamp!, equals(DateTime.parse("2020-05-05T12:53:22.857+0000")));

    final secondTransponder = response.transponders!.elementAt(1);
    expect(secondTransponder.epc!, equals("BB88327737223JJD"));
    expect(secondTransponder.rssi!, equals(-80));
    expect(secondTransponder.timestamp!, equals(DateTime.parse("2020-07-22T15:22:18.466+0000")));

  });
}
