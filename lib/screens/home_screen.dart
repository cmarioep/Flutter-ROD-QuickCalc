import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_button.dart';
import 'login_screen.dart';
import 'seleccion_alimentador_screen.dart';
import 'caida_tension_screen.dart';
import 'calcular_corriente_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction_rounded,
                color: AppTheme.limeGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              '$feature — Próximamente',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.darkGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side:
              BorderSide(color: AppTheme.limeGreen.withOpacity(0.4), width: 1),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader()),

                // ── Divider ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppTheme.lightGray.withOpacity(0.25),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'HERRAMIENTAS',
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightGray.withOpacity(0.7),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppTheme.lightGray.withOpacity(0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Menu Buttons ─────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      MenuButton(
                        icon: Icons.electric_bolt_rounded,
                        label: 'Caída de Tensión',
                        subtitle: 'Cálculo de caída en conductores',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CaidaTensionScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MenuButton(
                        icon: Icons.cable_rounded,
                        label: 'Selección de Alimentador',
                        subtitle: 'Dimensionamiento de conductores',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SeleccionAlimentadorScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MenuButton(
                        icon: Icons.grid_view_rounded,
                        label: 'Ocupación de Ductos',
                        subtitle: 'Factor de relleno en tuberías',
                        onTap: () =>
                            _showComingSoon(context, 'Ocupación de Ductos'),
                      ),
                      const SizedBox(height: 12),
                      MenuButton(
                        icon: Icons.electrical_services_rounded,
                        label: 'Calcular Corriente',
                        subtitle: 'Corriente en circuitos eléctricos',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CalcularCorrienteScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MenuButton(
                        icon: Icons.power_rounded,
                        label: 'Calcular kVA',
                        subtitle: 'Potencia aparente del sistema',
                        onTap: () => _showComingSoon(context, 'Calcular kVA'),
                      ),
                    ]),
                  ),
                ),

                // ── Footer ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'v1.0.0  ·  ROD Consulting © 2025',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: AppTheme.lightGray.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Column(
        children: [
          // ── Fila superior: botón login ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.lightGray.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 17,
                        color: AppTheme.darkGray,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Iniciar sesión',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGray,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Logo ─────────────────────────────────────────
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.limeGreen.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // App name
          Text(
            'ROD QuickCalc',
            style: GoogleFonts.rajdhani(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.black,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitle
          Text(
            'Ingeniería Eléctrica',
            style: GoogleFonts.rajdhani(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.limeGreenDark,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
