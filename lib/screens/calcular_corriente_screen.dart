import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/electrical_constants.dart';

class CalcularCorrienteScreen extends StatefulWidget {
  const CalcularCorrienteScreen({super.key});

  @override
  State<CalcularCorrienteScreen> createState() =>
      _CalcularCorrienteScreenState();
}

class _CalcularCorrienteScreenState extends State<CalcularCorrienteScreen>
    with SingleTickerProviderStateMixin {
  // ── Tensiones válidas por sistema ───────────────────────────────────────────
  static const Map<String, Map<String, String>> _voltagesBySystem = {
    'monofasico': {
      '120': '120 V',
      '127': '127 V',
      '277': '277 V',
    },
    'bifasico': {
      '240': '240 V',
      '208': '208 V',
    },
    'trifasico': {
      '208': '208 V',
      '220': '220 V',
      '440': '440 V',
      '460': '460 V',
    },
  };

  // ── Estado ───────────────────────────────────────────────────────────────
  String _loadType = 'kVA';
  String _systemType = 'trifasico';
  String _voltageStr = '208';
  double _voltage = 208;
  String _fpStr = '0.9';
  double _fp = 0.9;

  final _loadController = TextEditingController();

  // ── Resultado ────────────────────────────────────────────────────────────
  double? _current;
  late AnimationController _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    _loadController.dispose();
    super.dispose();
  }

  void _resetVoltageIfNeeded(String newSystem) {
    final validVoltages = _voltagesBySystem[newSystem]!;
    if (!validVoltages.containsKey(_voltageStr)) {
      _voltageStr = validVoltages.keys.first;
      _voltage = double.parse(_voltageStr);
    }
  }

  void _recalculate() {
    final loadVal = double.tryParse(_loadController.text);
    if (loadVal == null || loadVal <= 0) {
      setState(() => _current = null);
      _resultAnim.reset();
      return;
    }

    final result = getLoadCurrent(
      loadType: _loadType,
      load: loadVal,
      fp: _fp,
      type: _systemType,
      voltage: _voltage,
    );

    setState(() => _current = result);
    _resultAnim.forward(from: 0);
  }

  void _reset() {
    _loadController.clear();
    setState(() {
      _loadType = 'kVA';
      _systemType = 'trifasico';
      _voltageStr = '208';
      _voltage = 208;
      _fpStr = '0.9';
      _fp = 0.9;
      _current = null;
    });
    _resultAnim.reset();
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
          'Calcular Corriente',
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
              // ── Tipo de carga ─────────────────────────────────────────
              _sectionLabel('Tipo de carga'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _toggleChip(
                    label: 'kVA',
                    value: 'kVA',
                    group: _loadType,
                    onTap: () {
                      setState(() => _loadType = 'kVA');
                      _recalculate();
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _toggleChip(
                    label: 'kW',
                    value: 'kW',
                    group: _loadType,
                    onTap: () {
                      setState(() => _loadType = 'kW');
                      _recalculate();
                    },
                  )),
                ],
              ),

              const SizedBox(height: 24),

              // ── Valor de carga ────────────────────────────────────────
              _sectionLabel(
                  _loadType == 'kVA' ? 'Potencia aparente' : 'Potencia activa'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _loadController,
                hint: 'Ingresa el valor',
                suffix: _loadType,
                icon: Icons.flash_on_outlined,
              ),

              // ── Factor de potencia — solo si es kW ────────────────────
              if (_loadType == 'kW') ...[
                const SizedBox(height: 24),
                _sectionLabel('Factor de potencia'),
                const SizedBox(height: 10),
                _buildDropdown<String>(
                  value: _fpStr,
                  items: const {
                    '1.0': '1.00',
                    '0.95': '0.95',
                    '0.9': '0.90',
                    '0.85': '0.85',
                  },
                  icon: Icons.speed_outlined,
                  onChanged: (v) {
                    setState(() {
                      _fpStr = v!;
                      _fp = double.parse(v);
                    });
                    _recalculate();
                  },
                ),
              ],

              const SizedBox(height: 24),

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
                    onTap: () {
                      setState(() {
                        _systemType = 'monofasico';
                        _resetVoltageIfNeeded('monofasico');
                      });
                      _recalculate();
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _toggleChip(
                    label: 'Bifásico',
                    value: 'bifasico',
                    group: _systemType,
                    onTap: () {
                      setState(() {
                        _systemType = 'bifasico';
                        _resetVoltageIfNeeded('bifasico');
                      });
                      _recalculate();
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _toggleChip(
                    label: 'Trifásico',
                    value: 'trifasico',
                    group: _systemType,
                    onTap: () {
                      setState(() {
                        _systemType = 'trifasico';
                        _resetVoltageIfNeeded('trifasico');
                      });
                      _recalculate();
                    },
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

              // ── Resultado ─────────────────────────────────────────────
              if (_current != null) ...[
                const SizedBox(height: 32),
                _buildResultCard(_current!),
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
            fontSize: 15,
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

  Widget _buildResultCard(double current) {
    final current125 = double.parse((current * 1.25).toStringAsFixed(2));

    return FadeTransition(
      opacity: _resultAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut)),
        child: Column(
          children: [
            // ── Corriente nominal ──────────────────────────────────────
            Container(
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CORRIENTE DE CARGA',
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
                        current.toStringAsFixed(2),
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
                          'A',
                          style: GoogleFonts.rajdhani(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Corriente al 125% ──────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.limeGreen.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.limeGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppTheme.limeGreenDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corriente al 125%',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Para dimensionamiento de protecciones',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            color: AppTheme.lightGray.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${current125} A',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.limeGreenDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
