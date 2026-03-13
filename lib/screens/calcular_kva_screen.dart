import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/electrical_constants.dart';

class CalcularKvaScreen extends StatefulWidget {
  const CalcularKvaScreen({super.key});

  @override
  State<CalcularKvaScreen> createState() => _CalcularKvaScreenState();
}

class _CalcularKvaScreenState extends State<CalcularKvaScreen>
    with SingleTickerProviderStateMixin {
  // ── Tensiones válidas por sistema ─────────────────────────────────────────
  static const Map<String, Map<String, String>> _voltagesBySystem = {
    'monofasico': {'120': '120 V', '127': '127 V', '277': '277 V'},
    'bifasico': {'208': '208 V', '240': '240 V'},
    'trifasico': {
      '208': '208 V',
      '220': '220 V',
      '440': '440 V',
      '460': '460 V'
    },
  };

  // ── Estado ────────────────────────────────────────────────────────────────
  String _systemType = 'trifasico';
  String _voltageStr = '208';
  double _voltage = 208;

  final _currentController = TextEditingController();

  // ── Resultado ─────────────────────────────────────────────────────────────
  double? _kva;
  late AnimationController _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _currentController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    _currentController.dispose();
    super.dispose();
  }

  void _resetVoltageIfNeeded(String newSystem) {
    final valid = _voltagesBySystem[newSystem]!;
    if (!valid.containsKey(_voltageStr)) {
      _voltageStr = valid.keys.first;
      _voltage = double.parse(_voltageStr);
    }
  }

  void _recalculate() {
    final currentVal = double.tryParse(_currentController.text);
    if (currentVal == null || currentVal <= 0) {
      setState(() => _kva = null);
      _resultAnim.reset();
      return;
    }

    final result = getLoadPower(
      current: currentVal,
      type: _systemType,
      voltage: _voltage,
    );

    setState(() => _kva = result);
    _resultAnim.forward(from: 0);
  }

  void _reset() {
    _currentController.clear();
    setState(() {
      _systemType = 'trifasico';
      _voltageStr = '208';
      _voltage = 208;
      _kva = null;
    });
    _resultAnim.reset();
  }

  // ── Fórmula según sistema ─────────────────────────────────────────────────
  String _formula() {
    switch (_systemType) {
      case 'trifasico':
        return 'S = (√3 × V × I) / 1000';
      default:
        return 'S = (V × I) / 1000';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.limeGreen,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calcular kVA',
          style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reiniciar',
            onPressed: _reset,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 20, 16, MediaQuery.of(context).size.height * 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tipo de sistema ───────────────────────────────────────
              _sectionLabel('Tipo de sistema'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _toggleChip(
                    label: 'Monofásico',
                    value: 'monofasico',
                    group: _systemType,
                    onTap: () => setState(() {
                      _systemType = 'monofasico';
                      _resetVoltageIfNeeded('monofasico');
                      _recalculate();
                    }),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _toggleChip(
                    label: 'Bifásico',
                    value: 'bifasico',
                    group: _systemType,
                    onTap: () => setState(() {
                      _systemType = 'bifasico';
                      _resetVoltageIfNeeded('bifasico');
                      _recalculate();
                    }),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _toggleChip(
                    label: 'Trifásico',
                    value: 'trifasico',
                    group: _systemType,
                    onTap: () => setState(() {
                      _systemType = 'trifasico';
                      _resetVoltageIfNeeded('trifasico');
                      _recalculate();
                    }),
                  )),
                ],
              ),

              const SizedBox(height: 24),

              // ── Tensión ───────────────────────────────────────────────
              _sectionLabel('Tensión de línea'),
              const SizedBox(height: 10),
              _buildDropdown<String>(
                value: _voltageStr,
                items: _voltagesBySystem[_systemType]!,
                icon: Icons.power_input_outlined,
                onChanged: (v) {
                  setState(() {
                    _voltageStr = v!;
                    _voltage = double.parse(v);
                  });
                  _recalculate();
                },
              ),

              const SizedBox(height: 24),

              // ── Corriente ─────────────────────────────────────────────
              _sectionLabel('Corriente de carga'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _currentController,
                hint: 'Ingresa los amperios',
                suffix: 'A',
                icon: Icons.bolt_outlined,
              ),

              const SizedBox(height: 20),

              // ── Chip de fórmula ───────────────────────────────────────
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey(_systemType),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.limeGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.limeGreen.withOpacity(0.3)),
                    ),
                    child: Text(
                      _formula(),
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.limeGreenDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Resultado ─────────────────────────────────────────────
              if (_kva != null) ...[
                const SizedBox(height: 28),
                _buildResultCard(_kva!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.lightGray,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _toggleChip<T>({
    required String label,
    required T value,
    required T group,
    required VoidCallback onTap,
  }) {
    final selected = value == group;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppTheme.limeGreen : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.limeGreen
                : AppTheme.lightGray.withOpacity(0.3),
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppTheme.limeGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.darkGray,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required Map<T, String> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.limeGreen),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.lightGray, size: 22),
                style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600),
                items: items.entries
                    .map((e) => DropdownMenuItem<T>(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.limeGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: GoogleFonts.rajdhani(
                  fontSize: 15,
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.rajdhani(
                    fontSize: 14, color: AppTheme.lightGray.withOpacity(0.7)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              suffix,
              style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(double kva) {
    return FadeTransition(
      opacity: _resultAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.limeGreen, Color(0xFF9ED64A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.limeGreen.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POTENCIA APARENTE',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    kva.toStringAsFixed(2),
                    style: GoogleFonts.rajdhani(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 6),
                    child: Text(
                      'kVA',
                      style: GoogleFonts.rajdhani(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(
                        'Sistema',
                        _systemType == 'trifasico'
                            ? 'Trifásico'
                            : _systemType == 'bifasico'
                                ? 'Bifásico'
                                : 'Monofásico'),
                    _infoChip('Tensión', '$_voltageStr V'),
                    _infoChip('Fórmula', _formula()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.rajdhani(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        Text(value,
            style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
