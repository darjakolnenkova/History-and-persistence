import 'package:intl/intl.dart';
import 'database.dart';
import 'calculator_model.dart';

class KmMileConverterController {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<double> convertKmToMiles(double km) async {
    double result = km * 0.621371;

    // Format the record
    String expression = "$km км";
    String resultText = "${result.toStringAsFixed(2)} миль";
    String timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Save to SQLite
    final record = CalculationRecord(
      expression: expression,
      result: resultText,
      timestamp: timestamp,
    );
    await db.insertRecord(record);

    return result;
  }

  void onEqualsPressed() {
    String expression = '4 * 5'; // this should come from your UI input
    String result = '20';        // this is your calculated result

    DatabaseHelper.instance.saveCalculationToHistory(expression, result);
  }
}
