import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/settings/models/lora.dart';
import '../../features/settings/models/sampler.dart';
import '../../features/settings/models/scheduler.dart';
import '../../features/settings/models/sd_model.dart';
import '../../features/settings/models/upscaler.dart';

class ForgeApiClient {
  final String baseUrl;
  final http.Client _client;

  ForgeApiClient({this.baseUrl = 'http://127.0.0.1:7860', http.Client? client})
    : _client = client ?? http.Client();

  Future<List<SDModel>> getSDModels() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sdapi/v1/sd-models'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SDModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Forge: $e');
    }
  }

  Future<List<Sampler>> getSamplers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sdapi/v1/samplers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Sampler.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load samplers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch samplers: $e');
    }
  }

  Future<List<Scheduler>> getSchedulers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sdapi/v1/schedulers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Scheduler.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load schedulers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch schedulers: $e');
    }
  }

  Future<List<Lora>> getLoras() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/sdapi/v1/loras'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Lora.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load loras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch loras: $e');
    }
  }

  Future<List<Upscaler>> getUpscalers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sdapi/v1/upscalers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Upscaler.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upscalers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch upscalers: $e');
    }
  }

  Future<void> setSDModel(String modelTitle) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/sdapi/v1/options'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sd_model_checkpoint': modelTitle}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set model: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> txt2img(Map<String, dynamic> params) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/sdapi/v1/txt2img'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(params),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate image: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getProgress() async {
    final response = await _client.get(Uri.parse('$baseUrl/sdapi/v1/progress'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get progress');
    }
  }

  Future<void> refreshSDModels() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/sdapi/v1/refresh-checkpoints'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to refresh models: ${response.statusCode}');
    }
  }

  Future<void> refreshLoras() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/sdapi/v1/refresh-loras'),
    );
    if (response.statusCode != 200) {
      // Some versions might not have this endpoint, but we should at least try.
      throw Exception('Failed to refresh loras: ${response.statusCode}');
    }
  }
}
