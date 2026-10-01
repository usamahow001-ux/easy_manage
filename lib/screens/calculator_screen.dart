import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/calculation_record.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _currentInput = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetInput = false;

  void _onDigitPressed(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_shouldResetInput || _currentInput == '0') {
        _currentInput = digit;
        _shouldResetInput = false;
      } else {
        if (_currentInput.length < 15) {
          _currentInput += digit;
        }
      }
    });
  }

  void _onDecimalPressed() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_shouldResetInput) {
        _currentInput = '0.';
        _shouldResetInput = false;
      } else if (!_currentInput.contains('.')) {
        _currentInput += '.';
      }
    });
  }

  void _onOperatorPressed(String op) {
    HapticFeedback.mediumImpact();
    setState(() {
      final currentVal = double.tryParse(_currentInput) ?? 0.0;
      if (_firstOperand != null && _operator != null && !_shouldResetInput) {
        _calculatePartialResult();
      } else {
        _firstOperand = currentVal;
      }
      _operator = op;
      _expression = '${_formatNumber(_firstOperand!)} $op';
      _shouldResetInput = true;
    });
  }

  void _calculatePartialResult() {
    if (_firstOperand == null || _operator == null) return;
    final secondVal = double.tryParse(_currentInput) ?? 0.0;
    double res = 0.0;

    switch (_operator) {
      case '+':
        res = _firstOperand! + secondVal;
        break;
      case '−':
      case '-':
        res = _firstOperand! - secondVal;
        break;
      case '×':
      case '*':
        res = _firstOperand! * secondVal;
        break;
      case '÷':
      case '/':
        if (secondVal != 0) {
          res = _firstOperand! / secondVal;
        } else {
          _currentInput = 'Error';
          _firstOperand = null;
          _operator = null;
          _expression = '';
          return;
        }
        break;
    }

    _firstOperand = res;
    _currentInput = _formatNumber(res);
  }

  void _onEqualPressed() {
    HapticFeedback.heavyImpact();
    if (_firstOperand == null || _operator == null) return;

    final secondVal = double.tryParse(_currentInput) ?? 0.0;
    final fullExpr = '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(secondVal)}';

    _calculatePartialResult();

    final resultStr = _currentInput;
    if (resultStr != 'Error') {
      context.read<AppStateProvider>().addCalculationRecord(
        CalculationRecord(
          expression: fullExpr,
          result: resultStr,
          time: DateTime.now(),
        ),
      );
    }

    setState(() {
      _expression = '$fullExpr =';
      _firstOperand = null;
      _operator = null;
      _shouldResetInput = true;
    });
  }

  void _onClearPressed() {
    HapticFeedback.lightImpact();
    setState(() {
      _expression = '';
      _currentInput = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetInput = false;
    });
  }

  void _onBackspacePressed() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_shouldResetInput || _currentInput.length <= 1 || _currentInput == 'Error') {
        _currentInput = '0';
      } else {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      }
    });
  }

  void _onPercentagePressed() {
    HapticFeedback.selectionClick();
    setState(() {
      final val = double.tryParse(_currentInput) ?? 0.0;
      if (_firstOperand != null && (_operator == '+' || _operator == '−' || _operator == '-')) {
        final pctVal = (_firstOperand! * val) / 100.0;
        _currentInput = _formatNumber(pctVal);
      } else {
        final pct = val / 100.0;
        _currentInput = _formatNumber(pct);
      }
    });
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    String str = val.toStringAsFixed(6);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }

  void _copyResultToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _currentInput));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied "$_currentInput" to clipboard'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHistoryModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<AppStateProvider>(
          builder: (modalCtx, provider, _) {
            final history = provider.calculatorHistory;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calculation History',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (history.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.debitRed),
                            label: Text(
                              'Clear',
                              style: GoogleFonts.inter(color: AppTheme.debitRed, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              provider.clearCalculatorHistory();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No recent calculations yet.',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: history.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.expression,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              subtitle: Text(
                                '= ${item.result}',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.north_west_rounded, size: 20, color: AppTheme.primaryGreen),
                                tooltip: 'Use result',
                                onPressed: () {
                                  setState(() {
                                    _currentInput = item.result;
                                    _shouldResetInput = true;
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  _currentInput = item.result;
                                  _shouldResetInput = true;
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final loc = provider.loc;
    final isDark = provider.isDarkMode;

    final isAllClear = _currentInput == '0' && _expression.isEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          loc.tr('calculator'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Calculation History',
            icon: Badge(
              isLabelVisible: provider.calculatorHistory.isNotEmpty,
              label: Text('${provider.calculatorHistory.length}'),
              child: const Icon(Icons.history_rounded),
            ),
            onPressed: () => _showHistoryModal(context),
          ),
          IconButton(
            tooltip: 'Copy Result',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () => _copyResultToClipboard(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Section with iPhone-style horizontal swipe to backspace
            Expanded(
              flex: 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (_) => _onBackspacePressed(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expression line
                      if (_expression.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            _expression,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Main Input / Result line (scales down smoothly)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () => _copyResultToClipboard(context),
                          child: Text(
                            _currentInput,
                            style: GoogleFonts.outfit(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtle swipe to delete indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 13,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loc.tr('swipe_to_delete'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Keypad Grid Section (iPhone Calculator Style)
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard.withValues(alpha: 0.6) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Row 1: AC/C, ⌫ (Clear 1 digit), %, ÷
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(
                            text: isAllClear ? 'AC' : 'C',
                            textColor: AppTheme.debitRed,
                            bgColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            onTap: _onClearPressed,
                          ),
                          _buildButton(
                            icon: Icons.backspace_outlined,
                            textColor: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            bgColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            onTap: _onBackspacePressed,
                          ),
                          _buildButton(
                            text: '%',
                            textColor: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            bgColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            onTap: _onPercentagePressed,
                          ),
                          _buildButton(
                            text: '÷',
                            textColor: Colors.white,
                            bgColor: AppTheme.primaryGreen,
                            isOperator: true,
                            isSelected: _operator == '÷' && _shouldResetInput,
                            onTap: () => _onOperatorPressed('÷'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 2: 7, 8, 9, ×
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(text: '7', onTap: () => _onDigitPressed('7')),
                          _buildButton(text: '8', onTap: () => _onDigitPressed('8')),
                          _buildButton(text: '9', onTap: () => _onDigitPressed('9')),
                          _buildButton(
                            text: '×',
                            textColor: Colors.white,
                            bgColor: AppTheme.primaryGreen,
                            isOperator: true,
                            isSelected: _operator == '×' && _shouldResetInput,
                            onTap: () => _onOperatorPressed('×'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 3: 4, 5, 6, −
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(text: '4', onTap: () => _onDigitPressed('4')),
                          _buildButton(text: '5', onTap: () => _onDigitPressed('5')),
                          _buildButton(text: '6', onTap: () => _onDigitPressed('6')),
                          _buildButton(
                            text: '−',
                            textColor: Colors.white,
                            bgColor: AppTheme.primaryGreen,
                            isOperator: true,
                            isSelected: (_operator == '−' || _operator == '-') && _shouldResetInput,
                            onTap: () => _onOperatorPressed('−'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 4: 1, 2, 3, +
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(text: '1', onTap: () => _onDigitPressed('1')),
                          _buildButton(text: '2', onTap: () => _onDigitPressed('2')),
                          _buildButton(text: '3', onTap: () => _onDigitPressed('3')),
                          _buildButton(
                            text: '+',
                            textColor: Colors.white,
                            bgColor: AppTheme.primaryGreen,
                            isOperator: true,
                            isSelected: _operator == '+' && _shouldResetInput,
                            onTap: () => _onOperatorPressed('+'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 5 (HERO ROW: 0, ., and BIGGER EQUAL BUTTON)
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(
                            text: '0',
                            flex: 1,
                            onTap: () => _onDigitPressed('0'),
                          ),
                          _buildButton(
                            text: '.',
                            flex: 1,
                            onTap: _onDecimalPressed,
                          ),
                          // BIGGER HERO EQUAL BUTTON (flex: 2, smooth capsule, glowing emerald gradient)
                          _buildHeroEqualButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    String? text,
    IconData? icon,
    Color? textColor,
    Color? bgColor,
    int flex = 1,
    bool isOperator = false,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final defaultText = isDark ? Colors.white : AppTheme.lightTextPrimary;

    final effectiveBg = isSelected
        ? Colors.white
        : (bgColor ?? defaultBg);

    final effectiveTextColor = isSelected
        ? AppTheme.primaryGreen
        : (textColor ?? defaultText);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Material(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(36),
            splashColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
            highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : (isDark ? AppTheme.darkBorder.withValues(alpha: 0.4) : Colors.transparent),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: effectiveTextColor, size: 24)
                    : Text(
                        text ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: isOperator ? 28 : 24,
                          fontWeight: isOperator ? FontWeight.w500 : FontWeight.w600,
                          color: effectiveTextColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroEqualButton() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Material(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            onTap: _onEqualPressed,
            borderRadius: BorderRadius.circular(36),
            splashColor: Colors.white.withValues(alpha: 0.25),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
              ),
              child: Center(
                child: Text(
                  '=',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
