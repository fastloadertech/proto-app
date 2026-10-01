import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/proto_button.dart';
import '../../orders/domain/order.dart';

/// Local address book. A selection is returned to checkout so its editable
/// address fields stay in sync with the selected saved destination.
class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  static const _labels = ['Home', 'Work', 'Other'];

  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _pin = TextEditingController();
  String _label = 'Home';
  String? _error;
  bool _editing = false;

  @override
  void dispose() {
    _street.dispose();
    _area.dispose();
    _city.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _edit([DeliveryAddress? address]) {
    final addresses = AppScope.of(context).savedAddresses;
    final firstUnused = _labels.where(
      (label) => addresses.every((saved) => saved.label != label),
    );
    setState(() {
      _editing = true;
      _error = null;
      _label =
          address?.label ??
          (firstUnused.isNotEmpty ? firstUnused.first : 'Other');
      _street.text = address?.line1 ?? '';
      _area.text = address?.area ?? '';
      _city.text = address?.city ?? '';
      _pin.text = address?.postalCode ?? '';
    });
  }

  void _select(DeliveryAddress address) {
    final app = AppScope.of(context);
    app.selectDeliveryAddress(address.label);
    Navigator.of(context).pop(app.deliveryAddress);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final address = DeliveryAddress(
      line1: _street.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      postalCode: _pin.text.trim(),
      label: _label,
    );
    if (!address.isValid) {
      setState(() => _error = 'Complete the address before continuing.');
      return;
    }
    try {
      final app = AppScope.of(context);
      app.saveDeliveryAddress(address);
      Navigator.of(context).pop(app.deliveryAddress);
    } on ArgumentError catch (error) {
      setState(() {
        _error = error.message?.toString() ?? 'Check this address and retry.';
      });
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) => TextFormField(
    key: ValueKey('saved-${label.toLowerCase().replaceAll(' ', '-')}'),
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: keyboardType == TextInputType.number
        ? TextCapitalization.none
        : TextCapitalization.words,
    textInputAction: label == 'PIN code'
        ? TextInputAction.done
        : TextInputAction.next,
    inputFormatters: inputFormatters,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ProtoColors.muted, fontSize: 13),
      errorMaxLines: 2,
    ),
    validator: validator,
  );

  Widget _editor() => Container(
    key: const ValueKey('address-editor'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SAVE A DESTINATION',
            style: TextStyle(
              color: ProtoColors.lime,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Make it yours.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in _labels)
                ChoiceChip(
                  label: Text(label),
                  selected: _label == label,
                  onSelected: (_) => setState(() => _label = label),
                  selectedColor: ProtoColors.lime,
                  backgroundColor: ProtoColors.elevated,
                  side: BorderSide(
                    color: _label == label
                        ? ProtoColors.lime
                        : ProtoColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: _label == label
                        ? ProtoColors.background
                        : ProtoColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Street address',
            controller: _street,
            validator: (value) => (value?.trim().length ?? 0) >= 3
                ? null
                : 'Enter a street address with a house or flat number.',
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Area',
            controller: _area,
            validator: (value) =>
                (value?.trim().isNotEmpty ?? false) ? null : 'Enter an area.',
          ),
          const SizedBox(height: 16),
          _field(
            label: 'City',
            controller: _city,
            validator: (value) =>
                (value?.trim().isNotEmpty ?? false) ? null : 'Enter a city.',
          ),
          const SizedBox(height: 16),
          _field(
            label: 'PIN code',
            controller: _pin,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) =>
                RegExp(r'^[1-9]\d{5}$').hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid 6-digit PIN code.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFF3B8A7), fontSize: 12),
            ),
          ],
          const SizedBox(height: 22),
          ProtoButton(
            label: 'Save and use address',
            icon: Icons.arrow_forward_rounded,
            onPressed: _save,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _editing = false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final addresses = app.savedAddresses;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery address')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DELIVERY, YOUR WAY.',
                    style: TextStyle(
                      color: ProtoColors.lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Where should we meet you?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Addresses are saved in this local demo session.',
                    style: TextStyle(color: ProtoColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  if (addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'No saved addresses yet. Add one below.',
                        style: TextStyle(color: ProtoColors.muted),
                      ),
                    )
                  else ...[
                    for (final address in addresses) ...[
                      _SavedAddressCard(
                        address: address,
                        selected:
                            app.deliveryAddress.label == address.label &&
                            app.deliveryAddress.formatted == address.formatted,
                        onSelect: () => _select(address),
                        onEdit: () => _edit(address),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (!_editing)
                    OutlinedButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add another address'),
                    )
                  else
                    _editor(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  final DeliveryAddress address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: selected
          ? ProtoColors.lime.withValues(alpha: .07)
          : ProtoColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: selected ? ProtoColors.lime : ProtoColors.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              switch (address.label) {
                'Home' => Icons.home_outlined,
                'Work' => Icons.work_outline_rounded,
                _ => Icons.location_on_outlined,
              },
              size: 20,
              color: ProtoColors.lime,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                address.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              const Text(
                'SELECTED',
                style: TextStyle(
                  color: ProtoColors.lime,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          address.formatted,
          style: const TextStyle(
            color: ProtoColors.muted,
            height: 1.5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            TextButton(
              onPressed: onSelect,
              child: Text('Use ${address.label}'),
            ),
            TextButton(onPressed: onEdit, child: Text('Edit ${address.label}')),
          ],
        ),
      ],
    ),
  );
}
