import 'package:call_app_livekit/src/screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _callIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _peerIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Username',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _callIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Call Id',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _peerIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter peer Id',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              onPressed: () {
                context.push(CallScreen.routeName, extra: {
                  "callId": _callIdController.text,
                  "username": _usernameController.text,
                  "peerId": _peerIdController.text,
                });
              },
              child: const Text(
                'Join Call',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
