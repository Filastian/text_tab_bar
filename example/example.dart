import 'package:flutter/material.dart';
import 'package:text_tab_bar/text_tab_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TextTabBar Example'),
        ),
        body: DefaultTabController(
          length: 20,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              return Column(
                children: [
                  TextTabBar(
                    tabs: List.generate(20, (index) => 'Tab ${index + 1}'),
                    controller: tabController,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: List.generate(
                        20,
                        (index) => Center(
                          child: Text(
                            'Page ${index + 1}',
                            style: const TextStyle(fontSize: 24.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
