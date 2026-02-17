import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firm_model.dart';
import 'firm_service.dart';
import '../../core/active_firm_provider.dart';

class FirmFormScreen extends StatefulWidget {
  final Firm? firm;
  final bool isFirstSetup;

  const FirmFormScreen({
    super.key,
    this.firm,
    this.isFirstSetup = false,
  });

  @override
  State<FirmFormScreen> createState() => _FirmFormScreenState();
}

class _FirmFormScreenState extends State<FirmFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _gstController;
  late TextEditingController _panController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.firm?.name ?? '');
    _codeController = TextEditingController(text: widget.firm?.code ?? '');
    _ownerNameController =
        TextEditingController(text: widget.firm?.owner_name ?? '');
    _phoneController = TextEditingController(text: widget.firm?.phone ?? '');
    _emailController = TextEditingController(text: widget.firm?.email ?? '');
    _addressController =
        TextEditingController(text: widget.firm?.address ?? '');
    _cityController = TextEditingController(text: widget.firm?.city ?? '');
    _stateController = TextEditingController(text: widget.firm?.state ?? '');
    _pincodeController =
        TextEditingController(text: widget.firm?.pincode ?? '');
    _gstController = TextEditingController(text: widget.firm?.gst_number ?? '');
    _panController = TextEditingController(text: widget.firm?.pan_number ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _saveFirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();

      if (widget.firm == null) {
        final newFirm = Firm(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          owner_name: _ownerNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          gst_number: _gstController.text.trim().isNotEmpty
              ? _gstController.text.trim()
              : null,
          pan_number: _panController.text.trim().isNotEmpty
              ? _panController.text.trim()
              : null,
          active: false,
          created_at: now,
          updated_at: now,
        );

        final firmId = await FirmService.addFirm(newFirm);

        final createdFirm = await FirmService.getFirmById(firmId);

        if (createdFirm != null) {
          final provider =
              Provider.of<ActiveFirmProvider>(context, listen: false);
          await provider.setActiveFirm(createdFirm);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('फर्म यशस्वीरित्या जोडला गेला'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 🔥 UPDATE FIRM
        final updatedFirm = widget.firm!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          owner_name: _ownerNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          gst_number: _gstController.text.trim().isNotEmpty
              ? _gstController.text.trim()
              : null,
          pan_number: _panController.text.trim().isNotEmpty
              ? _panController.text.trim()
              : null,
          updated_at: now,
        );

        await FirmService.updateFirm(updatedFirm);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('फर्म यशस्वीरित्या अपडेट झाले'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;

      if (!widget.isFirstSetup) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFirstSetup
              ? 'पहिली फर्म तयार करा'
              : (widget.firm == null ? 'नवीन फर्म' : 'फर्म संपादित करा'),
        ),
        automaticallyImplyLeading: !widget.isFirstSetup,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'फर्मचे नाव *',
                hint: 'फर्मचे नाव प्रविष्ट करा',
                icon: Icons.business,
                validator: (v) =>
                    v == null || v.isEmpty ? 'फर्मचे नाव आवश्यक आहे' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ownerNameController,
                label: 'मालकाचे नाव *',
                hint: 'मालकाचे नाव',
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.isEmpty ? 'मालकाचे नाव आवश्यक आहे' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'फोन नंबर *',
                hint: '१०-अंकी नंबर',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'फोन नंबर आवश्यक आहे';
                  if (v.length != 10) return 'फोन नंबर १० अंकांचा असावा';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Optional Fields Below
              _buildTextField(
                controller: _codeController,
                label: 'फर्म कोड',
                hint: 'वैकल्पिक',
                icon: Icons.code,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'ईमेल',
                hint: 'वैकल्पिक',
                icon: Icons.email,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'सेव करा',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
