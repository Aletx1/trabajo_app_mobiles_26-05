import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const Pro3DPrintApp());

class Pro3DPrintApp extends StatelessWidget {
  const Pro3DPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3D Print Calc Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // Paleta Esmeralda
          primary: const Color(0xFF0F172A),   // Fondo Slate Navy
        ),
      ),
      home: const VistaFormularioTecnico(),
    );
  }
}

// ==========================================
// VISTA 1: FORMULARIO TÉCNICO (Scroll Vertical)
// ==========================================
class VistaFormularioTecnico extends StatefulWidget {
  const VistaFormularioTecnico({super.key});

  @override
  State<VistaFormularioTecnico> createState() => _VistaFormularioTecnicoState();
}

class _VistaFormularioTecnicoState extends State<VistaFormularioTecnico> {
  final _formKey = GlobalKey<FormState>();
  
  // Palabra clave: Uso de TextEditingController para la captura de flujos de texto y números
  final _nombreCtrl = TextEditingController();
  final _specsCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();

  // Estados iniciales para los 11 tipos de campos obligatorios
  String _material = 'PLA Premium';
  String _prioridad = 'Media';
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 30);
  bool _acabadoEspecial = false;
  bool _incluyeSoportes = false;
  double _rellenoInfill = 15.0;
  XFile? _imagenSTL;

  @override
  void initState() {
    super.initState();
    _cargarHistorialLocal();
  }

  // DESAFÍO: Almacenamiento Local automático mediante shared_preferences
  // Sincroniza inmediatamente los datos en tiempo real ante cambios del usuario
  void _syncLocal(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is String) await p.setString(key, value);
    if (value is bool) await p.setBool(key, value);
    if (value is double) await p.setDouble(key, value);
  }

  // Reinserta automáticamente la sesión si el usuario sale de la aplicación
  void _cargarHistorialLocal() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _nombreCtrl.text = p.getString('f_nom') ?? '';
      _pesoCtrl.text = p.getString('f_peso') ?? '';
      _specsCtrl.text = p.getString('f_specs') ?? '';
      _material = p.getString('f_mat') ?? 'PLA Premium';
      _prioridad = p.getString('f_prioridad') ?? 'Media';
      _acabadoEspecial = p.getBool('f_acabado') ?? false;
      _incluyeSoportes = p.getBool('f_soportes') ?? false;
      _rellenoInfill = p.getDouble('f_infill') ?? 15.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('3D Print Calc Pro', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
      ),
      // Requisito mínimo: Contenedor con scroll o desplazamiento vertical
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header("IDENTIFICACIÓN DEL CLIENTE", Icons.person_pin_outlined),
              _buildCardContainer([
                // Campo 1: Texto Corto (Nombre del proyecto/pieza)
                TextFormField(
                  controller: _nombreCtrl, 
                  decoration: const InputDecoration(labelText: 'Proyecto / Nombre del Cliente', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()), 
                  onChanged: (v) => _syncLocal('f_nom', v)
                ),
                const SizedBox(height: 15),
                // Campo 2: Texto Largo (Descripción/Notas técnicas)
                TextFormField(
                  controller: _specsCtrl, 
                  maxLines: 2, 
                  decoration: const InputDecoration(labelText: 'Notas Técnicas y Observaciones', border: OutlineInputBorder()),
                  onChanged: (v) => _syncLocal('f_specs', v)
                ),
              ]),

              _header("CONFIGURACIÓN DE IMPRESIÓN", Icons.settings_input_component),
              _buildCardContainer([
                // Campo 3: Numérico (Métrica de peso en gramos)
                TextFormField(
                  controller: _pesoCtrl, 
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: 'Peso Final Estimado (Gramos)', prefixIcon: Icon(Icons.monitor_weight), border: OutlineInputBorder()), 
                  onChanged: (v) => _syncLocal('f_peso', v)
                ),
                const SizedBox(height: 15),
                // Campo 6: Lista Desplegable (Material de fabricación)
                DropdownButtonFormField<String>(
                  value: _material,
                  decoration: const InputDecoration(labelText: 'Material / Filamento de Insumo', border: OutlineInputBorder()),
                  items: ['PLA Premium', 'PETG Tech', 'ABS Industrial', 'TPU Flexible'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) { setState(() => _material = v!); _syncLocal('f_mat', v); },
                ),
                const SizedBox(height: 15),
                const Text("Prioridad de Fabricación (Radio Button):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                // Campo 7: Radio Buttons (Nivel de prioridad del pedido)
                Row(
                  children: ['Baja', 'Media', 'Alta'].map((p) => Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p, style: const TextStyle(fontSize: 12)), 
                      value: p, 
                      groupValue: _prioridad, 
                      onChanged: (v) { setState(() => _prioridad = v!); _syncLocal('f_prioridad', v); }
                    ),
                  )).toList(),
                ),
              ]),

              _header("LOGÍSTICA Y CRONOGRAMA", Icons.history_toggle_off),
              _buildCardContainer([
                // Campo 4: Selector de Fecha (Fecha límite)
                ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFF10B981)),
                  title: Text("Fecha Límite: ${DateFormat('dd/MM/yyyy').format(_fechaEntrega)}"),
                  onTap: () async {
                    DateTime? d = await showDatePicker(context: context, initialDate: _fechaEntrega, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (d != null) setState(() => _fechaEntrega = d);
                  },
                ),
                // Campo 5: Selector de Hora (Hora de inicio)
                ListTile(
                  leading: const Icon(Icons.schedule, color: Color(0xFF10B981)),
                  title: Text("Hora Estimada de Inicio: ${_horaInicio.format(context)}"),
                  onTap: () async {
                    TimeOfDay? t = await showTimePicker(context: context, initialTime: _horaInicio);
                    if (t != null) setState(() => _horaInicio = t);
                  },
                ),
                // Campo 8: Switch (Estado/Validación booleana de acabado)
                SwitchListTile(
                  title: const Text("¿Requiere Acabado Químico Especial?"),
                  subtitle: const Text("Pulido extra o tratamiento de resina"),
                  value: _acabadoEspecial,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (v) { setState(() => _acabadoEspecial = v); _syncLocal('f_acabado', v); },
                ),
              ]),

              _header("PARAMETRIZACIÓN AVANZADA Y EVIdENCIA", Icons.auto_awesome_mosaic_outlined),
              _buildCardContainer([
                // Campo 9: Checkbox (Selección de opciones de soporte)
                CheckboxListTile(
                  title: const Text("Generar Estructuras de Soporte Mecánico"), 
                  value: _incluyeSoportes, 
                  activeColor: const Color(0xFF10B981),
                  onChanged: (v) { setState(() => _incluyeSoportes = v!); _syncLocal('f_soportes', v!); }
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Densidad de Relleno (Infill Slider): ${_rellenoInfill.round()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 5),
                      // Campo 10: Slider (Control numérico de rango de infill)
                      Slider(
                        value: _rellenoInfill, 
                        min: 0, 
                        max: 100, 
                        divisions: 20, 
                        activeColor: const Color(0xFF10B981),
                        label: "${_rellenoInfill.round()}%",
                        onChanged: (v) { setState(() => _rellenoInfill = v); _syncLocal('f_infill', v); }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Campo 11: Subir Archivo/Imagen (Evidencia fotográfica o captura STL del Slicer)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) setState(() => _imagenSTL = pickedFile);
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_imagenSTL == null ? "Cargar Captura STL de Referencia" : "Evidencia STL Cargada ✓"),
                  ),
                ),
                const SizedBox(height: 10),
              ]),

              const SizedBox(height: 35),
              // Botón de procesamiento (OnPressed) con salto de contexto a la Segunda Vista
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => VistaResumenFinal(
                      nombre: _nombreCtrl.text,
                      peso: double.tryParse(_pesoCtrl.text) ?? 0,
                      prioridad: _prioridad,
                      acabado: _acabadoEspecial,
                    )));
                  },
                  child: const Text("ANALIZAR COSTOS DE PRODUCCIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String t, IconData i) => Padding(
    padding: const EdgeInsets.only(top: 25, bottom: 10, left: 5), 
    child: Row(children: [Icon(i, size: 18, color: Colors.blueGrey), const SizedBox(width: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.1))])
  );
  
  Widget _buildCardContainer(List<Widget> children) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children))
  );
}

