// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/dashboard/presentation/main_shell.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  static String pinKey = 'app_pin';
  static String lockEnabledKey = 'app_lock_enabled';

  String _enteredPin = '';
  String? _savedPin;
  bool _isSetupMode = false;
  String? _firstPin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    final lockEnabled = prefs.getBool(lockEnabledKey) ?? true;
    final pin = prefs.getString(pinKey);

    if (!lockEnabled && mounted) {
      _goHome();
      return;
    }

    if (!mounted) return;

    setState(() {
      _savedPin = pin;
      _isSetupMode = pin == null;
      _loading = false;
    });
  }

  Future<void> _onDigit(String digit) async {
    if (_enteredPin.length >= 4) return;

    setState(() => _enteredPin += digit);

    if (_enteredPin.length == 4) {
      await Future.delayed(Duration(milliseconds: 150));

      if (_isSetupMode) {
        await _handleSetupPin();
      } else {
        _handleLoginPin();
      }
    }
  }

  Future<void> _handleSetupPin() async {
    if (_firstPin == null) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
      });
      _showMessage('Confirm your passcode.');
      return;
    }

    if (_firstPin != _enteredPin) {
      setState(() {
        _firstPin = null;
        _enteredPin = '';
      });
      _showMessage('Passcode did not match. Try again.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pinKey, _enteredPin);
    await prefs.setBool(lockEnabledKey, true);

    if (!mounted) return;
    _goHome();
  }

  void _handleLoginPin() {
    if (_enteredPin == _savedPin) {
      _goHome();
      return;
    }

    setState(() => _enteredPin = '');
    _showMessage('Wrong passcode.');
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainShell()),
    );
  }

  void _backspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _isSetupMode
        ? (_firstPin == null ? 'Create Passcode' : 'Confirm Passcode')
        : 'Enter Passcode';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 48, 28, 28),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Use a 4-digit code to protect your spending data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              SizedBox(height: 44),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return Container(
                    width: 18,
                    height: 18,
                    margin: EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.accent : Colors.transparent,
                      border: Border.all(color: AppColors.textSecondary),
                    ),
                  );
                }),
              ),
              Spacer(),
              _NumberPad(onDigit: _onDigit, onBackspace: _backspace),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: keys.length,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 74,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];

        if (key.isEmpty) return SizedBox.shrink();

        if (key == 'back') {
          return _KeyButton(
            child: Icon(Icons.backspace_outlined),
            onTap: onBackspace,
          );
        }

        return _KeyButton(
          child: Text(
            key,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          onTap: () => onDigit(key),
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: AppColors.textPrimary),
            child: DefaultTextStyle(
              style: TextStyle(color: AppColors.textPrimary),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
