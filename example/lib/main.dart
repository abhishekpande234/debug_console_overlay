
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:debug_console_overlay/debug_console_overlay.dart';
import 'package:dio/dio.dart';

void main() {
  DebugConsoleOverlay.runWithPrintCapture(() {
    runApp(const ExampleApp());
  });
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DebugConsoleOverlay(
      enabled: kDebugMode,
      child: MaterialApp(
        home: const HomePage(),
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Dio dio;

  @override
  void initState() {
    super.initState();
    
    // Setup Dio with debug console interceptor
    dio = Dio();
    dio.addDebugConsole(); // This is the magic line for Dio integration!
    
    // Optional: configure base options
    dio.options.baseUrl = 'https://jsonplaceholder.typicode.com';
    dio.options.connectTimeout = Duration(seconds: 5);
    dio.options.receiveTimeout = Duration(seconds: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('debug_console_overlay + Dio Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Log Testing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => DebugConsoleOverlay.log('Hello from INFO', level: LogLevel.info, tag: 'DEMO'),
                child: const Text('Log INFO'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => DebugConsoleOverlay.log('Uh oh… Warnings are fine', level: LogLevel.warn, tag: 'DEMO'),
                child: const Text('Log WARN'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  try {
                    throw StateError('Sample exception to test FlutterError.onError');
                  } catch (e) {
                    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: StackTrace.current));
                  }
                },
                child: const Text('Trigger FlutterError'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => print('This print() will also appear in overlay'),
                child: const Text('print() → overlay'),
              ),
              const SizedBox(height: 24),
              
              const Text(
                '🚀 Dio HTTP Requests (Auto-Logged)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _dioGetRequest(),
                child: const Text('Dio GET Request'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _dioPostRequest(),
                child: const Text('Dio POST Request'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _dioErrorRequest(),
                child: const Text('Dio Error Request'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _dioWithCustomHeaders(),
                child: const Text('Dio with Custom Headers'),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Manual Network Testing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _simulateGetRequest(),
                child: const Text('Simulate GET Request'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _simulatePostRequest(),
                child: const Text('Simulate POST Request'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _simulateErrorRequest(),
                child: const Text('Simulate Error Request'),
              ),
              const SizedBox(height: 24),
              const Text(
                'How to use:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Tap the floating bug icon to open debug console\n'
                '2. Switch between Logs and Network tabs\n'
                '3. Use search and filters\n'
                '4. Tap copy icons to copy content\n'
                '5. Tap list items to expand details\n'
                '6. Dio requests are automatically captured!',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dio requests - these will be automatically logged!
  Future<void> _dioGetRequest() async {
    try {
      await dio.get('/posts/1');
      DebugConsoleOverlay.log('✅ Dio GET completed successfully', level: LogLevel.info, tag: 'DIO_SUCCESS');
    } catch (e) {
      DebugConsoleOverlay.log('❌ Dio GET failed: $e', level: LogLevel.error, tag: 'DIO_FAIL');
    }
  }

  Future<void> _dioPostRequest() async {
    try {
      await dio.post('/posts', data: {
        'title': 'My Dio Post',
        'body': 'This is a post made with Dio HTTP client',
        'userId': 1,
      });
      DebugConsoleOverlay.log('✅ Dio POST completed successfully', level: LogLevel.info, tag: 'DIO_SUCCESS');
    } catch (e) {
      DebugConsoleOverlay.log('❌ Dio POST failed: $e', level: LogLevel.error, tag: 'DIO_FAIL');
    }
  }

  Future<void> _dioErrorRequest() async {
    try {
      // This will cause a 404 error
      await dio.get('/nonexistent-endpoint');
    } catch (e) {
      DebugConsoleOverlay.log('Expected error occurred (404)', level: LogLevel.info, tag: 'DIO_TEST');
    }
  }

  Future<void> _dioWithCustomHeaders() async {
    try {
      await dio.get(
        '/posts/1',
        options: Options(
          headers: {
            'X-Custom-Header': 'MyValue',
            'Authorization': 'Bearer custom-token-123',
            'User-Agent': 'MyApp/1.0',
          },
        ),
      );
      DebugConsoleOverlay.log('✅ Dio request with custom headers completed', level: LogLevel.info, tag: 'DIO_SUCCESS');
    } catch (e) {
      DebugConsoleOverlay.log('❌ Dio custom headers request failed: $e', level: LogLevel.error, tag: 'DIO_FAIL');
    }
  }

  // Manual simulation methods (same as before)
  void _simulateGetRequest() {
    final url = 'https://jsonplaceholder.typicode.com/posts/1';
    
    // Start the request using the new system
    DebugConsoleOverlay.logNetworkRequest('GET', url, tag: 'MANUAL_REQ');

    // Simulate network delay
    Future.delayed(Duration(milliseconds: 500), () {
      // Complete with success
      DebugConsoleOverlay.logNetworkResponse('GET', url, 200, responseData: {
        'userId': 1,
        'id': 1,
        'title': 'sunt aut facere repellat provident occaecati excepturi optio reprehenderit',
        'body': 'quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto'
      });
    });
  }

  void _simulatePostRequest() {
    final url = 'https://jsonplaceholder.typicode.com/posts';
    final requestBody = {
      'title': 'New Post',
      'body': 'This is a test post created from the debug console example',
      'userId': 1,
    };
    
    // Start the request
    DebugConsoleOverlay.logNetworkRequest('POST', url, tag: 'MANUAL_REQ');

    // Simulate network delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Complete with success
      DebugConsoleOverlay.logNetworkResponse('POST', url, 201, responseData: {
        'id': 101,
        ...requestBody,
      });
    });
  }

  void _simulateErrorRequest() {
    final url = 'https://jsonplaceholder.typicode.com/posts/9999';
    
    // Start the request
    DebugConsoleOverlay.logNetworkRequest('GET', url, tag: 'MANUAL_REQ');

    // Simulate network delay and error
    Future.delayed(Duration(milliseconds: 1200), () {
      // Complete with error
      DebugConsoleOverlay.logNetworkError('GET', url, 'The requested resource was not found', statusCode: 404);
    });
  }
}
