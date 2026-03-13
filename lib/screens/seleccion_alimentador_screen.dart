import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/awg_calculator.dart';

class SeleccionAlimentadorScreen extends StatefulWidget {
  const SeleccionAlimentadorScreen({super.key});

  @override
  State<SeleccionAlimentadorScreen> createState() =>
      _SeleccionAlimentadorScreenState();
}

class _SeleccionAlimentadorScreenState extends State<SeleccionAlimentadorScreen>
    with SingleTickerProviderStateMixin {
  // ── Tensiones válidas por sistema ───────────────────────────────────────────
  static const Map<String, Map<String, String>> _voltagesBySystem = {
    'monofasico': {'120': '120 V', '127': '127 V', '277': '277 V'},
    'trifasico': {
      '208': '208 V',
      '220': '220 V',
      '440': '440 V',
      '460': '460 V'
    },
  };

  // ── Estado formulario principal ───────────────────────────────────────────
  String _material = 'Cu';
  int _temperature = 60;
  int _environmentTemperature = 30;
  int _occupation = 3;
  final _currentController = TextEditingController();

  // ── Estado verificación caída de tensión ──────────────────────────────────
  bool _showVoltageDrop = false;
  String _systemType = 'trifasico';
  double _voltage = 208;
  String _voltageStr = '208';
  double _fp = 0.9;
  String _fpStr = '0.9';
  String _conduit = 'PVC';
  final _longController = TextEditingController();

  // ── Resultados ────────────────────────────────────────────────────────────
  String? _awgByCurrent;
  String? _awgByVoltageDrop;

  // ── Animación resultado ───────────────────────────────────────────────────
  late AnimationController _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _currentController.addListener(_recalculate);
    _longController.addListener(_recalculateVoltageDrop);
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    _currentController.dispose();
    _longController.dispose();
    super.dispose();
  }

  // ── Lógica de cálculo ─────────────────────────────────────────────────────

  void _resetVoltageIfNeeded(String newSystem) {
    final validVoltages = _voltagesBySystem[newSystem]!;
    if (!validVoltages.containsKey(_voltageStr)) {
      _voltageStr = validVoltages.keys.first;
      _voltage = double.parse(_voltageStr);
    }
  }

  void _recalculate() {
    final currentVal = double.tryParse(_currentController.text);
    if (currentVal == null || currentVal <= 0) {
      setState(() {
        _awgByCurrent = null;
        _awgByVoltageDrop = null;
        _showVoltageDrop = false;
      });
      _resultAnim.reset();
      return;
    }

    if (currentVal > 100 && _temperature == 60) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWarningDialog(
          'Atención',
          'La corriente máxima para conductores de 60°C es 100 A. Se recomienda cambiar a 75°C.',
        );
        setState(() => _temperature = 75);
      });
    }

    final awg = getAwgByCurrent(
      material: _material,
      temperature: _temperature,
      environmentTemperature: _environmentTemperature,
      occupation: _occupation,
      current: currentVal,
    );

    setState(() => _awgByCurrent = awg);
    if (awg != null) _resultAnim.forward(from: 0);
    _recalculateVoltageDrop();
  }

  void _recalculateVoltageDrop() {
    final currentVal = double.tryParse(_currentController.text);
    final longVal = double.tryParse(_longController.text);
    if (currentVal == null || longVal == null || _awgByCurrent == null) {
      setState(() => _awgByVoltageDrop = null);
      return;
    }
    final awg = checkVoltageDrop(
      systemType: _systemType,
      material: _material,
      conduit: _conduit,
      voltage: _voltage,
      fp: _fp,
      current: currentVal,
      awgByCurrent: _awgByCurrent,
      longitud: longVal,
    );
    setState(() => _awgByVoltageDrop = awg);
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.white,
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFE8A020), size: 36),
        title: Text(title,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                color: AppTheme.black)),
        content: Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
                fontSize: 14, color: AppTheme.lightGray, height: 1.4)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.limeGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Entendido',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          'Selección de Alimentador',
          style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sección: Material ──────────────────────────────────────
              _sectionLabel('Material del conductor'),
              const SizedBox(height: 10),
              _materialSelector(),

              const SizedBox(height: 24),

              // ── Sección: Temperatura conductor ────────────────────────
              _sectionLabel('Temperatura del conductor'),
              const SizedBox(height: 10),
              _tempSelector(),

              const SizedBox(height: 24),

              // ── Sección: Temperatura ambiente ─────────────────────────
              _sectionLabel('Temperatura ambiente'),
              const SizedBox(height: 10),
              _buildDropdown<int>(
                value: _environmentTemperature,
                items: const {
                  25: '21 – 25 °C',
                  30: '26 – 30 °C',
                  35: '31 – 35 °C',
                  40: '36 – 40 °C',
                  45: '41 – 45 °C',
                  50: '46 – 50 °C',
                  55: '51 – 55 °C',
                  60: '56 – 60 °C',
                  70: '61 – 70 °C',
                  80: '71 – 80 °C',
                },
                icon: Icons.thermostat_outlined,
                onChanged: (v) {
                  setState(() => _environmentTemperature = v!);
                  _recalculate();
                },
              ),

              const SizedBox(height: 24),

              // ── Sección: Portadores de corriente ──────────────────────
              _sectionLabel('Portadores de corriente en ducto'),
              const SizedBox(height: 10),
              _buildDropdown<int>(
                value: _occupation,
                items: const {
                  3: 'De 1 a 3',
                  6: 'De 4 a 6',
                  9: 'De 7 a 9',
                  20: 'De 10 a 20',
                  30: 'De 21 a 30',
                  40: 'De 31 a 40',
                  100: 'De 41 y más',
                },
                icon: Icons.electrical_services_outlined,
                onChanged: (v) {
                  setState(() => _occupation = v!);
                  _recalculate();
                },
              ),

              const SizedBox(height: 24),

              // ── Sección: Corriente ─────────────────────────────────────
              _sectionLabel('Corriente de diseño'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _currentController,
                hint: 'Ingresa los amperios',
                suffix: 'A',
                icon: Icons.bolt_outlined,
              ),

              // ── Resultado por corriente ────────────────────────────────
              if (_awgByCurrent != null) ...[
                const SizedBox(height: 28),
                _buildResultCard(
                  label: 'Por capacidad de corriente',
                  awg: _awgByCurrent!,
                  anim: _resultAnim,
                  action: _awgByCurrent != null
                      ? _ActionButton(
                          label: _showVoltageDrop
                              ? 'Ocultar verificación'
                              : 'Verificar caída de tensión',
                          icon: _showVoltageDrop
                              ? Icons.expand_less_rounded
                              : Icons.electric_bolt_rounded,
                          onTap: () => setState(
                              () => _showVoltageDrop = !_showVoltageDrop),
                        )
                      : null,
                ),
              ],

              // ── Sección verificación caída de tensión ──────────────────
              if (_showVoltageDrop && _awgByCurrent != null) ...[
                const SizedBox(height: 28),
                _voltageDivider(),
                const SizedBox(height: 24),

                // Sistema
                _sectionLabel('Tipo de sistema'),
                const SizedBox(height: 10),
                _systemSelector(),

                const SizedBox(height: 24),

                // Tensión
                _sectionLabel('Tensión de línea'),
                const SizedBox(height: 10),
                _buildDropdown<String>(
                  value: _voltageStr,
                  items: const {
                    '120': '120 V',
                    '127': '127 V',
                    '208': '208 V',
                    '220': '220 V',
                    '240': '240 V',
                    '277': '277 V',
                    '440': '440 V',
                    '460': '460 V',
                  },
                  icon: Icons.power_input_outlined,
                  onChanged: (v) {
                    setState(() {
                      _voltageStr = v!;
                      _voltage = double.parse(v);
                    });
                    _recalculateVoltageDrop();
                  },
                ),

                const SizedBox(height: 24),

                // Factor de potencia
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
                    _recalculateVoltageDrop();
                  },
                ),

                const SizedBox(height: 24),

                // Canalización
                _sectionLabel('Tipo de canalización'),
                const SizedBox(height: 10),
                _conduitSelector(),

                const SizedBox(height: 24),

                // Longitud
                _sectionLabel('Longitud del tramo'),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _longController,
                  hint: 'Ingresa la longitud',
                  suffix: 'm',
                  icon: Icons.straighten_outlined,
                ),

                // Resultado por caída de tensión
                if (_awgByVoltageDrop != null) ...[
                  const SizedBox(height: 28),
                  _buildResultCard(
                    label: 'Por caída de tensión (máx. 3%)',
                    awg: _awgByVoltageDrop!,
                    anim: _resultAnim,
                    accent: true,
                    action: _ActionButton(
                      label: 'Aceptar y cerrar',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => setState(() => _showVoltageDrop = false),
                      secondary: true,
                    ),
                  ),
                ],
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
                })),
        const SizedBox(width: 12),
        Expanded(
            child: _toggleChip(
                label: 'Aluminio',
                value: 'Al',
                group: _material,
                onTap: () {
                  setState(() => _material = 'Al');
                  _recalculate();
                })),
      ],
    );
  }

  Widget _tempSelector() {
    return Row(
      children: [
        Expanded(
            child: _toggleChip(
                label: '60 °C',
                value: 60,
                group: _temperature,
                onTap: () {
                  setState(() => _temperature = 60);
                  _recalculate();
                })),
        const SizedBox(width: 10),
        Expanded(
            child: _toggleChip(
                label: '75 °C',
                value: 75,
                group: _temperature,
                onTap: () {
                  setState(() => _temperature = 75);
                  _recalculate();
                })),
        const SizedBox(width: 10),
        Expanded(
            child: _toggleChip(
                label: '90 °C',
                value: 90,
                group: _temperature,
                onTap: () {
                  _showWarningDialog(
                      'Atención', 'Considerar terminales a 90°C.');
                  setState(() => _temperature = 90);
                  _recalculate();
                })),
      ],
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
                  setState(() => _systemType = 'monofasico');
                  _recalculateVoltageDrop();
                })),
        const SizedBox(width: 12),
        Expanded(
            child: _toggleChip(
                label: 'Trifásico',
                value: 'trifasico',
                group: _systemType,
                onTap: () {
                  setState(() => _systemType = 'trifasico');
                  _recalculateVoltageDrop();
                })),
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
                  _recalculateVoltageDrop();
                })),
        const SizedBox(width: 12),
        Expanded(
            child: _toggleChip(
                label: 'Metálica',
                value: 'ACERO',
                group: _conduit,
                onTap: () {
                  setState(() => _conduit = 'ACERO');
                  _recalculateVoltageDrop();
                })),
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
                    .map((e) =>
                        DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
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
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
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
            child: Text(suffix,
                style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightGray)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String label,
    required String awg,
    required AnimationController anim,
    bool accent = false,
    _ActionButton? action,
  }) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: accent
                  ? [const Color(0xFF6FA832), AppTheme.limeGreen]
                  : [AppTheme.limeGreen, const Color(0xFF9ED64A)],
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AWG',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    awg,
                    style: GoogleFonts.rajdhani(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: action.onTap,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: action.secondary
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action.icon,
                            size: 18,
                            color: action.secondary
                                ? Colors.white
                                : AppTheme.limeGreenDark),
                        const SizedBox(width: 8),
                        Text(
                          action.label,
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: action.secondary
                                ? Colors.white
                                : AppTheme.limeGreenDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _voltageDivider() {
    return Row(
      children: [
        Expanded(
            child: Container(
                height: 1, color: AppTheme.lightGray.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.limeGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.limeGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.electric_bolt_rounded,
                    size: 14, color: AppTheme.limeGreenDark),
                const SizedBox(width: 6),
                Text('Verificación de caída de tensión',
                    style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.limeGreenDark,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
        Expanded(
            child: Container(
                height: 1, color: AppTheme.lightGray.withOpacity(0.2))),
      ],
    );
  }
}

// ── Modelo simple para el botón de acción en la tarjeta resultado ─────────────
class _ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool secondary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.secondary = false,
  });
}
