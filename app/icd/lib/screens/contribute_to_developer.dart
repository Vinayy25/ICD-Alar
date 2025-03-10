import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/widgets/alar.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ContributeToDeveloper extends StatefulWidget {
  const ContributeToDeveloper({super.key});

  @override
  State<ContributeToDeveloper> createState() => _ContributeToDeveloperState();
}

class _ContributeToDeveloperState extends State<ContributeToDeveloper> {
  final _customAmountController = TextEditingController();
  int _selectedAmount = 199; // Default selected amount
  bool _isCustomAmount = false;
  bool _isLoading = false;

  // Initialize Razorpay
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // Predefined donation amounts
  final List<int> _predefinedAmounts = [99, 199, 299, 399];

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Show success message
    _showSuccessDialog(response.paymentId!);

    // Reset UI state
    setState(() {
      _isLoading = false;
    });

    // Log payment success
    print(
        "Payment Success: PaymentId: ${response.paymentId}, OrderId: ${response.orderId}, Signature: ${response.signature}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isLoading = false;
    });

    // Show error toast
    Fluttertoast.showToast(
      msg: "ERROR: ${response.code} - ${response.message}",
      timeInSecForIosWeb: 4,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    print("Payment Failed: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isLoading = false;
    });

    Fluttertoast.showToast(
      msg: "EXTERNAL_WALLET: ${response.walletName}",
      timeInSecForIosWeb: 4,
    );

    print("External Wallet Selected: ${response.walletName}");
  }

  // Launch Razorpay with selected amount
  void _startRazorpayPayment() {
    setState(() => _isLoading = true);

    try {
      // Get the final amount (either selected or custom)
      int amount = _isCustomAmount
          ? int.tryParse(_customAmountController.text) ?? _selectedAmount
          : _selectedAmount;

      // Razorpay accepts amount in the smallest currency unit
      // For INR, 100 paise = ₹1, so multiply by 100
      int amountInSmallestUnit = amount * 100;

      // Set up payment options
      var options = {
        'key':
            'rzp_test_i28wsJwStT5S3X', // Replace with your actual Razorpay key
        'amount': amountInSmallestUnit,
        'name': 'ICD-11 App',
        'description': 'Support ICD-11 App Development',
        'prefill': {
          'contact': '',
          'email': '',
        },
        'external': {
          'wallets': ['paytm']
        },
        'theme': {
          'color': '#3F51B5', // Match your app's primary color
        }
      };

      print("Opening Razorpay with options: $options");
      _razorpay.open(options);
    } catch (e) {
      print("Error starting Razorpay payment: $e");
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/search_animation/success.json',
                height: 120, repeat: false),
            const Text('Thank You!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your contribution has been received.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Payment ID: $paymentId',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support the Developer'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Animation and header
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Lottie.asset(
                          'assets/search_animation/donate.json',
                          repeat: true,
                          animate: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Support ICD-11 App Development',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 600.ms),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Your contribution helps us maintain and improve this free ICD-11 reference app',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Predefined amounts section
                Text(
                  'Select an amount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount selection grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    // Predefined amount buttons
                    ..._predefinedAmounts.map((amount) => _buildAmountButton(
                          amount: amount,
                          isSelected:
                              !_isCustomAmount && _selectedAmount == amount,
                          onTap: () {
                            setState(() {
                              _isCustomAmount = false;
                              _selectedAmount = amount;
                            });
                          },
                        )),

                    // Custom amount button
                    _buildAmountButton(
                      label: 'Custom',
                      isSelected: _isCustomAmount,
                      onTap: () {
                        setState(() {
                          _isCustomAmount = true;
                        });
                        // Show custom amount dialog
                        _showCustomAmountDialog();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Display selected amount or custom amount
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  color:
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are contributing:',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _isCustomAmount &&
                                    _customAmountController.text.isNotEmpty
                                ? Text(
                                    _customAmountController.text,
                                    style:
                                        theme.textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Text(
                                    '$_selectedAmount',
                                    style:
                                        theme.textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Developer info card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset('assets/icons/alar_logo.png'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ALAR Innovations',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Developer',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your contribution will help us maintain the app, add new features, and keep it updated with the latest ICD-11 data.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom donate button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity, // Full width
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      Color.lerp(theme.colorScheme.primary,
                              theme.colorScheme.tertiary, 0.6) ??
                          theme.colorScheme.primary,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _startRazorpayPayment,
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Processing...',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Contribute Now',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms),
            ),
          ),

          // Footer
          const AlarFooter(),
        ],
      ),
    );
  }

  // Custom amount dialog
  Future<void> _showCustomAmountDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Custom Amount'),
          content: TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              prefixText: '₹ ',
              hintText: 'Amount (min ₹10)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                int? amount = int.tryParse(_customAmountController.text);
                if (amount != null && amount >= 10) {
                  setState(() {
                    _selectedAmount = amount;
                    _isCustomAmount = true;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount (min ₹10)')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Build amount selection button
  Widget _buildAmountButton({
    int? amount,
    String? label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
