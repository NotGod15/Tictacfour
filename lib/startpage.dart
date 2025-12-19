import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  bool _showLoginDropdown = false;
  bool _dropping = false;
  static const _dropDuration = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFEDE8D0);

    return Scaffold(
      backgroundColor: backgroundColor,

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapStart,
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: _dropDuration,
                curve: Curves.easeInOut,
                top: _dropping ? MediaQuery.of(context).size.height : 0,
                left: 0,
                right: 0,
                bottom: _dropping ? -MediaQuery.of(context).size.height : 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      SizedBox(
                        height: 180,
                        child: Image.asset(
                          'assets/textures/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 40),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _showLoginDropdown
                            ? const _LoginDropdownPanel()
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: const Text(
                  'Press anywhere to start',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapStart() {
    if (_dropping) return;
    setState(() {
      _dropping = true;
    });

    Future.delayed(_dropDuration, () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }
}

class _LoginDropdownPanel extends StatelessWidget {
  const _LoginDropdownPanel();

  @override
  Widget build(BuildContext context) {
    const panelColor = Color(0xFFDCCDB3);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black26,
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Start menu is not available yet.', // archaic and unused code, back when login page not yet created
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Login / signup will be added later.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
