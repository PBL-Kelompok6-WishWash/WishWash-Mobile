import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF0C4B8E);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBCEFF2),
              Color(0xFFF8FBFC),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navyColor,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    Text(
                      'Order Details',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(),

                      const SizedBox(height: 16),

                      _buildScheduleCard(),

                      const SizedBox(height: 24),

                      _buildReceiptSection(),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF9C27B0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Text(
                      'Download Receipt',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    const Color baseColor = Color(0xFF9C27B0);

    final Color orderColor = HSLColor.fromColor(baseColor)
        .withLightness(0.26)
        .toColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: orderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #1232',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: orderColor,
                  fontSize: 12,
                ),
              ),

              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    'Est: 20 April 2026',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Wash Only (4 Kg)',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: orderColor,
            ),
          ),

          Text(
            'Rp 40.000',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: orderColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineStep(
                'Pick Up',
                true,
                orderColor,
              ),

              _buildTimelineLine(true, orderColor),

              _buildTimelineStep(
                'Wash',
                true,
                orderColor,
              ),

              _buildTimelineLine(true, orderColor),

              _buildTimelineStep(
                'Dry',
                true,
                orderColor,
              ),

              _buildTimelineLine(false, orderColor),

              _buildTimelineStep(
                'Delivery',
                false,
                orderColor,
                isCurrent: true,
              ),

              _buildTimelineLine(false, orderColor),

              _buildTimelineStep(
                'Success',
                false,
                orderColor,
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: orderColor,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Track Your Order',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    bool isDone,
    Color themeColor, {
    bool isCurrent = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDone
                ? themeColor
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone || isCurrent
                  ? themeColor
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: isCurrent
              ? Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: themeColor,
                )
              : Icon(
                  isDone
                      ? Icons.check
                      : Icons.circle,
                  size: 8,
                  color: isDone
                      ? Colors.white
                      : Colors.transparent,
                ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDone || isCurrent
                ? themeColor
                : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(
    bool isDone,
    Color themeColor,
  ) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 14),
        color: isDone
            ? themeColor
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildScheduleCard() {
    const Color navyColor = Color(0xFF0C4B8E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick Up',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '16 April 2026',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),

                    Text(
                      '08:00 - 12:00 am',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick Up Address',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Jalan Kesana Kemari',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Colors.blue.shade100,
              thickness: 1,
            ),
          ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '20 April 2026',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),

                    Text(
                      '08:00 - 12:00 am',
                      style: GoogleFonts.poppins(
                        color: navyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Jalan Kesana Kemari',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: navyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    const Color navyColor = Color(0xFF0C4B8E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Receipt',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: navyColor,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Container(
                height: 2,
                color: navyColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #1232',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w600,
                          color: navyColor,
                        ),
                      ),

                      Text(
                        '16 April 2026',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE8F5E9,
                      ),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      'On Process',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildReceiptRow(
                'Customer',
                'Mark Lee',
              ),

              _buildReceiptRow(
                'Pick Up Method',
                'Delivery',
              ),

              _buildReceiptRow(
                'Delivered to',
                'Jalan Kesana Kesini',
              ),

              _buildReceiptRow(
                'Payment Method',
                'QRIS',
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Divider(
                  color: Colors.blue.shade100,
                  thickness: 1,
                ),
              ),

              Text(
                'Service Details',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'Wash Only (By Weight)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: navyColor,
                  fontSize: 14,
                ),
              ),

              Text(
                'Daily Wear',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 6),

              _buildPriceRow(
                '4 Kg x Rp 8.000',
                'Rp 32.000',
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Divider(
                  color: Colors.blue.shade100,
                  thickness: 1,
                ),
              ),

              _buildPriceRow(
                'Sub Total',
                'Rp 32.000',
                isBoldLabel: false,
              ),

              const SizedBox(height: 4),

              _buildPriceRow(
                'Delivery Fee',
                'Rp 8.000',
                isBoldLabel: false,
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Divider(
                  color: Colors.blue.shade100,
                  thickness: 1,
                ),
              ),

              _buildPriceRow(
                'Paid',
                'Rp 40.000',
                isTotal: true,
              ),

              const SizedBox(height: 24),

              BarcodeWidget(
                barcode: Barcode.code128(),
                data: 'Order#1232-MarkLee',
                drawText: false,
                height: 60,
                width: double.infinity,
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  '*Show this receipt when picking up your order',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0C4B8E),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String price, {
    bool isTotal = false,
    bool isBoldLabel = true,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isTotal
                ? const Color(0xFF0C4B8E)
                : (isBoldLabel
                    ? const Color(0xFF0C4B8E)
                    : Colors.grey),
            fontWeight:
                isTotal || isBoldLabel
                    ? FontWeight.w600
                    : FontWeight.normal,
            fontSize: isTotal ? 14 : 12,
          ),
        ),

        Text(
          price,
          style: GoogleFonts.poppins(
            color: const Color(0xFF0C4B8E),
            fontWeight: FontWeight.w600,
            fontSize: isTotal ? 14 : 12,
          ),
        ),
      ],
    );
  }
}