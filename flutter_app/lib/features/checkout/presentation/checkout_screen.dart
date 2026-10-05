import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/state/coupon_pricing.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/price_summary.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/proto_button.dart';
import '../../orders/domain/order.dart';
import '../../orders/presentation/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _street = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _pin = TextEditingController();
  final _coupon = TextEditingController();
  late final Listenable _addressDraft = Listenable.merge([
    _street,
    _area,
    _city,
    _pin,
  ]);
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _initialized = false;
  bool _placingOrder = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = AppScope.of(context);
    _name.text = app.contact.name;
    _phone.text = app.contact.phone;
    _email.text = app.contact.email;
    _street.text = app.deliveryAddress.line1;
    _area.text = app.deliveryAddress.area;
    _city.text = app.deliveryAddress.city;
    _pin.text = app.deliveryAddress.postalCode;
    _coupon.text = app.couponCode ?? '';
    _paymentMethod = app.paymentMethod;
    _initialized = true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _street,
      _area,
      _city,
      _pin,
      _coupon,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_placingOrder) return;
    final app = AppScope.of(context);
    if (app.cartCount == 0) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Check the highlighted details to continue.');
      final formContext = _formKey.currentContext;
      if (formContext != null) {
        await Scrollable.ensureVisible(
          formContext,
          duration: const Duration(milliseconds: 250),
        );
      }
      return;
    }
    final contact = CheckoutContact(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
    );
    final address = DeliveryAddress(
      line1: _street.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      postalCode: _pin.text.trim(),
      label: app.deliveryAddress.label,
      id: app.deliveryAddress.id,
    );
    final paymentMethod = _paymentMethod;
    if (!contact.isValid || !address.isValid) {
      setState(
        () => _error = 'Please complete your contact and delivery details.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _placingOrder = true;
      _error = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final order = await app.submitOrder(
        address: address,
        contact: contact,
        paymentMethod: paymentMethod,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/order-confirmation'),
          builder: (_) => OrderConfirmationScreen(orderId: order.id),
        ),
      );
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _placingOrder = false;
          _error = error.message;
        });
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        setState(() {
          _placingOrder = false;
          _error =
              error.message?.toString() ??
              'Please check your details and try again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _placingOrder = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _chooseAddress() async {
    final result = await Navigator.of(context).pushNamed('/addresses');
    if (!mounted || result is! DeliveryAddress) return;
    setState(() {
      _street.text = result.line1;
      _area.text = result.area;
      _city.text = result.city;
      _pin.text = result.postalCode;
      _error = null;
    });
  }

  void _applyCoupon() {
    FocusScope.of(context).unfocus();
    AppScope.of(context).applyCoupon(_coupon.text);
  }

  String? _requiredText(String? value, String label, {int minLength = 2}) {
    if (value == null || value.trim().length < minLength)
      return 'Enter your $label.';
    return null;
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization capitalization = TextCapitalization.none,
    String? prefixText,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    enabled: !_placingOrder,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    textInputAction: TextInputAction.next,
    inputFormatters: inputFormatters,
    maxLines: maxLines,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefixText,
      errorMaxLines: 2,
      labelStyle: const TextStyle(color: ProtoColors.muted, fontSize: 13),
    ),
    validator: validator,
  );

  Widget _form(AppController app) => Form(
    key: _formKey,
    child: Column(
      children: [
        _CheckoutSection(
          number: '01',
          title: 'Your details',
          subtitle: 'Sample details are filled in. Make them yours.',
          child: Column(
            children: [
              _field(
                label: 'Full name',
                controller: _name,
                capitalization: TextCapitalization.words,
                validator: (value) => _requiredText(value, 'full name'),
              ),
              const SizedBox(height: 18),
              _field(
                label: 'Mobile number',
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) => RegExp(r'^\d{10}$').hasMatch(value ?? '')
                    ? null
                    : 'Enter a 10-digit mobile number.',
              ),
              const SizedBox(height: 18),
              _field(
                label: 'Email (optional)',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty ||
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                    return null;
                  }
                  return 'Enter a valid email address.';
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CheckoutSection(
          number: '02',
          title: 'Where’s your next rep?',
          subtitle: 'Your delivery address',
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ProtoColors.elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ProtoColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: ProtoColors.lime,
                      size: 20,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deliver to · ${app.deliveryAddress.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          AnimatedBuilder(
                            animation: _addressDraft,
                            builder: (context, _) => Text(
                              '${_street.text}\n${_area.text}, ${_city.text} — ${_pin.text}',
                              style: const TextStyle(
                                color: ProtoColors.muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _placingOrder ? null : _chooseAddress,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Choose saved address'),
                ),
              ),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You can also adjust this address below.',
                  style: TextStyle(color: ProtoColors.muted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Street address',
                controller: _street,
                capitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Enter a street address with a house or flat number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _field(
                label: 'Area',
                controller: _area,
                capitalization: TextCapitalization.words,
                validator: (value) =>
                    _requiredText(value, 'area', minLength: 1),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'City',
                      controller: _city,
                      capitalization: TextCapitalization.words,
                      validator: (value) =>
                          _requiredText(value, 'city', minLength: 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'PIN code',
                      controller: _pin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) =>
                          RegExp(r'^[1-9]\d{5}$').hasMatch(value ?? '')
                          ? null
                          : 'Enter a valid 6-digit PIN code.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CheckoutSection(
          number: '03',
          title: 'Your way to pay',
          subtitle: 'All payment choices are part of the local demo.',
          child: Column(
            children: [
              for (final method in PaymentMethod.values.where(
                (method) => method != PaymentMethod.online,
              )) ...[
                _PaymentChoice(
                  method: method,
                  selected: _paymentMethod == method,
                  enabled: !_placingOrder,
                  onTap: () => setState(() => _paymentMethod = method),
                ),
                if (method != PaymentMethod.values.last)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 16),
              const Text(
                'No money is charged. No card, UPI app, or payment service is contacted.',
                style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _couponSection(AppController app) {
    final activeCoupon = app.couponCode == null
        ? null
        : CouponPricing.evaluate(app.couponCode!, app.subtotal);
    return _CheckoutSection(
      title: 'Have a code?',
      subtitle: 'Try PROTO10 or FUEL50 in this local demo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coupon,
                  enabled: !_placingOrder,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyCoupon(),
                  decoration: const InputDecoration(
                    labelText: 'Promo code',
                    hintText: 'Enter code',
                    labelStyle: TextStyle(
                      color: ProtoColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _placingOrder ? null : _applyCoupon,
                child: const Text('Apply code'),
              ),
            ],
          ),
          if (activeCoupon != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  activeCoupon.isApplied
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: activeCoupon.isApplied
                      ? ProtoColors.lime
                      : const Color(0xFFF3B8A7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeCoupon.isApplied
                        ? '${app.couponCode} applied · Save ${formatPrice(activeCoupon.discount)}'
                        : '${app.couponCode} paused · ${activeCoupon.message}',
                    style: TextStyle(
                      color: activeCoupon.isApplied
                          ? ProtoColors.lime
                          : const Color(0xFFF3B8A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _placingOrder
                      ? null
                      : () {
                          app.removeCoupon();
                          _coupon.clear();
                        },
                  child: const Text('Remove code'),
                ),
              ],
            ),
          ],
          if (app.couponMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              app.couponMessage!,
              style: const TextStyle(
                color: Color(0xFFF3B8A7),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summary(AppController app) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _CheckoutSection(
        title: 'Your fuel, packed.',
        subtitle:
            '${app.cartCount} ${app.cartCount == 1 ? 'item' : 'items'} in this order',
        child: Column(
          children: [
            for (var i = 0; i < app.bagLines.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
              _CheckoutProduct(line: app.bagLines[i]),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      _couponSection(app),
      const SizedBox(height: 20),
      PriceSummary(
        subtotal: app.subtotal,
        deliveryFee: app.deliveryFee,
        savings: app.savings,
        discount: app.couponDiscount,
      ),
      const SizedBox(height: 20),
      if (_error != null) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF3A2520),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFF3B8A7),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      ProtoButton(
        label: _placingOrder ? 'Placing order…' : 'Place order',
        loading: _placingOrder,
        icon: _placingOrder ? null : Icons.arrow_forward_rounded,
        onPressed: _placingOrder || app.cartCount == 0 ? null : _placeOrder,
      ),
      const SizedBox(height: 12),
      const Text(
        'Local demo order · No real delivery will be made.',
        textAlign: TextAlign.center,
        style: TextStyle(color: ProtoColors.muted, fontSize: 10, height: 1.6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PopScope(
      canPop: !_placingOrder,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _placingOrder
                ? null
                : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          top: false,
          child: app.cartCount == 0 && !_placingOrder
              ? _EmptyCheckout(error: _error)
              : LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ONE STEP CLOSER.',
                              style: TextStyle(
                                color: ProtoColors.lime,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.7,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Ready for your next level.',
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 26),
                            if (constraints.maxWidth >= 900)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: _form(app)),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: _summary(app)),
                                ],
                              )
                            else ...[
                              _form(app),
                              const SizedBox(height: 20),
                              _summary(app),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String? number;
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (number != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  number!,
                  style: const TextStyle(
                    color: ProtoColors.lime,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ProtoColors.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected
          ? ProtoColors.lime.withValues(alpha: .07)
          : ProtoColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? ProtoColors.lime : ProtoColors.border,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                switch (method) {
                  PaymentMethod.cashOnDelivery => Icons.payments_outlined,
                  PaymentMethod.mockUpi => Icons.qr_code_rounded,
                  PaymentMethod.online => Icons.account_balance_wallet_outlined,
                  PaymentMethod.mockCard => Icons.credit_card_rounded,
                },
                color: selected ? ProtoColors.lime : ProtoColors.muted,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? ProtoColors.lime : ProtoColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CheckoutProduct extends StatelessWidget {
  const _CheckoutProduct({required this.line});
  final BagLine line;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 64,
        height: 74,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFECEEE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ProductArtwork(product: line.product, showGlow: false),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.product.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              '${line.flavor == null ? '' : '${line.flavor} · '}${line.product.weightLabel}',
              style: const TextStyle(
                color: ProtoColors.muted,
                fontSize: 10,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Qty ${line.quantity} · ${formatPrice(line.product.price * line.quantity)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: ProtoColors.lime,
            size: 46,
          ),
          const SizedBox(height: 22),
          const Text(
            'Your bag needs some fuel.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error ?? 'Add something good before placing an order.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProtoColors.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ProtoButton(
            label: 'Continue shopping',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/shop', (_) => false),
          ),
        ],
      ),
    ),
  );
}
