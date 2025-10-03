import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';

class CreateReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const CreateReminderScreen({super.key, this.reminder});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDateTime;
  ReminderFrequency _frequency = ReminderFrequency.once;
  List<int> _selectedDays = [];
  int? _customInterval;
  
  Timer? _debounceTimer;
  bool _hasUnsavedChanges = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController = TextEditingController(text: widget.reminder!.title);
      _descriptionController =
          TextEditingController(text: widget.reminder!.description);
      _selectedDateTime = widget.reminder!.dateTime;
      _frequency = widget.reminder!.frequency;
      _selectedDays = widget.reminder!.customDays ?? [];
      _customInterval = widget.reminder!.customInterval;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color(0xFF2C3E50), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Editar Recordatorio' : 'Nuevo Recordatorio',
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            // Título
            _buildTextField(
              controller: _titleController,
              label: 'Título del recordatorio',
              hint: 'Ej: Endereza tu espalda',
              icon: Icons.title,
              onChanged: _isEditing ? _onFieldChanged : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Descripción
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hint: 'Explica qué hacer cuando llegue el recordatorio',
              icon: Icons.description,
              maxLines: 4,
              onChanged: _isEditing ? _onFieldChanged : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Fecha y hora
            _buildDateTimeCard(),

            const SizedBox(height: 20),

            // Frecuencia
            _buildFrequencyCard(),

            // Opciones personalizadas
            if (_frequency == ReminderFrequency.custom) ...[
              const SizedBox(height: 20),
              _buildCustomFrequencyOptions(),
            ],

            const SizedBox(height: 30),

            // Indicador de cambios guardados y botón manual
            if (_isEditing) ...[
              
              ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else
              ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Crear Recordatorio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFF3498DB), size: 24),
            border: InputBorder.none,
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Color(0xFF3498DB), size: 24),
                SizedBox(width: 8),
                Text(
                  'Fecha y hora',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('dd/MM/yyyy', 'es').format(_selectedDateTime),
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF3498DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      DateFormat('HH:mm').format(_selectedDateTime),
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF3498DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.repeat, color: Color(0xFF3498DB), size: 24),
                SizedBox(width: 8),
                Text(
                  'Frecuencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFrequencyOption(
                'Una vez', ReminderFrequency.once, Icons.event),
            _buildFrequencyOption(
                'Todos los días', ReminderFrequency.daily, Icons.today),
            _buildFrequencyOption('Cada semana', ReminderFrequency.weekly,
                Icons.calendar_view_week),
            _buildFrequencyOption(
                'Personalizado', ReminderFrequency.custom, Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(
      String label, ReminderFrequency freq, IconData icon) {
    final isSelected = _frequency == freq;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() => _frequency = freq);
          if (_isEditing) _onFieldChanged('');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3498DB).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF3498DB) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color:
                      isSelected ? const Color(0xFF3498DB) : Colors.grey[600],
                  size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF3498DB)
                      : const Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: Color(0xFF3498DB), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFrequencyOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones personalizadas',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona días de la semana:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDayChip('L', 1),
                _buildDayChip('M', 2),
                _buildDayChip('X', 3),
                _buildDayChip('J', 4),
                _buildDayChip('V', 5),
                _buildDayChip('S', 6),
                _buildDayChip('D', 7),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'O repite cada:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _customInterval?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Número',
                      suffixText: 'días',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customInterval = int.tryParse(value);
                        if (_customInterval != null) _selectedDays = [];
                      });
                      if (_isEditing) _onFieldChanged('');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int day) {
    final isSelected = _selectedDays.contains(day);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : const Color(0xFF2C3E50),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
            _customInterval = null;
          } else {
            _selectedDays.remove(day);
          }
          _selectedDays.sort();
        });
        if (_isEditing) _onFieldChanged('');
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF3498DB),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.all(12),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3498DB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
      if (_isEditing) _onFieldChanged('');
    }
  }

  // Reemplaza la función _selectTime() en create_reminder_screen.dart

  Future<void> _selectTime() async {
    int selectedHour = _selectedDateTime.hour > 12
        ? _selectedDateTime.hour - 12
        : (_selectedDateTime.hour == 0 ? 12 : _selectedDateTime.hour);
    int selectedMinute = (_selectedDateTime.minute / 5).round();
    bool isAM = _selectedDateTime.hour < 12;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Selecciona la hora',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de Hora con ruedas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Horas (1-12)
                      SizedBox(
                        width: 80,
                        height: 180,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                            initialItem: selectedHour - 1,
                          ),
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() => selectedHour = index + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 12,
                            builder: (context, index) {
                              final hour = index + 1;
                              final isSelected = selectedHour == hour;
                              return Center(
                                child: Text(
                                  hour.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 36 : 24,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF3498DB)
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),

                      // Minutos (00, 05, 10, 15, ..., 55)
                      SizedBox(
                        width: 80,
                        height: 180,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                            initialItem: selectedMinute,
                          ),
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() => selectedMinute = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 12, // 0, 5, 10, ..., 55
                            builder: (context, index) {
                              final minute = index * 5;
                              final isSelected = selectedMinute == index;
                              return Center(
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 36 : 24,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF3498DB)
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // AM/PM Selector
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setModalState(() => isAM = true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isAM
                                    ? const Color(0xFF3498DB)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AM',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isAM ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => setModalState(() => isAM = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: !isAM
                                    ? const Color(0xFF3498DB)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PM',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      !isAM ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF3498DB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Convertir a formato 24 horas
                            int hour24 = selectedHour;
                            if (!isAM && selectedHour != 12) {
                              hour24 = selectedHour + 12;
                            } else if (isAM && selectedHour == 12) {
                              hour24 = 0;
                            }

                            setState(() {
                              _selectedDateTime = DateTime(
                                _selectedDateTime.year,
                                _selectedDateTime.month,
                                _selectedDateTime.day,
                                hour24,
                                selectedMinute * 5,
                              );
                            });
                            if (_isEditing) _onFieldChanged('');
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Listo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      if (_frequency == ReminderFrequency.custom) {
        if (_selectedDays.isEmpty && _customInterval == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Por favor selecciona días o un intervalo personalizado',
                style: TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (_isEditing) {
        final updatedReminder = widget.reminder!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          dateTime: _selectedDateTime,
          frequency: _frequency,
          customDays:
              _frequency == ReminderFrequency.custom ? _selectedDays : null,
          customInterval:
              _frequency == ReminderFrequency.custom ? _customInterval : null,
        );
        context.read<ReminderBloc>().add(UpdateReminder(updatedReminder));
      } else {
        context.read<ReminderBloc>().add(
              CreateReminder(
                title: _titleController.text,
                description: _descriptionController.text,
                dateTime: _selectedDateTime,
                frequency: _frequency,
                customDays: _frequency == ReminderFrequency.custom
                    ? _selectedDays
                    : null,
                customInterval: _frequency == ReminderFrequency.custom
                    ? _customInterval
                    : null,
              ),
            );
      }

      // Mostrar notificación de éxito solo al guardar manualmente
      if (_isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recordatorio actualizado exitosamente',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recordatorio creado exitosamente',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      Navigator.pop(context);
    }
  }

  void _onFieldChanged(String value) {
    if (!_isEditing) return;
    
    setState(() {
      _hasUnsavedChanges = true;
    });

    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();
    
    // Crear un nuevo timer para guardar después de 1 segundo de inactividad
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _autoSaveReminder();
    });
  }

  void _autoSaveReminder() {
    if (!_isEditing) return;

    // Validar que los campos requeridos no estén vacíos
    if (_titleController.text.trim().isEmpty || 
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    // Validar frecuencia personalizada
    if (_frequency == ReminderFrequency.custom) {
      if (_selectedDays.isEmpty && _customInterval == null) {
        return;
      }
    }

    final updatedReminder = widget.reminder!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dateTime: _selectedDateTime,
      frequency: _frequency,
      customDays: _frequency == ReminderFrequency.custom ? _selectedDays : null,
      customInterval: _frequency == ReminderFrequency.custom ? _customInterval : null,
      updatedAt: DateTime.now(),
    );

    // Guardado silencioso - sin notificación
    context.read<ReminderBloc>().add(UpdateReminder(updatedReminder));

    setState(() {
      _hasUnsavedChanges = false;
    });
  }
}
