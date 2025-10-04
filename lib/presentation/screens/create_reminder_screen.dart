import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../../theme/app_styles.dart';

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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kWhiteColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kContrastColor, size: kMediumIconSize),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Editar Recordatorio' : 'Nuevo Recordatorio',
          style: kSubtitleTextStyle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kLargePadding),
          children: [
            const SizedBox(height: kDefaultPadding),

            /// --- Título ---
            _buildTextField(
              controller: _titleController,
              label: 'Título del recordatorio',
              hint: 'Ej: Endereza tu espalda',
              icon: Icons.title,
              onChanged: _isEditing ? _onFieldChanged : null,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Por favor ingresa un título' : null,
            ),

            const SizedBox(height: kLargePadding),

            /// --- Descripción ---
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hint: 'Explica qué hacer cuando llegue el recordatorio',
              icon: Icons.description,
              maxLines: 4,
              onChanged: _isEditing ? _onFieldChanged : null,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Por favor ingresa una descripción' : null,
            ),

            const SizedBox(height: kLargePadding),

            /// --- Fecha y hora ---
            _buildDateTimeCard(),

            const SizedBox(height: kLargePadding),

            /// --- Frecuencia ---
            _buildFrequencyCard(),

            if (_frequency == ReminderFrequency.custom) ...[
              const SizedBox(height: kLargePadding),
              _buildCustomFrequencyOptions(),
            ],

            const SizedBox(height: kExtraLargePadding),

            /// --- Botón Guardar/Crear ---
            ElevatedButton(
              onPressed: _saveReminder,
              style: kPrimaryButtonStyle,
              child: Text(
                _isEditing ? 'Guardar Cambios' : 'Crear Recordatorio',
                style: kButtonTextStyle,
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
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: kBodyTextStyle,
          onChanged: onChanged,
          decoration: kTextFieldDecoration.copyWith(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: kPrimaryColor, size: kMediumIconSize),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Card(
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: kPrimaryColor, size: kMediumIconSize),
                const SizedBox(width: kSmallPadding),
                Text('Fecha y hora', style: kSubtitleTextStyle),
              ],
            ),
            const SizedBox(height: kDefaultPadding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('dd/MM/yyyy', 'es').format(_selectedDateTime),
                      style: kCaptionTextStyle,
                    ),
                  ),
                ),
                const SizedBox(width: kSmallPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      DateFormat('HH:mm').format(_selectedDateTime),
                      style: kCaptionTextStyle,
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
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: kPrimaryColor, size: kMediumIconSize),
                const SizedBox(width: kSmallPadding),
                Text('Frecuencia', style: kSubtitleTextStyle),
              ],
            ),
            const SizedBox(height: kSmallPadding),
            _buildFrequencyOption('Una vez', ReminderFrequency.once, Icons.event),
            _buildFrequencyOption('Todos los días', ReminderFrequency.daily, Icons.today),
            _buildFrequencyOption('Cada semana', ReminderFrequency.weekly, Icons.calendar_view_week),
            _buildFrequencyOption('Personalizado', ReminderFrequency.custom, Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String label, ReminderFrequency freq, IconData icon) {
    final isSelected = _frequency == freq;
    return Padding(
      padding: const EdgeInsets.only(bottom: kSmallPadding),
      child: InkWell(
        onTap: () {
          setState(() => _frequency = freq);
          if (_isEditing) _onFieldChanged('');
        },
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(kSmallPadding),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
            border: Border.all(
              color: isSelected ? kPrimaryColor : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? kPrimaryColor : Colors.grey[600],
                  size: kMediumIconSize),
              const SizedBox(width: kSmallPadding),
              Text(
                label,
                style: kBodyTextStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kPrimaryColor : kContrastColor,
                ),
              ),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: kPrimaryColor, size: kSmallIconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFrequencyOptions() {
    return Card(
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opciones personalizadas', style: kSubtitleTextStyle),
            const SizedBox(height: kDefaultPadding),
            Text('Selecciona días de la semana:',
                style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: kSmallPadding),
            Wrap(
              spacing: kSmallPadding,
              runSpacing: kSmallPadding,
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
            const SizedBox(height: kLargePadding),
            Text('O repite cada:',
                style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: kSmallPadding),
            TextFormField(
              initialValue: _customInterval?.toString() ?? '',
              keyboardType: TextInputType.number,
              style: kBodyTextStyle,
              decoration: kTextFieldDecoration.copyWith(
                hintText: 'Número',
                suffixText: 'días',
              ),
              onChanged: (value) {
                setState(() {
                  _customInterval = int.tryParse(value);
                  if (_customInterval != null) _selectedDays = [];
                });
                if (_isEditing) _onFieldChanged('');
              },
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
        style: kBodyTextStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: isSelected ? kWhiteColor : kContrastColor,
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
      selectedColor: kPrimaryColor,
      checkmarkColor: kWhiteColor,
      padding: const EdgeInsets.all(kSmallPadding),
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
            colorScheme: const ColorScheme.light(primary: kPrimaryColor),
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

  Future<void> _selectTime() async {
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(_selectedDateTime);
    
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(kDefaultBorderRadius),
                    topRight: Radius.circular(kDefaultBorderRadius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: kWhiteColor),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _selectedDateTime = DateTime(
                            _selectedDateTime.year,
                            _selectedDateTime.month,
                            _selectedDateTime.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                        });
                        if (_isEditing) _onFieldChanged('');
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _selectedDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newTime) {
                    selectedTime = TimeOfDay.fromDateTime(newTime);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      if (_frequency == ReminderFrequency.custom &&
          _selectedDays.isEmpty &&
          _customInterval == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona días o un intervalo personalizado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_isEditing) {
        final updatedReminder = widget.reminder!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          dateTime: _selectedDateTime,
          frequency: _frequency,
          customDays: _frequency == ReminderFrequency.custom ? _selectedDays : null,
          customInterval: _frequency == ReminderFrequency.custom ? _customInterval : null,
        );
        context.read<ReminderBloc>().add(UpdateReminder(updatedReminder));
      } else {
        context.read<ReminderBloc>().add(
              CreateReminder(
                title: _titleController.text,
                description: _descriptionController.text,
                dateTime: _selectedDateTime,
                frequency: _frequency,
                customDays: _frequency == ReminderFrequency.custom ? _selectedDays : null,
                customInterval: _frequency == ReminderFrequency.custom ? _customInterval : null,
              ),
            );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Recordatorio actualizado exitosamente'
              : 'Recordatorio creado exitosamente'),
          backgroundColor: kSuccessColor,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    }
  }

  void _onFieldChanged(String value) {
    if (!_isEditing) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () => _autoSaveReminder());
  }

  void _autoSaveReminder() {
    if (!_isEditing) return;
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;
    if (_frequency == ReminderFrequency.custom &&
        _selectedDays.isEmpty &&
        _customInterval == null) return;

    final updatedReminder = widget.reminder!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dateTime: _selectedDateTime,
      frequency: _frequency,
      customDays: _frequency == ReminderFrequency.custom ? _selectedDays : null,
      customInterval: _frequency == ReminderFrequency.custom ? _customInterval : null,
      updatedAt: DateTime.now(),
    );

    context.read<ReminderBloc>().add(UpdateReminder(updatedReminder));
  }
}
