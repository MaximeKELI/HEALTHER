import 'dart:convert';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

/// Écran de Vidéoconsultation / Télémédecine
class VideoConsultationScreen extends StatefulWidget {
  final int consultationId;
  final int doctorId;
  final int patientId;
  final String provider; // 'agora', 'twilio', 'jitsi'

  const VideoConsultationScreen({
    super.key,
    required this.consultationId,
    required this.doctorId,
    required this.patientId,
    this.provider = 'jitsi',
  });

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _sessionData;
  bool _isLoading = false;
  bool _isRecording = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = _apiService.getToken();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/video-consultation/session'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'consultationId': widget.consultationId,
          'doctorId': widget.doctorId,
          'patientId': widget.patientId,
          'provider': widget.provider,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sessionData = data['session'];
          _isLoading = false;
        });

        // Pour Jitsi, charger l'URL directement
        if (widget.provider == 'jitsi' && _sessionData!['roomUrl'] != null) {
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(_sessionData!['roomUrl']));
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur création session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      final token = _apiService.getToken();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/video-consultation/record'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'sessionId': _sessionData!['channelName'] ?? _sessionData!['roomName'],
          'metadata': {
            'consultationId': widget.consultationId,
            'doctorId': widget.doctorId,
            'patientId': widget.patientId,
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isRecording = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement démarré'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur enregistrement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vidéoconsultation'),
        actions: [
          if (_sessionData != null && !_isRecording)
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: _startRecording,
              tooltip: 'Démarrer enregistrement',
            ),
          if (_isRecording)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.fiber_manual_record, color: Colors.red),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessionData == null
              ? const Center(child: Text('Erreur de chargement'))
              : _buildVideoView(),
    );
  }

  Widget _buildVideoView() {
    switch (widget.provider) {
      case 'jitsi':
        return _buildJitsiView();
      case 'agora':
      case 'twilio':
        return _buildNativeView();
      default:
        return const Center(child: Text('Provider non supporté'));
    }
  }

  Widget _buildJitsiView() {
    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: WebViewWidget(controller: _webViewController!),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey.shade200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Information de Session',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Room: ${_sessionData!['roomName']}'),
              Text('Provider: ${_sessionData!['provider']}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNativeView() {
    // Pour Agora ou Twilio, utiliser les SDKs natifs
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Vidéoconsultation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Provider: ${widget.provider}'),
          const SizedBox(height: 32),
          const Text(
            'Intégration SDK native requise',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Intégrer SDK Agora ou Twilio
            },
            child: const Text('Démarrer la consultation'),
          ),
        ],
      ),
    );
  }
}

