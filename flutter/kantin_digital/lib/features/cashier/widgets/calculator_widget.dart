import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';


/// Modern Calculator Widget for Cashier Dashboard
/// Green Gojek theme with glassmorphism design
class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});

  /// Show calculator as a modal dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(24),
        child: CalculatorWidget(),
      ),
    );
  }

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget>
    with SingleTickerProviderStateMixin {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    setState(() {
      if (_shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else if (_display == '0' && digit != '.') {
        _display = digit;
      } else if (digit == '.' && _display.contains('.')) {
        // Already has decimal point, ignore
        return;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      if (_firstOperand == null) {
        _firstOperand = double.tryParse(_display);
        _operator = operator;
        _expression = '$_display $operator';
        _shouldResetDisplay = true;
      } else if (!_shouldResetDisplay) {
        // Chain operations
        _calculate();
        _operator = operator;
        _expression = '$_display $operator';
        _shouldResetDisplay = true;
      } else {
        // Just change the operator
        _operator = operator;
        _expression = '${_firstOperand?.toStringAsFixed(_firstOperand! == _firstOperand!.roundToDouble() ? 0 : 2)} $operator';
      }
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;

    final secondOperand = double.tryParse(_display);
    if (secondOperand == null) return;

    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          setState(() {
            _display = 'Error';
            _expression = '';
            _firstOperand = null;
            _operator = null;
            _shouldResetDisplay = true;
          });
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
      default:
        return;
    }

    setState(() {
      // Format result nicely
      if (result == result.roundToDouble()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _expression = '';
      _firstOperand = result;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _onPercentPressed() {
    final value = double.tryParse(_display);
    if (value == null) return;

    setState(() {
      final result = value / 100;
      if (result == result.roundToDouble()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _shouldResetDisplay = true;
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _shouldResetDisplay = false;
    });
  }

  void _onAllClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }



  void _onEqualsPressed() {
    _calculate();
  }

  void _onPlusMinusPressed() {
    final value = double.tryParse(_display);
    if (value == null) return;

    setState(() {
      final result = -value;
      if (result == result.roundToDouble()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildDisplay(),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kalkulator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expression.isNotEmpty)
            Text(
              _expression,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _display,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildButton('AC', onTap: _onAllClearPressed, isFunction: true),
              _buildButton('±', onTap: _onPlusMinusPressed, isFunction: true),
              _buildButton('%', onTap: _onPercentPressed, isFunction: true),
              _buildButton('÷', onTap: () => _onOperatorPressed('÷'), isOperator: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildButton('7', onTap: () => _onDigitPressed('7')),
              _buildButton('8', onTap: () => _onDigitPressed('8')),
              _buildButton('9', onTap: () => _onDigitPressed('9')),
              _buildButton('×', onTap: () => _onOperatorPressed('×'), isOperator: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildButton('4', onTap: () => _onDigitPressed('4')),
              _buildButton('5', onTap: () => _onDigitPressed('5')),
              _buildButton('6', onTap: () => _onDigitPressed('6')),
              _buildButton('-', onTap: () => _onOperatorPressed('-'), isOperator: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildButton('1', onTap: () => _onDigitPressed('1')),
              _buildButton('2', onTap: () => _onDigitPressed('2')),
              _buildButton('3', onTap: () => _onDigitPressed('3')),
              _buildButton('+', onTap: () => _onOperatorPressed('+'), isOperator: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildButton('C', onTap: _onClearPressed, isFunction: true),
              _buildButton('0', onTap: () => _onDigitPressed('0')),
              _buildButton('.', onTap: () => _onDigitPressed('.')),
              _buildButton('=', onTap: _onEqualsPressed, isEquals: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String label, {
    required VoidCallback onTap,
    bool isOperator = false,
    bool isFunction = false,
    bool isEquals = false,
  }) {
    Color bgColor;
    Color textColor;

    if (isEquals) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      textColor = AppColors.primary;
    } else if (isFunction) {
      bgColor = AppColors.textMuted.withValues(alpha: 0.15);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = Colors.white;
      textColor = AppColors.textPrimary;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          elevation: isEquals ? 4 : 0,
          shadowColor: isEquals ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primary.withValues(alpha: 0.2),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: !isEquals && !isOperator && !isFunction
                    ? Border.all(color: AppColors.textMuted.withValues(alpha: 0.2))
                    : null,
              ),
              child: Center(
                child: label == 'C'
                    ? Icon(Icons.backspace_outlined, color: textColor, size: 22)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: isOperator || isEquals ? 26 : 22,
                          fontWeight: FontWeight.w600,
                          color: textColor,
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
