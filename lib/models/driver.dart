class Driver {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? licenseNumber;
  final String? hubId;
  final bool isActive;
  final DateTime? createdAt;
  
  // Personal Info
  final DateTime? dateOfBirth;
  final String? gender;
  
  // Address
  final String? currentAddress;
  final String? permanentAddress;
  final String? city;
  final String? state;
  final String? pincode;
  
  // Work Info
  final String? workingCity;
  final String? preferredTime;
  final String? employmentType;
  final String? yearsOfExperience;
  
  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyRelationship;
  final String? emergencyContactNumber;
  
  // Documents
  final String? licenseType;
  final DateTime? licenseExpiry;
  final String? aadhaarNumber;
  
  // Bank Details
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;

  Driver({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.licenseNumber,
    this.hubId,
    this.isActive = true,
    this.createdAt,
    this.dateOfBirth,
    this.gender,
    this.currentAddress,
    this.permanentAddress,
    this.city,
    this.state,
    this.pincode,
    this.workingCity,
    this.preferredTime,
    this.employmentType,
    this.yearsOfExperience,
    this.emergencyContactName,
    this.emergencyRelationship,
    this.emergencyContactNumber,
    this.licenseType,
    this.licenseExpiry,
    this.aadhaarNumber,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['driver_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['driver_name']?.toString() ?? json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      email: json['email']?.toString(),
      licenseNumber: json['license_number']?.toString(),
      hubId: json['hub_id']?.toString(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      gender: json['gender']?.toString(),
      currentAddress: json['current_address']?.toString(),
      permanentAddress: json['permanent_address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      workingCity: json['working_city']?.toString(),
      preferredTime: json['preferred_time']?.toString(),
      employmentType: json['employment_type']?.toString(),
      yearsOfExperience: json['years_of_experience']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyRelationship: json['emergency_relationship']?.toString(),
      emergencyContactNumber: json['emergency_contact_number']?.toString(),
      licenseType: json['license_type']?.toString(),
      licenseExpiry: json['license_expiry'] != null ? DateTime.parse(json['license_expiry']) : null,
      aadhaarNumber: json['aadhaar_number']?.toString(),
      bankName: json['bank_name']?.toString(),
      accountHolderName: json['account_holder_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      upiId: json['upi_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': id,
      'driver_name': name,
      'phone_number': phoneNumber,
      'email': email,
      'license_number': licenseNumber,
      'hub_id': hubId,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'working_city': workingCity,
      'preferred_time': preferredTime,
      'employment_type': employmentType,
      'years_of_experience': yearsOfExperience,
      'emergency_contact_name': emergencyContactName,
      'emergency_relationship': emergencyRelationship,
      'emergency_contact_number': emergencyContactNumber,
      'license_type': licenseType,
      'license_expiry': licenseExpiry?.toIso8601String(),
      'aadhaar_number': aadhaarNumber,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
    };
  }

  @override
  String toString() {
    return 'Driver(id: $id, name: $name, phone: $phoneNumber)';
  }
}
