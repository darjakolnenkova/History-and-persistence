import 'package:flutter/material.dart';
import 'km_to_mile_converter.dart';
import 'calculator_model.dart';
import 'controller.dart';
import 'history_screen.dart';
import 'database.dart'; // Import DatabaseHelper

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalculatorUI(),
    );
  }
}

class DivideByZeroException implements Exception {
  final String message;
  DivideByZeroException([this.message = 'Деление на ноль']);

  @override
  String toString() => message;
}

class _CalculatorUIState extends State<CalculatorUI> {
  String display = '0';   // текущий текст
  final CalculatorModel model = CalculatorModel();  // подключение модели
  late KmMileConverterController controller;         // контроллер для другой страницы

  final List<String> buttons = const [
    '7', '8', '9', '/',
    '4', '5', '6', 'x',
    '1', '2', '3', '-',
    'C', '0', '=', '+',
  ];

  @override
  void initState() {
    super.initState();
    controller = KmMileConverterController();
  }

  Future<void> buttonPressed(String buttonText) async {
    if (buttonText == 'C') {
      setState(() {
        display = '0';
      });
    } else if (buttonText == '=') {
      final expression = display;
      try {
        final result = _evaluate(expression);

        String resultStr;
        if (result % 1 == 0) {
          resultStr = result.toInt().toString();
        } else {
          resultStr = result.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
        }

        final timestamp = DateTime.now().toIso8601String();
        final record = CalculationRecord(
          expression: expression,
          result: resultStr,
          timestamp: timestamp,
        );

        await DatabaseHelper.instance.insertRecord(record);

        setState(() {
          display = resultStr;
        });
      } catch (e) {
        setState(() {
          if (e is FormatException) {
            display = e.message;
          } else if (e is DivideByZeroException) {
            display = e.message;
          } else {
            display = "Ошибка";
          }
        });
      }
    } else {
      setState(() {
        display = display == '0' ? buttonText : display + buttonText;
      });
    }
  }

  double _evaluate(String expression) {
    if (expression.endsWith('+') ||
        expression.endsWith('-') ||
        expression.endsWith('x') ||
        expression.endsWith('/')) {
      throw FormatException("Неверный формат");
    }

    for (var op in ['+', '-', 'x', '/']) {
      if (expression.contains(op)) {
        final parts = expression.split(op);
        if (parts.length != 2) throw FormatException("Неверный формат");

        try {
          final a = double.parse(parts[0]);
          final b = double.parse(parts[1]);

          if (op == '/' && b == 0) {
            throw DivideByZeroException();
          }

          return model.calculate(a, b, op);
        } on DivideByZeroException catch (_) {
          rethrow;
        } on FormatException catch (_) {
          rethrow;
        } catch (_) {
          throw FormatException("Ошибка");
        }
      }
    }
    throw FormatException("Оператор не найден");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                child: Text(
                  display,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buttons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () => buttonPressed(buttons[index]),
                    child: Text(
                      buttons[index],
                      style: const TextStyle(fontSize: 35),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const KmToMileConverterScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Конвертация: км в мили'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('История вычислений'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CalculatorUI extends StatefulWidget {
  const CalculatorUI({Key? key}) : super(key: key);

  @override
  _CalculatorUIState createState() => _CalculatorUIState();
}