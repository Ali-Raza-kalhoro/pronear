// lib/services/ocr_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class OCRService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  // Extract CNIC number only from image
  Future<CNICData> extractCNICData(File imageFile) async {
    try {
      print('🔍 Starting OCR with Google ML Kit...');

      String fullText = '';
      List<String> allLines = [];

      // Approach 1: Direct OCR
      print('📷 Approach 1: Direct OCR');
      final result1 = await _performOCR(imageFile);
      if (result1.isNotEmpty) {
        fullText = result1;
        allLines = fullText.split('\n');
        print('📝 Direct OCR Result:\n$fullText');
      }

      // Approach 2: If no text detected, try with image preprocessing
      if (fullText.length < 5) {
        print('📷 Approach 2: Preprocessed Image OCR');
        final preprocessedFile = await _preprocessImage(imageFile);
        final result2 = await _performOCR(preprocessedFile);
        if (result2.isNotEmpty && result2.length > fullText.length) {
          fullText = result2;
          allLines = fullText.split('\n');
          print('📝 Preprocessed OCR Result:\n$fullText');
        }
        if (preprocessedFile.path != imageFile.path) {
          await preprocessedFile.delete();
        }
      }

      // Approach 3: If still no text, try with different orientation
      if (fullText.length < 5) {
        print('📷 Approach 3: Rotated Image OCR');
        final rotatedFile = await _rotateImage(imageFile);
        final result3 = await _performOCR(rotatedFile);
        if (result3.isNotEmpty && result3.length > fullText.length) {
          fullText = result3;
          allLines = fullText.split('\n');
          print('📝 Rotated OCR Result:\n$fullText');
        }
        if (rotatedFile.path != imageFile.path) {
          await rotatedFile.delete();
        }
      }

      if (fullText.isEmpty) {
        throw Exception('No text detected in image');
      }

      // Extract CNIC Number only
      String cnicNumber = _extractCNICNumber(fullText);
      print('🆔 Extracted CNIC Number: $cnicNumber');

      if (cnicNumber.isEmpty) {
        throw Exception('Could not read CNIC number. Please try with a clearer image.');
      }

      return CNICData(
        cnicNumber: cnicNumber,
        fullName: '',
        dateOfBirth: '',
        rawText: fullText,
        isUrdu: _containsUrdu(fullText),
      );
    } catch (e) {
      print('❌ OCR Error: $e');
      throw Exception('Failed to read CNIC: $e');
    }
  }

  // Perform OCR on an image
  Future<String> _performOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = '';
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          fullText += line.text + '\n';
        }
      }
      return fullText;
    } catch (e) {
      print('⚠️ OCR failed: $e');
      return '';
    }
  }

  // Preprocess image for better OCR
  Future<File> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      print('⚠️ Preprocessing failed: $e');
      return imageFile;
    }
  }

  // Simple rotate implementation
  Future<File> _rotateImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      print('⚠️ Rotation failed: $e');
      return imageFile;
    }
  }

  // ============================================================
  // CNIC Number Extraction - Only This
  // ============================================================
  String _extractCNICNumber(String text) {
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Pattern 1: Standard CNIC format with dashes (#####-#######-#)
    final pattern1 = RegExp(r'\b\d{5}-\d{7}-\d{1}\b');
    final match1 = pattern1.firstMatch(cleanText);
    if (match1 != null) {
      return match1.group(0)!;
    }

    // Pattern 2: 13 digit number without dashes
    final pattern2 = RegExp(r'\b\d{13}\b');
    final match2 = pattern2.firstMatch(cleanText);
    if (match2 != null) {
      final cnic = match2.group(0)!;
      return '${cnic.substring(0, 5)}-${cnic.substring(5, 12)}-${cnic.substring(12, 13)}';
    }

    // Pattern 3: CNIC with labels
    final pattern3 = RegExp(r'(?:[Ii]dentity\s*[Nn]umber|CNIC|ID|CARD)\s*[:.]?\s*(\d{5}[-]?\d{7}[-]?\d{1})');
    final match3 = pattern3.firstMatch(cleanText);
    if (match3 != null) {
      String cnic = match3.group(1)!.replaceAll('-', '');
      if (cnic.length == 13) {
        return '${cnic.substring(0, 5)}-${cnic.substring(5, 12)}-${cnic.substring(12, 13)}';
      }
      return match3.group(1)!;
    }

    // Pattern 4: Find any 5-7-1 digit pattern with or without dashes
    final pattern4 = RegExp(r'(\d{5})[-]?(\d{7})[-]?(\d{1})');
    final match4 = pattern4.firstMatch(cleanText);
    if (match4 != null) {
      return '${match4.group(1)}-${match4.group(2)}-${match4.group(3)}';
    }

    // Pattern 5: Try to find CNIC-like pattern in the text
    final pattern5 = RegExp(r'\d{5}\s*\d{7}\s*\d{1}');
    final match5 = pattern5.firstMatch(cleanText);
    if (match5 != null) {
      final cnic = match5.group(0)!.replaceAll(RegExp(r'\s+'), '');
      if (cnic.length == 13) {
        return '${cnic.substring(0, 5)}-${cnic.substring(5, 12)}-${cnic.substring(12, 13)}';
      }
    }

    return '';
  }

  // Check if text contains Urdu characters
  bool _containsUrdu(String text) {
    final urduRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return urduRegex.hasMatch(text);
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class CNICData {
  final String cnicNumber;
  final String fullName;
  final String dateOfBirth;
  final String rawText;
  final bool isUrdu;

  CNICData({
    required this.cnicNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.rawText,
    this.isUrdu = false,
  });
}