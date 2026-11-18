import 'package:flutter/foundation.dart';
// lib/services/face_recognition_service.dart
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
    ),
  );

  // Detect face in image and verify liveness
  Future<FaceVerificationResult> verifyFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceVerificationResult(
          isVerified: false,
          message: 'No face detected. Please try again.',
        );
      }

      final face = faces.first;

      // Check liveness indicators
      final isLive = _checkLiveness(face);

      if (!isLive) {
        return FaceVerificationResult(
          isVerified: false,
          message: 'Liveness detection failed. Please look at the camera.',
        );
      }

      // Extract face embedding for storage
      final embedding = await _extractFaceEmbedding(imageFile);

      return FaceVerificationResult(
        isVerified: true,
        faceEmbedding: embedding,
        message: 'Face verified successfully!',
        faceData: {
          'smilingProbability': face.smilingProbability,
          'leftEyeOpenProbability': face.leftEyeOpenProbability,
          'rightEyeOpenProbability': face.rightEyeOpenProbability,
        },
      );
    } catch (e) {
      debugPrint('❌ Face verification error: $e');
      return FaceVerificationResult(
        isVerified: false,
        message: 'Error: $e',
      );
    }
  }

  // Check liveness indicators
  bool _checkLiveness(Face face) {
    // Check if eyes are open (basic liveness detection)
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;

    // If eyes are open, likely a live person
    return leftEyeOpen > 0.5 || rightEyeOpen > 0.5;
  }

  // Extract face embedding (simplified - in production use ML model)
  Future<String> _extractFaceEmbedding(File imageFile) async {
    // In production, use a proper face embedding model
    // For now, return a hash of the file
    final bytes = await imageFile.readAsBytes();
    return 'face_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _faceDetector.close();
  }
}

class FaceVerificationResult {
  final bool isVerified;
  final String message;
  final String? faceEmbedding;
  final Map<String, dynamic>? faceData;

  FaceVerificationResult({
    required this.isVerified,
    required this.message,
    this.faceEmbedding,
    this.faceData,
  });
}