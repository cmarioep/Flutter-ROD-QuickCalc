import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/electrical_constants.dart';

class OcupacionDuctosScreen extends StatefulWidget {
  const OcupacionDuctosScreen({super.key});

  @override
  State<OcupacionDuctosScreen> createState() => _OcupacionDuctosScreenState();
}

class _OcupacionDuctosScreenState extends State<OcupacionDuctosScreen>
    with SingleTickerProviderStateMixin {
  // ── Estado ────────────────────────────────────────────────────────────────
  String _conduitType = '';
  String _conduitSize = '';

  final List<Map<String, dynamic>> _conductors = [
    {'awg': '', 'insulation': '', 'qty': null},
  ];

  double? _occupancy;
  late AnimationController _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _recalculate();
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  void _recalculate() {
    if (_conduitType.isEmpty || _conduitSize.isEmpty) {
      setState(() => _occupancy = null);
      return;
    }
    final conduitArea = conduitAreas[_conduitType]?[_conduitSize];
    if (conduitArea == null) {
      setState(() => _occupancy = null);
      return;
    }

    double totalConductorArea = 0;
    for (final c in _conductors) {
      final ins = c['insulation'] as String;
      final awg = c['awg'] as String;
      final qty = c['qty'] as int?;
      if (ins.isEmpty || awg.isEmpty || qty == null) continue;
      final area = conductorAreas[ins]?[awg];
      if (area != null) totalConductorArea += area * qty;
    }

    if (totalConductorArea <= 0) {
      setState(() => _occupancy = null);
      return;
    }

    final occ = (totalConductorArea / conduitArea) * 100;
    setState(() => _occupancy = double.parse(occ.toStringAsFixed(1)));
    _resultAnim.forward(from: 0);
  }

  void _addConductor() {
    setState(() => _conductors.add({'awg': '', 'insulation': '', 'qty': null}));
    _recalculate();
  }

  void _removeConductor(int index) {
    if (_conductors.length == 1) return;
    setState(() => _conductors.removeAt(index));
    _recalculate();
  }

  void _reset() {
    setState(() {
      _conduitType = '';
      _conduitSize = '';
      _conductors
        ..clear()
        ..add({'awg': '', 'insulation': '', 'qty': null});
      _occupancy = null;
    });
    _resultAnim.reset();
    _recalculate();
  }

  Color _occColor(double occ) {
    if (occ <= 33) return AppTheme.limeGreen;
    if (occ <= 40) return const Color(0xFFE8A020);
    return const Color(0xFFD93025);
  }

  String _occLabel(double occ) {
    if (occ <= 33) return 'Óptimo — por debajo del 33% recomendado';
    if (occ <= 40) return 'Aceptable — entre 33% y 40% permitido';
    return 'Excede el límite máximo del 40%';
  }

  IconData _occIcon(double occ) {
    if (occ <= 33) return Icons.check_circle_rounded;
    if (occ <= 40) return Icons.warning_amber_rounded;
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
        title: Text('Ocupación de Ductos',
            style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3)),
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
              _sectionLabel('Tipo de ducto'),
              const SizedBox(height: 10),
              _buildDropdown<String>(
                value: _conduitType,
                items: const {
                  '': 'Tipo de ducto',
                  'PVC TL': 'PVC TL',
                  'EMT': 'EMT',
                  'SCH-40': 'SCH-40',
                  'IMC': 'IMC'
                },
                icon: Icons.circle_outlined,
                onChanged: (v) {
                  setState(() => _conduitType = v!);
                  _recalculate();
                },
              ),
              const SizedBox(height: 20),
              _sectionLabel('Diámetro nominal'),
              const SizedBox(height: 10),
              _buildDropdown<String>(
                value: _conduitSize,
                items: const {
                  '': 'Diámetro',
                  '1/2"': '1/2"',
                  '3/4"': '3/4"',
                  '1"': '1"',
                  '1-1/4"': '1-1/4"',
                  '1-1/2"': '1-1/2"',
                  '2"': '2"',
                  '2-1/2"': '2-1/2"',
                  '3"': '3"',
                  '4"': '4"',
                },
                icon: Icons.settings_ethernet_rounded,
                onChanged: (v) {
                  setState(() => _conduitSize = v!);
                  _recalculate();
                },
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Conductores'),
                  GestureDetector(
                    onTap: _addConductor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.limeGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.limeGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text('Agregar',
                              style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(
                  _conductors.length, (i) => _buildConductorRow(i)),
              if (_occupancy != null) ...[
                const SizedBox(height: 28),
                _buildResultCard(_occupancy!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConductorRow(int index) {
    final c = _conductors[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.lightGray.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _miniDropdown<String>(
                label: 'Calibre',
                value: c['awg'] as String,
                items: const {
                  '': 'Calibre',
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
                  '250': '250',
                  '300': '300',
                  '350': '350',
                  '500': '500',
                  '750': '750',
                },
                onChanged: (v) {
                  setState(() => _conductors[index]['awg'] = v!);
                  _recalculate();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _miniDropdown<String>(
                label: 'Aislamiento',
                value: c['insulation'] as String,
                items: const {
                  '': 'Aislamiento',
                  'THHN/THWN': 'THHN/THWN',
                  'THHW': 'THHW'
                },
                onChanged: (v) {
                  setState(() => _conductors[index]['insulation'] = v!);
                  _recalculate();
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: _qtyField(index, c['qty'] as int?)),
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded,
                  color: _conductors.length > 1
                      ? const Color(0xFFD93025).withOpacity(0.7)
                      : AppTheme.lightGray.withOpacity(0.3),
                  size: 22),
              onPressed:
                  _conductors.length > 1 ? () => _removeConductor(index) : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniDropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.rajdhani(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightGray,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.lightGray.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.lightGray, size: 16),
              style: GoogleFonts.rajdhani(
                  fontSize: 13,
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
    );
  }

  Widget _qtyField(int index, int? qty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cantidad',
            style: GoogleFonts.rajdhani(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightGray,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.lightGray.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: (qty != null && qty > 1)
                    ? () {
                        setState(() => _conductors[index]['qty'] = qty - 1);
                        _recalculate();
                      }
                    : null,
                child: Container(
                    width: 26,
                    alignment: Alignment.center,
                    child: Icon(Icons.remove_rounded,
                        size: 14,
                        color: (qty != null && qty > 1)
                            ? AppTheme.darkGray
                            : AppTheme.lightGray.withOpacity(0.3))),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    qty != null ? '$qty' : '-',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.black),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _conductors[index]['qty'] = (qty ?? 0) + 1);
                  _recalculate();
                },
                child: Container(
                    width: 26,
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_rounded,
                        size: 14, color: AppTheme.darkGray)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(double occ) {
    final color = _occColor(occ);
    final label = _occLabel(occ);
    final icon = _occIcon(occ);
    final conduitArea = conduitAreas[_conduitType]?[_conduitSize] ?? 0.0;
    final usedArea = conduitArea * occ / 100;

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
                  offset: const Offset(0, 6))
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OCUPACIÓN DEL DUCTO',
                  style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightGray,
                      letterSpacing: 1.8)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(occ.toStringAsFixed(1),
                      style: GoogleFonts.rajdhani(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('%',
                        style: GoogleFonts.rajdhani(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: color.withOpacity(0.7))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildOccupancyBar(occ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(label,
                          style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _areaDetail(
                        'Área ducto',
                        '${conduitArea.toStringAsFixed(0)} mm²',
                        Icons.circle_outlined),
                    Container(
                        width: 1,
                        height: 36,
                        color: AppTheme.lightGray.withOpacity(0.2)),
                    _areaDetail(
                        'Área usada',
                        '${usedArea.toStringAsFixed(1)} mm²',
                        Icons.cable_rounded),
                    Container(
                        width: 1,
                        height: 36,
                        color: AppTheme.lightGray.withOpacity(0.2)),
                    _areaDetail(
                        'Conductores',
                        '${_conductors.fold(0, (s, c) => s + ((c['qty'] as int?) ?? 0))}',
                        Icons.electrical_services_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyBar(double occ) {
    return Stack(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(height: 10, color: AppTheme.offWhite)),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.33 * 0.72,
          top: 0,
          bottom: 0,
          child:
              Container(width: 2, color: AppTheme.limeGreen.withOpacity(0.5)),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.40 * 0.72,
          top: 0,
          bottom: 0,
          child: Container(
              width: 2, color: const Color(0xFFE8A020).withOpacity(0.5)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (occ / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(_occColor(occ)),
          ),
        ),
      ],
    );
  }

  Widget _areaDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.lightGray),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.rajdhani(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.black)),
        Text(label,
            style: GoogleFonts.rajdhani(
                fontSize: 10, color: AppTheme.lightGray, letterSpacing: 0.3)),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(),
        style: GoogleFonts.rajdhani(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightGray,
            letterSpacing: 1.8));
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
}
