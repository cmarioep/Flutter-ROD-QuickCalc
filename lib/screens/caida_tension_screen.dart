import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/awg_calculator.dart';

class CaidaTensionScreen extends StatefulWidget {
  const CaidaTensionScreen({super.key});

  @override
  State<CaidaTensionScreen> createState() => _CaidaTensionScreenState();
}

class _CaidaTensionScreenState extends State<CaidaTensionScreen>
    with SingleTickerProviderStateMixin {
  // ── Tensiones válidas por sistema ───────────────────────────────────────────
  static const Map<String, Map<String, String>> _voltagesBySystem = {
    'monofasico': {
      '120': '120 V',
      '127': '127 V',
      '277': '277 V'
    },
    'trifasico': {
      '208': '208 V',
      '220': '220 V',
      '440': '440 V',
      '460': '460 V'
    },
  };

  // ── Estado del formulario ────────────────────────────────────────────────
  String _systemType = 'trifasico';
  String _voltageStr = '208';
  double _voltage = 208;
  String _loadType = 'Amperios';
  String _material = 'Cu';
  String _awg = '';
  String _conduit = 'PVC';
  String _fpStr = '0.9';
  double _fp = 0.9;

  final _loadController = TextEditingController();
  final _longController = TextEditingController();

  // ── Resultado ────────────────────────────────────────────────────────────
  double? _voltageDrop;
  late AnimationController _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadController.addListener(_recalculate);
    _longController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    _loadController.dispose();
    _longController.dispose();
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
    final longVal = double.tryParse(_longController.text);

    if (loadVal == null ||
        loadVal <= 0 ||
        longVal == null ||
        longVal <= 0 ||
        _awg.isEmpty) {
      setState(() => _voltageDrop = null);
      _resultAnim.reset();
      return;
    }

    final drop = getVoltageDrop(
      type: _systemType,
      material: _material,
      conduit: _conduit,
      voltage: _voltage,
      fp: _fp,
      loadType: _loadType,
      loadCurrent: loadVal,
      awg: _awg,
      longitud: longVal,
    );

    setState(() => _voltageDrop = drop);
    _resultAnim.forward(from: 0);
  }

  void _reset() {
    _loadController.clear();
    _longController.clear();
    setState(() {
      _systemType = 'trifasico';
      _voltageStr = '208';
      _voltage = 208;
      _loadType = 'Amperios';
      _material = 'Cu';
      _awg = '';
      _conduit = 'PVC';
      _fpStr = '0.9';
      _fp = 0.9;
      _voltageDrop = null;
    });
    _resultAnim.reset();
  }

  // ── Color según nivel de caída ────────────────────────────────────────────
  Color _dropColor(double drop) {
    if (drop <= 3) return AppTheme.limeGreen;
    if (drop <= 5) return const Color(0xFFE8A020);
    return const Color(0xFFD93025);
  }

  String _dropLabel(double drop) {
    if (drop <= 3) return 'Dentro del límite permitido (≤ 3%)';
    if (drop <= 5) return 'Advertencia: supera el 3% recomendado';
    return 'Crítico: supera el 5% máximo';
  }

  IconData _dropIcon(double drop) {
    if (drop <= 3) return Icons.check_circle_rounded;
    if (drop <= 5) return Icons.warning_amber_rounded;
    return Icons.cancel_rounded;
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
          'Caída de Tensión',
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
              // ── Sistema ──────────────────────────────────────────────────
              _sectionLabel('Tipo de sistema'),
              const SizedBox(height: 10),
              _systemSelector(),

              const SizedBox(height: 24),

              // ── Tensión ──────────────────────────────────────────────────
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

              // ── Tipo de carga ─────────────────────────────────────────────
              _sectionLabel('Tipo de carga'),
              const SizedBox(height: 10),
              _loadTypeSelector(),

              const SizedBox(height: 24),

              // ── Valor de carga ────────────────────────────────────────────
              _sectionLabel(_loadType == 'kVA'
                  ? 'Potencia de la carga'
                  : 'Corriente de la carga'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _loadController,
                hint: _loadType == 'kVA'
                    ? 'Ingresa los kVA'
                    : 'Ingresa los amperios',
                suffix: _loadType == 'kVA' ? 'kVA' : 'A',
                icon: _loadType == 'kVA'
                    ? Icons.flash_on_outlined
                    : Icons.bolt_outlined,
              ),

              // Factor de potencia — solo visible si la carga es kVA
              if (_loadType == 'kVA') ...[
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

              // ── Material ──────────────────────────────────────────────────
              _sectionLabel('Material del alimentador'),
              const SizedBox(height: 10),
              _materialSelector(),

              const SizedBox(height: 24),

              // ── Calibre AWG ───────────────────────────────────────────────
              _sectionLabel('Calibre AWG'),
              const SizedBox(height: 10),
              _buildDropdown<String>(
                value: _awg.isEmpty ? '' : _awg,
                items: const {
                  '': 'Seleccionar calibre',
                  '14': '14',
                  '12': '12',
                  '10': '10',
                  '8': '8',
                  '6': '6',
                  '4': '4',
                  '2': '2',
                  '1/0': '1/0',
                  '2/0': '2/0',
                  '4/0': '4/0',
                  '250': '250 kcmil',
                  '300': '300 kcmil',
                  '350': '350 kcmil',
                  '500': '500 kcmil',
                  '750': '750 kcmil',
                },
                icon: Icons.cable_outlined,
                onChanged: (v) {
                  setState(() => _awg = v ?? '');
                  _recalculate();
                },
              ),

              const SizedBox(height: 24),

              // ── Canalización ──────────────────────────────────────────────
              _sectionLabel('Tipo de canalización'),
              const SizedBox(height: 10),
              _conduitSelector(),

              const SizedBox(height: 24),

              // ── Longitud ──────────────────────────────────────────────────
              _sectionLabel('Longitud del tramo'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _longController,
                hint: 'Ingresa la longitud',
                suffix: 'm',
                icon: Icons.straighten_outlined,
              ),

              // ── Resultado ─────────────────────────────────────────────────
              if (_voltageDrop != null) ...[
                const SizedBox(height: 28),
                _buildResultCard(_voltageDrop!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets de UI ─────────────────────────────────────────────────────────

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

  Widget _systemSelector() {
    return Row(
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
        const SizedBox(width: 12),
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
    );
  }

  Widget _loadTypeSelector() {
    return Row(
      children: [
        Expanded(
            child: _toggleChip(
          label: 'Amperios',
          value: 'Amperios',
          group: _loadType,
          onTap: () {
            setState(() => _loadType = 'Amperios');
            _recalculate();
          },
        )),
        const SizedBox(width: 12),
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
      ],
    );
  }

  Widget _materialSelector() {
    return Row(
      children: [
        Expanded(
            child: _toggleChip(
          label: 'Cobre',
          value: 'Cu',
          group: _material,
          onTap: () {
            setState(() => _material = 'Cu');
            _recalculate();
          },
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _toggleChip(
          label: 'Aluminio',
          value: 'Al',
          group: _material,
          onTap: () {
            setState(() => _material = 'Al');
            _recalculate();
          },
        )),
      ],
    );
  }

  Widget _conduitSelector() {
    return Row(
      children: [
        Expanded(
            child: _toggleChip(
          label: 'PVC',
          value: 'PVC',
          group: _conduit,
          onTap: () {
            setState(() => _conduit = 'PVC');
            _recalculate();
          },
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _toggleChip(
          label: 'Metálica',
          value: 'ACERO',
          group: _conduit,
          onTap: () {
            setState(() => _conduit = 'ACERO');
            _recalculate();
          },
        )),
      ],
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

  Widget _buildResultCard(double drop) {
    final color = _dropColor(drop);
    final label = _dropLabel(drop);
    final icon = _dropIcon(drop);

    return FadeTransition(
      opacity: _resultAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etiqueta superior
              Text(
                'REGULACIÓN DE TENSIÓN',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightGray,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),

              // Valor principal
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    drop.toStringAsFixed(2),
                    style: GoogleFonts.rajdhani(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      '%',
                      style: GoogleFonts.rajdhani(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (drop / 6).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.offWhite,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: 14),

              // Estado
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