// ==========================================
// VISTA 2: RESUMEN / PROCESAMIENTO DE INFORMACIÓN
// ==========================================
class VistaResumenFinal extends StatelessWidget {
  final String nombre;
  final double peso;
  final String prioridad;
  final bool acabado;

  const VistaResumenFinal({super.key, required this.nombre, required this.peso, required this.prioridad, required this.acabado});

  @override
  Widget build(BuildContext context) {
    // REQUISITO MÍNIMO: Realizar al menos dos cálculos de ingeniería comercial relevantes al tema
    // Cálculo 1: Costo base del filamento ($28.000 CLP el kilogramo de insumo técnico)
    double costoMaterial = (peso / 1000) * 28000; 
    
    // Cálculo 2: Costo operativo asociado al consumo eléctrico estandarizado y depreciación de la boquilla
    double costoEnergiaDesgaste = 1800; 
    
    double subtotal = costoMaterial + costoEnergiaDesgaste + (acabado ? 6000 : 0);
    
    // Cálculo 3: Recargo sobre el margen de ganancia logística según prioridad alta (30% adicional)
    double recargoPrioridad = (prioridad == 'Alta') ? subtotal * 0.30 : 0.0;
    double totalFinal = subtotal + recargoPrioridad;

    // Reporte ordenado y formateado
    String reporte = """
=== 3D PRINT CALC PRO REPORT ===
PROYECTO: ${nombre.isEmpty ? 'N/A' : nombre.toUpperCase()}
MÉTRICA DE PESO: $peso gr.
NIVEL DE PRIORIDAD: $prioridad

--- DESGLOSE TÉCNICO-ECONÓMICO ---
- Insumo Filamento Neto: \$${costoMaterial.toStringAsFixed(0)} CLP
- Energía y Desgaste: \$${costoEnergiaDesgaste.toStringAsFixed(0)} CLP
- Post-Procesado Químico: \$${acabado ? '6.000' : '0'} CLP
- Recargo por Entrega: \$${recargoPrioridad.toStringAsFixed(0)} CLP
----------------------------------
TOTAL FINAL ESTIMADO: \$${totalFinal.toStringAsFixed(0)} CLP
==================================
""";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Análisis de Rentabilidad", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  // Requisito mínimo: Texto estructurado y totalmente seleccionable
                  child: SelectableText(reporte, style: const TextStyle(color: Color(0xFF10B981), fontFamily: 'monospace', fontSize: 17, height: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Requisito mínimo: Botón dedicado para copiar el resumen al portapapeles del dispositivo de manera nativa
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reporte));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Presupuesto comercial copiado al portapapeles!")));
              },
              icon: const Icon(Icons.copy_all),
              label: const Text("COPIAR RESUMEN PARA CLIENTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            )
          ],
        ),
      ),
    );
  }
}