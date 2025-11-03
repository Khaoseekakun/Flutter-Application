// In a new file, e.g., billing_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Add 'intl' package for date formatting
import 'package:test1/Interfaces/interface.ProductsData.dart'; // Your product interface

class BillingScreen extends StatelessWidget {
  final Map<String, Product> productCarts;
  final Map<String, int> productAmounts;
  final double totalPrice;
  final String selectedPaymentMethod;
  final String? payment_session_id;

  const BillingScreen({
    super.key,
    required this.productCarts,
    required this.productAmounts,
    required this.totalPrice,
    required this.selectedPaymentMethod,
    this.payment_session_id
  });

  @override
  Widget build(BuildContext context) {
    final double tax = totalPrice * 0.07;
    final double subtotal = totalPrice - tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide the back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Icon and Message
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction has been completed.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Transaction Details Card
            _buildDetailsCard(subtotal, tax),
            const SizedBox(height: 24),

            // Itemized List Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 24),

            // Itemized List
            ...productCarts.entries.map((entry) {
              final product = entry.value;
              final quantity = productAmounts[entry.key] ?? 0;
              return ListTile(
                visualDensity: VisualDensity.compact,
                leading: Text('x$quantity', style: const TextStyle(fontSize: 16)),
                title: Text(product.name),
                trailing: Text(
                  '\$${(product.price * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            const Divider(height: 24),

            // Total Section in Itemized List
            ListTile(
              title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            // Navigate back to the root or the main shop screen
            Get.toNamed('/home'); // Or your home route
          },
          child: const Text('Done', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(double subtotal, double tax) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow('Transaction ID:', '${payment_session_id!.startsWith("pi") ? "" : "TXN"}${payment_session_id ?? 'N/A'}'),
            const SizedBox(height: 8),
            _buildDetailRow('Date:', DateFormat('d MMM yyyy, HH:mm').format(DateTime.now())),
            const SizedBox(height: 8),
            _buildDetailRow('Payment Method:', selectedPaymentMethod.capitalizeFirst ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade700)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}