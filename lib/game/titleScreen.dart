import 'package:flutter/material.dart';
import 'package:panel_puzzle/game/game_set.dart';
import 'package:panel_puzzle/shared/GameTransition.dart';
import 'package:panel_puzzle/shared/menuItem.dart';

class Titlescreen extends StatefulWidget {

  const new({super.key});

  @override
  State<Titlescreen> createState() => _TitlescreenState();
}

class _TitlescreenState extends State<Titlescreen> {
  
  void _navigateToScreen(BuildContext context, Offset position, Widget screen){
    final navigator = Navigator.of(context);
    CirclePulseTransition.of(context).trigger(
      position,
      onMidPoint: () {
        navigator.push(PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) => screen,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 20 ? constraints.maxHeight - 20 : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      const Text(
                        'Panel Panic',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          wordSpacing: 10,
                          fontSize: 48,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white
                        ),
                      ),
                      const SizedBox(height: 100),
                      Menuitem(child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Builder(
                              builder: (cardContext) {
                                return InkWell(
                                  onTap: () {
                                    final box = cardContext.findRenderObject()! as RenderBox;
                                    final position = box.localToGlobal(box.size.center(Offset.zero)); // gets the card's middle position to render transition
                                    _navigateToScreen(context, position, const GameSet.randomMode());
                                  },
                                  child: const SizedBox(
                                    width: double.infinity,
                                    height: 80,
                                    child: Center(child: Text('Random Game', style: TextStyle(color: Colors.white),)),
                                  ),
                                );
                              },
                            ),
                          )
                      ),
                      Menuitem(child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTapUp: (details) {
                              debugPrint('Work in progress');
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: Center(child: Text('Custom Game', style: TextStyle(color: Colors.white),)),
                            ),
                          ),
                        )
                      ),
                      Menuitem(child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTapUp: (details) {
                              debugPrint('Work in progress');
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: Center(child: Text('Create Custom Board', style: TextStyle(color: Colors.white),)),
                            ),
                          ),
                        )
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}