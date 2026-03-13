// import 'dart:math';

/// Verifica si el calibre obtenido por corriente satisface
/// también el límite de caída de tensión (máx 3%).
/// Retorna el calibre definitivo (puede ser mayor al de corriente).
// String? checkVoltageDrop({
//   required String systemType, // 'monofasico' | 'trifasico'
//   required String material,
//   required String conduit, // 'PVC' | 'ACERO'
//   required double voltage,
//   required double fp,
//   required double current,
//   required String? awgByCurrent,
//   required double longitud, // metros
// }) {
//   if (awgByCurrent == null || longitud <= 0) return awgByCurrent;

//   // Factor de longitud según sistema
//   // Monofásico: 2 × L (ida y vuelta), trifásico: √3 × L
//   final lengthFactor = systemType == 'trifasico' ? sqrt(3) : 2.0;

//   // Máxima caída permitida (3%)
//   final maxDrop = voltage * 0.03;

//   // Empezar desde el calibre obtenido por corriente e ir subiendo
//   int startIndex = awgOrder.indexOf(awgByCurrent);
//   if (startIndex < 0) startIndex = 0;

//   for (int i = startIndex; i < awgOrder.length; i++) {
//     final calibre = awgOrder[i];

//     final resistance = ((electrictParamsAWG['resistance'] as Map)[material]
//         as Map)[conduit][calibre] as double?;
//     final inductance = ((electrictParamsAWG['inductance']
//         as Map)[conduit])[calibre] as double?;

//     if (resistance == null || inductance == null) continue;

//     // Reactancia inductiva XL = ωL = 2π × 60 × L (en Ω/km)
//     final xl = 2 * pi * 60 * inductance / 1000;

//     // Impedancia por km
//     final sinFP = sqrt(1 - fp * fp);
//     final impedancePerKm = resistance * fp + xl * sinFP;

//     // Caída de tensión total
//     // ΔV = √3 × I × Z × L  (trifásico) | ΔV = 2 × I × Z × L (monofásico)
//     final drop = lengthFactor * current * impedancePerKm * (longitud / 1000);

//     if (drop <= maxDrop) {
//       return calibre;
//     }
//   }

//   return '750'; // Si ningún calibre estándar alcanza, recomendar el máximo
// }

import 'electrical_constants.dart';

// ── Tabla sinFP precalculada (igual que en JS) ────────────────────────────────
const Map<String, double> _sinFP = {
  '1.0': 0.0,
  '0.95': 0.31,
  '0.9': 0.44,
  '0.85': 0.53,
};

// ── Funciones internas ────────────────────────────────────────────────────────

double _getResistance(String material, String conduit, String awg) {
  return ((electrictParamsAWG['resistance'] as Map)[material] as Map)[conduit]
      [awg] as double;
}

double _getInductance(String conduit, String awg) {
  return ((electrictParamsAWG['inductance'] as Map)[conduit])[awg] as double;
}

double _getEffectiveImpedance(
    String material, String conduit, String awg, double fp) {
  final sin = _sinFP[fp.toString()] ?? _sinFP['0.9']!;
  final resistance = _getResistance(material, conduit, awg);
  final inductance = _getInductance(conduit, awg);
  final impedance = (resistance * fp) + (inductance * sin);
  return double.parse(impedance.toStringAsFixed(4));
}

double _getCurrentFromLoad({
  required String type,
  required double voltage,
  required String loadType,
  required double loadCurrent,
}) {
  final v = type == 'trifasico' ? 1.732 * voltage : voltage;
  if (loadType == 'kVA') return (loadCurrent * 1000) / v;
  return loadCurrent; // Amperios
}

// ── API pública ───────────────────────────────────────────────────────────────

/// Calcula el porcentaje de caída de tensión (%Reg)
double getVoltageDrop({
  required String type,
  required String material,
  required String conduit,
  required double voltage,
  required double fp,
  required String loadType,
  required double loadCurrent,
  required String awg,
  required double longitud,
}) {
  final current = _getCurrentFromLoad(
    type: type,
    voltage: voltage,
    loadType: loadType,
    loadCurrent: loadCurrent,
  );

  double deltaDrop = _getEffectiveImpedance(material, conduit, awg, fp) *
      (longitud / 1000) *
      current;

  deltaDrop = type == 'trifasico' ? 1.732 * deltaDrop : 2 * deltaDrop;

  final dropVoltage = (deltaDrop / voltage) * 100;
  return double.parse(dropVoltage.toStringAsFixed(2));
}

/// Verifica si el calibre cumple con máx 3% de caída.
/// Si no cumple, sube al siguiente calibre que sí lo haga.
String? checkVoltageDrop({
  required String systemType,
  required String material,
  required String conduit,
  required double voltage,
  required double fp,
  required double current,
  required String? awgByCurrent,
  required double longitud,
}) {
  if (awgByCurrent == null || longitud <= 0) return awgByCurrent;

  final initialDrop = getVoltageDrop(
    type: systemType,
    material: material,
    conduit: conduit,
    voltage: voltage,
    fp: fp,
    loadType: 'Amperios',
    loadCurrent: current,
    awg: awgByCurrent,
    longitud: longitud,
  );

  if (initialDrop <= 3) return awgByCurrent;

  // Buscar el siguiente calibre que cumpla
  int startIndex = awgOrder.indexOf(awgByCurrent);
  if (startIndex < 0) startIndex = 0;

  for (int i = startIndex + 1; i < awgOrder.length; i++) {
    final candidate = awgOrder[i];
    final drop = getVoltageDrop(
      type: systemType,
      material: material,
      conduit: conduit,
      voltage: voltage,
      fp: fp,
      loadType: 'Amperios',
      loadCurrent: current,
      awg: candidate,
      longitud: longitud,
    );
    if (drop <= 3) return candidate;
  }

  return awgByCurrent; // Si ninguno alcanza, retorna el original
}

/// Obtiene el calibre AWG por capacidad de corriente,
/// aplicando corrección por temperatura y agrupamiento.
String? getAwgByCurrent({
  required String material,
  required int temperature,
  required int environmentTemperature,
  required int occupation,
  required double current,
}) {
  // 1. Factor de corrección por temperatura ambiente
  final tempFactors = temperatureCorrectionFactor[temperature];
  if (tempFactors == null) return null;
  final tempFactor = tempFactors[environmentTemperature] ?? 1.0;

// 2. Factor de agrupamiento
  final densityFactor = conduitDensityFactor[occupation] ?? 1.0;

  // 3. Corriente corregida
  final correctedCurrent = current / (tempFactor * densityFactor);

// 4. Buscar el calibre mínimo que soporte la corriente corregida
  final materialTable =
      (currentAWG[material] as Map)[temperature] as Map<int, String>;

  // Ordenar las entradas de menor a mayor ampere
  final sortedEntries = materialTable.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in sortedEntries) {
    if (entry.key >= correctedCurrent) {
      return entry.value;
    }
  }
  return null; // Supera la capacidad máxima
}
