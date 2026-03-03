import 'package:dynamsoft_mrz_scanner_bundle_flutter/dynamsoft_mrz_scanner_bundle_flutter.dart';

/// A view-model wrapper around [MRZData] that exposes display-friendly strings.
class MrzResultModel {
  MrzResultModel({required MRZData data}) : _data = data;

  final MRZData _data;

  String get fullName => '${_data.firstName} ${_data.lastName}'.trim();
  String get sex => _capitalize(_data.sex);
  String get age => _data.age.toString();
  String get documentType => _data.documentType;
  String get documentNumber => _data.documentNumber;
  String get issuingState => _data.issuingState;
  String get nationality => _data.nationality;
  String get dateOfBirth => _data.dateOfBirth;
  String get dateOfExpiry => _data.dateOfExpire;

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Returns all fields as a list of label/value pairs for rendering.
  List<({String label, String value})> get fields => [
        (label: 'Full Name', value: fullName),
        (label: 'Sex', value: sex),
        (label: 'Age', value: age),
        (label: 'Document Type', value: documentType),
        (label: 'Document Number', value: documentNumber),
        (label: 'Issuing State', value: issuingState),
        (label: 'Nationality', value: nationality),
        (label: 'Date of Birth', value: dateOfBirth),
        (label: 'Date of Expiry', value: dateOfExpiry),
      ];
}
