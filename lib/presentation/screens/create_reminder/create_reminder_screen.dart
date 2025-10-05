import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../domain/entities/reminder.dart';
import '../../bloc/reminder_bloc.dart';
import '/../theme/app_styles.dart';
import 'reminder_form_controller.dart';
import 'widgets/reminder_text_field.dart';
import 'widgets/reminder_date_time_card.dart';
import 'widgets/reminder_frequency_card.dart';
import 'widgets/custom_frequency_options.dart';
import 'widgets/time_picker_modal.dart';

class CreateReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const CreateReminderScreen({super.key, this.reminder});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  late ReminderFormController _controller;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    _controller = ReminderFormController(
      initialReminder: widget.reminder,
      onAutoSave: _isEditing ? _autoSaveReminder : null,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Form(
        key: _controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(kLargePadding),
          children: [
            const SizedBox(height: kDefaultPadding),

            ReminderTextField(
              controller: _controller.titleController,
              label: 'Título del recordatorio',
              hint: 'Ej: Endereza tu espalda',
              icon: Icons.title,
              onChanged: _isEditing ? (_) => {} : null,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Por favor ingresa un título' : null,
            ),

            const SizedBox(height: kLargePadding),

            ReminderTextField(
              controller: _controller.descriptionController,
              label: 'Descripción',
              hint: 'Explica qué hacer cuando llegue el recordatorio',
              icon: Icons.description,
              maxLines: 4,
              onChanged: _isEditing ? (_) => {} : null,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Por favor ingresa una descripción' : null,
            ),

            const SizedBox(height: kLargePadding),

            ReminderDateTimeCard(
              selectedDateTime: _controller.selectedDateTime,
              onDatePressed: _selectDate,
              onTimePressed: _selectTime,
            ),

            const SizedBox(height: kLargePadding),

            ReminderFrequencyCard(
              selectedFrequency: _controller.frequency,
              onFrequencyChanged: (frequency) {
                setState(() => _controller.updateFrequency(frequency));
              },
            ),

            if (_controller.frequency == ReminderFrequency.custom) ...[
              const SizedBox(height: kLargePadding),
              CustomFrequencyOptions(
                selectedDays: _controller.selectedDays,
                customInterval: _controller.customInterval,
                onDaysChanged: (days) {
                  setState(() => _controller.updateDays(days));
                },
                onIntervalChanged: (interval) {
                  setState(() => _controller.updateCustomInterval(interval));
                },
              ),
            ],

            const SizedBox(height: kExtraLargePadding),

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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDateTime,
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
      setState(() => _controller.updateDate(picked));
    }
  }

  Future<void> _selectTime() async {
    await showTimePickerModal(
      context: context,
      initialDateTime: _controller.selectedDateTime,
      onConfirm: (time) {
        setState(() => _controller.updateTime(time));
      },
    );
  }

  void _saveReminder() {
    if (!_controller.validate()) return;

    if (!_controller.validateCustomFrequency()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona días o un intervalo personalizado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isEditing) {
      final updatedReminder = _controller.toReminder(
        id: widget.reminder!.id,
        createdAt: widget.reminder!.createdAt,
      );
      context.read<ReminderBloc>().add(UpdateReminder(updatedReminder));
    } else {
      final newReminder = _controller.toReminder();
      context.read<ReminderBloc>().add(
            CreateReminder(
              title: newReminder.title,
              description: newReminder.description,
              dateTime: newReminder.dateTime,
              frequency: newReminder.frequency,
              customDays: newReminder.customDays,
              customInterval: newReminder.customInterval,
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

  void _autoSaveReminder() {
    if (!_controller.validate()) return;
    if (!_controller.validateCustomFrequency()) return;

    final updatedReminder = _controller.toReminder(
      id: widget.reminder!.id,
      createdAt: widget.reminder!.createdAt,
    );

    context.read<ReminderBloc>().add(UpdateReminder(updatedReminder));
  }
}