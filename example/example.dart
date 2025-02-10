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
                    selectedTextStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 24.0,
                    ),
                    unselectedTextStyle: TextStyle(
                      color: Colors.green,
                      fontSize: 18.0,
                    ),
                    isFloatingAnimation: true,
                    decorator: (index, child) {
                      if (index % 3 != 0) {
                        return child;
                      }

                      return Stack(
                        children: [
                          child,
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
