import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/providers/app_provider.dart';
import 'package:mobile/models/driver.dart';
import '../theme.dart';

class AddDriverScreen extends StatefulWidget {
  final Driver? driver;
  const AddDriverScreen({super.key, this.driver});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _workingCityController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accHolderNameController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  DateTime? _dob;
  DateTime? _licenseExpiry;
  String? _gender;
  String? _preferredTime;
  String? _employmentType;
  String? _licenseType;

  @override
  void initState() {
    super.initState();
    debugPrint('🏁 AddDriverScreen: initState. driver: ${widget.driver}');
    if (widget.driver != null) {
      final d = widget.driver!;
      _nameController.text = d.name;
      _mobileController.text = d.phoneNumber ?? '';
      _emailController.text = d.email ?? '';
      _currentAddressController.text = d.currentAddress ?? '';
      _permanentAddressController.text = d.permanentAddress ?? '';
      _cityController.text = d.city ?? '';
      _stateController.text = d.state ?? '';
      _pincodeController.text = d.pincode ?? '';
      _workingCityController.text = d.workingCity ?? '';
      _yearsOfExperienceController.text = d.yearsOfExperience ?? '';
      _emergencyNameController.text = d.emergencyContactName ?? '';
      _emergencyRelationshipController.text = d.emergencyRelationship ?? '';
      _emergencyNumberController.text = d.emergencyContactNumber ?? '';
      _licenseNumberController.text = d.licenseNumber ?? '';
      _aadhaarNumberController.text = d.aadhaarNumber ?? '';
      _bankNameController.text = d.bankName ?? '';
      _accHolderNameController.text = d.accountHolderName ?? '';
      _accNumberController.text = d.accountNumber ?? '';
      _ifscController.text = d.ifscCode ?? '';
      _upiController.text = d.upiId ?? '';

      _dob = d.dateOfBirth;
      _licenseExpiry = d.licenseExpiry;
      _gender = d.gender;
      _preferredTime = d.preferredTime;
      _employmentType = d.employmentType;
      _licenseType = d.licenseType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _currentAddressController.dispose();
    _permanentAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _workingCityController.dispose();
    _yearsOfExperienceController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyNumberController.dispose();
    _licenseNumberController.dispose();
    _aadhaarNumberController.dispose();
    _bankNameController.dispose();
    _accHolderNameController.dispose();
    _accNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
        } else {
          _licenseExpiry = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final appProvider = context.read<AppProvider>();
      final isEdit = widget.driver != null;
      
      final driverData = Driver(
        id: isEdit ? widget.driver!.id : '',
        name: _nameController.text.trim(),
        phoneNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        hubId: isEdit ? widget.driver!.hubId : appProvider.selectedHub,
        dateOfBirth: _dob,
        gender: _gender,
        currentAddress: _currentAddressController.text.trim(),
        permanentAddress: _permanentAddressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        workingCity: _workingCityController.text.trim(),
        preferredTime: _preferredTime,
        employmentType: _employmentType,
        yearsOfExperience: _yearsOfExperienceController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyRelationship: _emergencyRelationshipController.text.trim(),
        emergencyContactNumber: _emergencyNumberController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        licenseType: _licenseType,
        licenseExpiry: _licenseExpiry,
        aadhaarNumber: _aadhaarNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountHolderName: _accHolderNameController.text.trim(),
        accountNumber: _accNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        upiId: _upiController.text.trim(),
        isActive: isEdit ? widget.driver!.isActive : true,
        createdAt: isEdit ? widget.driver!.createdAt : null,
      );
      
      if (isEdit) {
        await appProvider.updateDriver(driverData);
      } else {
        await appProvider.addDriver(driverData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Driver updated successfully' : 'Driver added successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDriver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${_nameController.text}?'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await context.read<AppProvider>().removeDriver(widget.driver!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Driver deleted successfully'), backgroundColor: AppTheme.primaryGreen),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerRed),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.driver != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Driver' : 'Add Driver', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.white),
              onPressed: _deleteDriver,
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionHeader(LucideIcons.user, 'Personal Information'),
                    _buildTextField(_nameController, 'Name *', LucideIcons.user, required: true),
                    _buildTextField(_mobileController, 'Mobile Number *', LucideIcons.phone, keyboardType: TextInputType.phone, required: true),
                    _buildTextField(_emailController, 'Email', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                    _buildDatePicker('Date of Birth', _dob, () => _selectDate(context, true)),
                    _buildDropdown('Gender', _gender, ['Male', 'Female', 'Other'], (val) => setState(() => _gender = val)),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(LucideIcons.mapPin, 'Address'),
                    _buildTextField(_currentAddressController, 'Current Address', LucideIcons.home),
                    _buildTextField(_permanentAddressController, 'Permanent Address', LucideIcons.home),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_cityController, 'City', null)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_stateController, 'State', null)),
                      ],
                    ),
                    _buildTextField(_pincodeController, 'Pincode', LucideIcons.hash, keyboardType: TextInputType.number),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(LucideIcons.briefcase, 'Work Information'),
                    _buildTextField(_workingCityController, 'Working City', LucideIcons.map),
                    _buildDropdown('Preferred Time', _preferredTime, ['Day Shift', 'Night Shift', 'Any'], (val) => setState(() => _preferredTime = val)),
                    _buildDropdown('Employment Type', _employmentType, ['Full-time', 'Part-time', 'Contract'], (val) => setState(() => _employmentType = val)),
                    _buildTextField(_yearsOfExperienceController, 'Years of Experience', LucideIcons.award, keyboardType: TextInputType.number),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(LucideIcons.phoneCall, 'Emergency Contact'),
                    _buildTextField(_emergencyNameController, 'Contact Name', LucideIcons.user),
                    _buildTextField(_emergencyRelationshipController, 'Relationship', LucideIcons.users),
                    _buildTextField(_emergencyNumberController, 'Contact Number', LucideIcons.phone, keyboardType: TextInputType.phone),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(LucideIcons.creditCard, 'License & Documents'),
                    _buildTextField(_licenseNumberController, 'License Number', LucideIcons.fileText),
                    _buildDropdown('License Type', _licenseType, ['MCWG', 'LMV', 'HMV'], (val) => setState(() => _licenseType = val)),
                    _buildDatePicker('License Expiry', _licenseExpiry, () => _selectDate(context, false)),
                    _buildTextField(_aadhaarNumberController, 'Aadhaar Number', LucideIcons.hash, keyboardType: TextInputType.number),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader(LucideIcons.landmark, 'Bank Details'),
                    _buildTextField(_bankNameController, 'Bank Name', LucideIcons.landmark),
                    _buildTextField(_accHolderNameController, 'Account Holder Name', LucideIcons.user),
                    _buildTextField(_accNumberController, 'Account Number', LucideIcons.hash, keyboardType: TextInputType.number),
                    _buildTextField(_ifscController, 'IFSC Code', LucideIcons.building),
                    _buildTextField(_upiController, 'UPI ID', LucideIcons.zap),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _submit,
                        child: Text(isEdit ? 'Update Driver' : 'Add Driver', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? icon, {TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: required ? (value) => value == null || value.isEmpty ? 'Required field' : null : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(LucideIcons.calendar, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Select date',
            style: TextStyle(color: value != null ? AppTheme.textDark : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
