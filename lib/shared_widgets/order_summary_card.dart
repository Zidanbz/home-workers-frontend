import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/order_model.dart';

class OrderSummaryStatus {
  final String label;
  final Color color;
  final IconData icon;

  const OrderSummaryStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class OrderSummaryAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color backgroundColor;

  const OrderSummaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.foregroundColor,
    required this.backgroundColor,
  });
}

/// Tampilan ringkas pesanan yang dipakai bersama oleh Customer dan Worker.
///
/// Status dan aksi tetap diberikan oleh halaman pemanggil karena aturan bisnis
/// kedua role berbeda. Komponen ini hanya bertanggung jawab atas presentasi.
class OrderSummaryCard extends StatelessWidget {
  static const Color _primaryColor = Color(0xFF1A374D);
  static const Color _secondaryColor = Color(0xFF2B6478);
  static const Color _mutedColor = Color(0xFF6B7D87);
  static const Color _borderColor = Color(0xFFE1E8EC);

  final Order order;
  final OrderSummaryStatus status;
  final VoidCallback onTap;
  final OrderSummaryAction? action;
  final String? supportingLabel;
  final IconData supportingIcon;
  final Color supportingColor;

  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.status,
    required this.onTap,
    this.action,
    this.supportingLabel,
    this.supportingIcon = Icons.verified_user_outlined,
    this.supportingColor = const Color(0xFF16835D),
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        order.jadwalPerbaikan.hour == 0 && order.jadwalPerbaikan.minute == 0;
    final scheduleDate = DateFormat(
      'd MMM yyyy',
      'id_ID',
    ).format(order.jadwalPerbaikan);
    final scheduleTime = isMidnight
        ? 'Waktu menyusul'
        : DateFormat('HH:mm', 'id_ID').format(order.jadwalPerbaikan);
    final price = order.quotedPrice == null
        ? 'Belum ditentukan'
        : NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp',
            decimalDigits: 0,
          ).format(order.quotedPrice);
    final shortId = order.id.substring(
      0,
      order.id.length < 6 ? order.id.length : 6,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A374D),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _StatusPill(status: status),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '#${shortId.toUpperCase()}',
                      style: const TextStyle(
                        color: _mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2F6),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.home_repair_service_rounded,
                        color: _secondaryColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _primaryColor,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            order.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _mutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (supportingLabel != null) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  supportingIcon,
                                  size: 14,
                                  color: supportingColor,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    supportingLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: supportingColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8F9),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetaItem(
                          icon: Icons.event_outlined,
                          label: 'Jadwal',
                          value: scheduleDate,
                          supporting: scheduleTime,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 39,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: _borderColor,
                      ),
                      Expanded(
                        child: _MetaItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Harga',
                          value: price,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                const Divider(height: 1, color: _borderColor),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (action != null)
                      Flexible(child: _OrderActionButton(action: action!)),
                    const Spacer(),
                    const Text(
                      'Lihat detail',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2F6),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: _primaryColor,
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final OrderSummaryStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final OrderSummaryAction action;

  const _OrderActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 17),
      label: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        foregroundColor: action.foregroundColor,
        backgroundColor: action.backgroundColor,
        disabledForegroundColor: const Color(0xFF6B7D87),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? supporting;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    this.supporting,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: OrderSummaryCard._secondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: OrderSummaryCard._mutedColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OrderSummaryCard._primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (supporting != null) ...[
                const SizedBox(height: 1),
                Text(
                  supporting!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrderSummaryCard._mutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
