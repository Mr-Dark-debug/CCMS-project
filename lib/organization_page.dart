/* TO SUBMIT THE DATA AND STORE IT IN A LIST AND THEN SHOW THAT IN THE AUDITOR PAGE */



import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './comp/models.dart'; // Import the model and manager

class OrganizationPage extends StatefulWidget {
  @override
  OrganizationPageState createState() => OrganizationPageState();
}

class OrganizationPageState extends State<OrganizationPage> {
  String? _uploadedFileName;
  Uint8List? _uploadedFileBytes;
  bool _fileUploaded = false;
  final Map<String, dynamic> _emissionData = {};
  String _orgName = '';
  String? _orgType;
  bool _limitExceeded = false;
  double _totalEmissions = 0.0;
  double _emissionLimit = 0.0;

  // Emission limits for various organization types
  final Map<String, double> _emissionLimits = {
    'Manufacturing': 200.0,
    'Energy': 150.0,
    'Transportation': 100.0,
    'Construction': 120.0,
    'Agriculture': 80.0,
    'Technology': 90.0,
  };

  // Pick Excel file and process it
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        if (fileBytes != null) {
          _parseExcelBytes(fileBytes); // Parse Excel file and calculate emissions
          setState(() {
            _fileUploaded = true;
            _uploadedFileName = file.name;
          });
        }
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  // Parse Excel file and calculate total emissions
  void _parseExcelBytes(Uint8List bytes) {
    try {
      var excel = Excel.decodeBytes(bytes);
      _emissionData.clear();
      _totalEmissions = 0.0;

      if (excel.tables.isNotEmpty) {
        var sheet = excel.tables[excel.tables.keys.first]!;

        bool isFirstRow = true;

        for (var row in sheet.rows) {
          if (isFirstRow) {
            isFirstRow = false;
            continue;
          }

          // Only process if there are at least 2 columns and column B exists
          if (row.length >= 2 && row[1]?.value != null) {
            String cellValue = row[1]!.value.toString().trim();

            if (cellValue.isNotEmpty) {
              try {
                double? amount = double.tryParse(cellValue);
                if (amount != null) {
                  _totalEmissions += amount;
                }
              } catch (e) {
                print('Skipping invalid number in column B: $cellValue');
              }
            }
          }
        }
      }

      setState(() {
        _checkLimit();
      });
    } catch (e) {
      print('Error processing Excel file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading Excel file. Please ensure the file format is correct.')),
      );
    }
  }

  // Check if the total emissions exceed the emission limit for the selected organization type
  void _checkLimit() {
    if (_orgType != null) {
      _emissionLimit = _emissionLimits[_orgType!] ?? 0.0;
      setState(() {
        _limitExceeded = _totalEmissions > _emissionLimit;
      });
    }
  }

  // Submit data to SubmissionManager and store in SharedPreferences
  void _submitData() async {
    if (_orgName.isEmpty || _orgType == null || !_fileUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields and upload an Excel file.')),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // Create a new OrganizationSubmission object
    OrganizationSubmission submission = OrganizationSubmission(
      orgName: _orgName,
      orgType: _orgType!,
      submissionDate: now,
      fileName: _uploadedFileName!,
      totalEmissions: _totalEmissions,
      emissionLimit: _emissionLimit,
    );

    // Add submission to SubmissionManager
    SubmissionManager().addSubmission(submission);

    // Persist submission data in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? submissions = prefs.getStringList('submissions') ?? [];
    submissions.add({
      'orgName': _orgName,
      'orgType': _orgType,
      'fileName': _uploadedFileName,
      'submissionDate': formattedDate,
      'totalEmissions': _totalEmissions,
      'emissionLimit': _emissionLimit,
      'approved': submission.approved,
      'fine': submission.fine,
    }.toString());
    await prefs.setStringList('submissions', submissions);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data submitted successfully!')),
    );

    // Reset form fields
    setState(() {
      _clearForm();
    });
  }

  // Clear form after submission
  void _clearForm() {
    _orgName = '';
    _orgType = null;
    _fileUploaded = false;
    _uploadedFileName = null;
    _totalEmissions = 0.0;
    _emissionLimit = 0.0;
    _limitExceeded = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Emission Tracker'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organization Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Organization Name',
                  prefixIcon: Icon(Icons.business, color: Colors.teal),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _orgName = value;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Organization Type',
                  prefixIcon: Icon(Icons.category, color: Colors.teal),
                  border: OutlineInputBorder(),
                ),
                value: _orgType,
                items: _emissionLimits.keys.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _orgType = value;
                    _checkLimit();
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.upload_file, color: Colors.white),
                label: Text('Upload Excel File', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Match the HomePage button color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              SizedBox(height: 16),
              _fileUploaded
                  ? Text('File Uploaded: $_uploadedFileName', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))
                  : Text('No file uploaded yet.', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitData,
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text('Submit', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Match the HomePage button color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              SizedBox(height: 16),
              if (_fileUploaded && _orgType != null) ...[
                Text(
                  _limitExceeded
                      ? 'Emission Limit Exceeded! ($_totalEmissions out of $_emissionLimit)'
                      : 'Emissions within Limit ($_totalEmissions out of $_emissionLimit)',
                  style: TextStyle(
                    color: _limitExceeded ? Colors.red : Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              SizedBox(height: 32),
              Text(
                'Note: Ensure the uploaded Excel file contains valid emission data.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





/* TRYING TO IMPLMENT THE RADAR GRAPH AND PIE CHART */


// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:excel/excel.dart';
// import 'dart:typed_data';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

// class OrganizationPage extends StatefulWidget {
//   @override
//   OrganizationPageState createState() => OrganizationPageState();
// }

// class OrganizationPageState extends State<OrganizationPage> {
//   String? _uploadedFileName;
//   Uint8List? _uploadedFileBytes;
//   bool _fileUploaded = false;
//   final Map<String, dynamic> _emissionData = {};
//   String _orgName = '';
//   String? _orgType;
//   bool _limitExceeded = false;
//   double _totalEmissions = 0.0;
//   double _emissionLimit = 0.0;

//   final Map<String, double> _emissionLimits = {
//     'Manufacturing': 200.0,
//     'Energy': 150.0,
//     'Transportation': 100.0,
//     'Construction': 120.0,
//     'Agriculture': 80.0,
//     'Technology': 90.0,
//   };

//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['xlsx'],
//       );

//       if (result != null && result.files.isNotEmpty) {
//         final file = result.files.first;
//         final fileBytes = file.bytes;
//         if (fileBytes != null) {
//           _parseExcelBytes(fileBytes);
//           setState(() {
//             _fileUploaded = true;
//             _uploadedFileName = file.name;
//           });
//         }
//       }
//     } catch (e) {
//       print('Error picking file: $e');
//     }
//   }

//   void _parseExcelBytes(Uint8List bytes) {
//     try {
//       var excel = Excel.decodeBytes(bytes);
//       _emissionData.clear();
//       _totalEmissions = 0.0;

//       if (excel.tables.isNotEmpty) {
//         var sheet = excel.tables[excel.tables.keys.first]!;

//         print('Processing sheet: ${excel.tables.keys.first}');
//         bool isFirstRow = true;

//         for (var row in sheet.rows) {
//           if (isFirstRow) {
//             isFirstRow = false;
//             continue;
//           }

//           if (row.length >= 2 && row[1]?.value != null) {
//             String cellValue = row[1]!.value.toString().trim();

//             if (cellValue.isNotEmpty) {
//               try {
//                 double? amount = double.tryParse(cellValue);
//                 if (amount != null) {
//                   _totalEmissions += amount;
//                   print('Valid amount found in column B: $amount, Running total: $_totalEmissions');
//                 }
//               } catch (e) {
//                 print('Skipping invalid number in column B: $cellValue');
//               }
//             }
//           }
//         }
//       }

//       print('Final total emissions calculated: $_totalEmissions');
//       setState(() {
//         _checkLimit();
//       });
//     } catch (e) {
//       print('Error processing Excel file: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error reading Excel file. Please ensure the file format is correct.')),
//       );
//     }
//   }

//   void _checkLimit() {
//     if (_orgType != null) {
//       _emissionLimit = _emissionLimits[_orgType!] ?? 0.0;
//       setState(() {
//         _limitExceeded = _totalEmissions > _emissionLimit;
//       });
//     }
//   }

//   void _submitData() async {
//     if (_orgName.isEmpty || _orgType == null || !_fileUploaded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please complete all fields and upload an Excel file.')),
//       );
//       return;
//     }

//     final now = DateTime.now();
//     final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

//     Map<String, dynamic> submission = {
//       'orgName': _orgName,
//       'orgType': _orgType,
//       'fileName': _uploadedFileName,
//       'submissionDate': formattedDate,
//       'totalEmissions': _totalEmissions,
//       'emissionLimit': _emissionLimit,
//       'approved': false,
//       'fine': null,
//     };

//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? submissions = prefs.getStringList('submissions') ?? [];
//     submissions.add(submission.toString());
//     await prefs.setStringList('submissions', submissions);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Data submitted successfully!')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Organization Page'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.info_outline),
//             onPressed: () {
//               // Implement your info action here
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 decoration: InputDecoration(
//                   labelText: 'Organization Name',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.business),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _orgName = value;
//                   });
//                 },
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 decoration: InputDecoration(
//                   labelText: 'Organization Type',
//                   border: OutlineInputBorder(),
//                 ),
//                 value: _orgType,
//                 items: _emissionLimits.keys.map((type) {
//                   return DropdownMenuItem(
//                     value: type,
//                     child: Text(type),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _orgType = value;
//                     _checkLimit();
//                   });
//                 },
//               ),
//               SizedBox(height: 16),
//               ElevatedButton.icon(
//                 onPressed: _pickFile,
//                 icon: Icon(Icons.upload_file),
//                 label: Text('Upload Excel'),
//               ),
//               SizedBox(height: 16),
//               _fileUploaded
//                   ? Text('File Uploaded: $_uploadedFileName', style: TextStyle(fontWeight: FontWeight.bold))
//                   : Text('No file uploaded yet.'),
//               SizedBox(height: 16),
//               ElevatedButton.icon(
//                 onPressed: _submitData,
//                 icon: Icon(Icons.check),
//                 label: Text('Submit'),
//               ),
//               SizedBox(height: 16),
//               if (_fileUploaded && _orgType != null)
//                 Text(
//                   _limitExceeded
//                       ? 'Emission Limit Exceeded! ($_totalEmissions out of $_emissionLimit)'
//                       : 'Emissions within Limit ($_totalEmissions out of $_emissionLimit)',
//                   style: TextStyle(
//                     color: _limitExceeded ? Colors.red : Colors.green,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               // Add the PieChart
//               if (_fileUploaded && _orgType != null) ...[
//                 SizedBox(height: 32),
//                 Text('Emissions Chart:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 SizedBox(height: 16),
//                 Container(
//                   height: 200, // Define a fixed height for the PieChart
//                   child: PieChart(
//                     PieChartData(
//                       sections: [
//                         PieChartSectionData(
//                           value: _totalEmissions,
//                           color: _limitExceeded ? Colors.red : Colors.green,
//                           title: '${_totalEmissions.toStringAsFixed(2)} tons',
//                         ),
//                         PieChartSectionData(
//                           value: _emissionLimit - _totalEmissions,
//                           color: Colors.grey,
//                           title: '${(_emissionLimit - _totalEmissions).toStringAsFixed(2)} tons left',
//                         ),
//                       ],
//                     ),
//                     swapAnimationDuration: Duration(milliseconds: 150),
//                     swapAnimationCurve: Curves.linear,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
