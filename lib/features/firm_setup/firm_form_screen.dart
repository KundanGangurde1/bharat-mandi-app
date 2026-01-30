import 'package:flutter/material.dart';
import 'firm_model.dart';
import 'firm_service.dart';

class FirmFormScreen extends StatefulWidget {
  final Firm? firm;

  const FirmFormScreen({super.key, this.firm});

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.firm == null) {
        // नवीन फर्म जोडा
        final newFirm = Firm(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isNotEmpty
              ? _codeController.text.trim()
              : null,
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
          created_at: DateTime.now().toIso8601String(),
        );

        await FirmService.addFirm(newFirm);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('फर्म यशस्वीरित्या जोडला गेला'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // फर्म update करा
        final updatedFirm = widget.firm!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isNotEmpty
              ? _codeController.text.trim()
              : null,
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
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firm == null ? 'नवीन फर्म' : 'फर्म संपादित करा'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // फर्मचे नाव
              _buildTextField(
                controller: _nameController,
                label: 'फर्मचे नाव',
                hint: 'फर्मचे नाव प्रविष्ट करा',
                icon: Icons.business,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'फर्मचे नाव आवश्यक आहे';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // फर्म कोड (optional)
              _buildTextField(
                controller: _codeController,
                label: 'फर्म कोड (वैकल्पिक)',
                hint: 'फर्मचा अद्वितीय कोड',
                icon: Icons.code,
              ),

              const SizedBox(height: 16),

              // मालकाचे नाव
              _buildTextField(
                controller: _ownerNameController,
                label: 'मालकाचे नाव',
                hint: 'मालकाचे नाव प्रविष्ट करा',
                icon: Icons.person,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'मालकाचे नाव आवश्यक आहे';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // फोन नंबर
              _buildTextField(
                controller: _phoneController,
                label: 'फोन नंबर',
                hint: '१०-अंकी फोन नंबर',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'फोन नंबर आवश्यक आहे';
                  }
                  if (value!.length != 10) {
                    return 'फोन नंबर १० अंकांचा असावा';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ईमेल
              _buildTextField(
                controller: _emailController,
                label: 'ईमेल',
                hint: 'ईमेल पत्ता प्रविष्ट करा',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'ईमेल आवश्यक आहे';
                  }
                  if (!value!.contains('@')) {
                    return 'वैध ईमेल प्रविष्ट करा';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // पत्ता
              _buildTextField(
                controller: _addressController,
                label: 'पत्ता',
                hint: 'संपूर्ण पत्ता प्रविष्ट करा',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'पत्ता आवश्यक आहे';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // शहर
              _buildTextField(
                controller: _cityController,
                label: 'शहर',
                hint: 'शहराचे नाव प्रविष्ट करा',
                icon: Icons.location_city,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'शहर आवश्यक आहे';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // राज्य
              _buildTextField(
                controller: _stateController,
                label: 'राज्य',
                hint: 'राज्याचे नाव प्रविष्ट करा',
                icon: Icons.map,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'राज्य आवश्यक आहे';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // पिनकोड
              _buildTextField(
                controller: _pincodeController,
                label: 'पिनकोड',
                hint: '६-अंकी पिनकोड',
                icon: Icons.pin,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'पिनकोड आवश्यक आहे';
                  }
                  if (value!.length != 6) {
                    return 'पिनकोड ६ अंकांचा असावा';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // GST नंबर
              _buildTextField(
                controller: _gstController,
                label: 'GST क्रमांक (वैकल्पिक)',
                hint: 'GST क्रमांक प्रविष्ट करा',
                icon: Icons.receipt,
              ),

              const SizedBox(height: 16),

              // PAN नंबर
              _buildTextField(
                controller: _panController,
                label: 'PAN क्रमांक (वैकल्पिक)',
                hint: 'PAN क्रमांक प्रविष्ट करा',
                icon: Icons.credit_card,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveFirm,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading
                        ? 'सेव होत आहे...'
                        : (widget.firm == null ? 'फर्म जोडा' : 'अपडेट करा'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('रद्द करा'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
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
    int maxLines = 1,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
