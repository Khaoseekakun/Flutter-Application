import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Interfaces/interface.ProductsData.dart';
import 'Billing.dart';

class PaymentProcessScreen extends StatefulWidget {
  final Map<String, Product> productCarts;
  final Map<String, int> productAmounts;
  final double totalPrice;
  final String selectedPaymentMethod;
  final Future<void> Function()? onPaymentSuccess;
  final String? initialQrCodeUrl;
  final String? initialPaymentSessionId;

  const PaymentProcessScreen({
    super.key,
    required this.productCarts,
    required this.productAmounts,
    required this.totalPrice,
    required this.selectedPaymentMethod,
    this.onPaymentSuccess,
    this.initialQrCodeUrl,
    this.initialPaymentSessionId,
  });

  @override
  State<PaymentProcessScreen> createState() => _PaymentProcessScreenState();
}

class _PaymentProcessScreenState extends State<PaymentProcessScreen> {
  String? _qrCodeUrl;
  String? _paymentSessionId;
  String _statusMessage = 'Initializing payment...';
  bool _isInitializing = true;
  bool _hasError = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPaymentSessionId != null &&
        widget.initialQrCodeUrl != null &&
        widget.initialQrCodeUrl!.isNotEmpty) {
      // Use pre-created payment and start polling immediately
      _paymentSessionId = widget.initialPaymentSessionId;
      _qrCodeUrl = widget.initialQrCodeUrl;
      _isInitializing = false;
      _statusMessage = 'Scan the QR code to complete the payment.';
      _startPolling();
      setState(() {});
    } else {
      _initializePayment();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    final apiUrl = dotenv.env['API_URL'];

    if (apiUrl == null || apiUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _isInitializing = false;
        _statusMessage = 'API_URL is not configured.';
      });
      return;
    }

    setState(() {
      _qrCodeUrl = null;
      _paymentSessionId = null;
      _hasError = false;
      _isInitializing = true;
      _statusMessage = 'Initializing payment...';
    });

    try {
      // Get saved JWT token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        setState(() {
          _hasError = true;
          _isInitializing = false;
          _statusMessage = 'You are not logged in.';
        });
        return;
      }

      final response = await http.post(
        Uri.parse('$apiUrl/api/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          // Backend expects: amount, optional currency/name/email/order_ids/code
          'amount': widget.totalPrice,
          'currency': 'thb',
          // Send method name if backend wants it in metadata (harmless if ignored)
          'code': widget.selectedPaymentMethod,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final qrUrl = data['qrcode_url'] ?? data['qr_code_url'];
        final sessionId = data['payment_session_id']?.toString();

        if (sessionId == null || (qrUrl == null || (qrUrl as String).isEmpty)) {
          setState(() {
            _hasError = true;
            _isInitializing = false;
            _statusMessage = 'Invalid response from server.';
          });
          return;
        }

        setState(() {
          _qrCodeUrl = qrUrl;
          _paymentSessionId = sessionId;
          _isInitializing = false;
          _statusMessage = 'Scan the QR code to complete the payment.';
        });

        _startPolling();
      } else {
        final message = _extractErrorMessage(response.body);
        setState(() {
          _hasError = true;
          _isInitializing = false;
          _statusMessage = message;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isInitializing = false;
        _statusMessage = 'Failed to initialize payment. Please try again.';
      });
      debugPrint('Payment initialization error: $e');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus();
    });
  }

  Future<void> _cancelPayment() async {
    final sessionId = _paymentSessionId;
    final apiUrl = dotenv.env['API_URL'];
    if (sessionId == null || apiUrl == null || apiUrl.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    try {
      // Get saved JWT token for authorized request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;

      final response = await http.delete(
        Uri.parse('$apiUrl/api/payments/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Payment status check failed: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (data['status'] ?? data['payment_status'])
          ?.toString()
          .toLowerCase();

      if (status == null) {
        return;
      }

      if (status == "canceled") {
        Get.snackbar(
          'Payment',
          'ยกเลิกการชำระเงินสำเร็จ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
        );
        Get.back();
      } else {
        Get.snackbar(
          'Payment',
          'ไม่สามารถยกเลิกการชำระเงินได้',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
  }

  Future<void> _checkPaymentStatus() async {
    final sessionId = _paymentSessionId;
    final apiUrl = dotenv.env['API_URL'];

    if (sessionId == null || apiUrl == null || apiUrl.isEmpty) return;

    try {
      // Get saved JWT token for authorized request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;

      final response = await http.post(
        Uri.parse('$apiUrl/api/payments/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Payment status check failed: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (data['status'] ?? data['payment_status'])
          ?.toString()
          .toLowerCase();

      if (status == null) {
        return;
      }

      // Stripe PaymentIntent success state is 'succeeded'
      if (status == 'succeeded' ||
          status == 'success' ||
          status == 'paid' ||
          status == 'completed') {
        _pollingTimer?.cancel();
        await _handlePaymentSuccess();
      } else if (status == 'failed' ||
          status == 'cancelled' ||
          status == 'canceled') {
        _pollingTimer?.cancel();
        if (!mounted) return;
        
        Get.back();
        setState(() {
          _hasError = true;
          _statusMessage = 'Payment $status. Please try again.';
        });
        Get.snackbar(
          'Payment',
          'Payment $status. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (widget.onPaymentSuccess != null) {
      await widget.onPaymentSuccess!();
    }

    if (!mounted) return;

    Get.snackbar(
      'Success',
      'Payment completed successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade400,
      colorText: Colors.white,
    );

    Get.off(
      () => BillingScreen(
        productCarts: widget.productCarts,
        productAmounts: widget.productAmounts,
        totalPrice: widget.totalPrice,
        selectedPaymentMethod: widget.selectedPaymentMethod,
      ),
    );
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final message = data['message'] ?? data['error'];
      if (message != null) {
        return message.toString();
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
    }
    return 'Failed to initialize payment. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Processing'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isInitializing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ] else if (_hasError) ...[
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initializePayment,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ] else ...[
                if (_qrCodeUrl != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      _qrCodeUrl!,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: Text(
                              'Unable to load QR code',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Amount: \$${widget.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _cancelPayment();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Payment'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
