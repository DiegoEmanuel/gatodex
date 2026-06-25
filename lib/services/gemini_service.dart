import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CatCardData {
  final String cardName;
  final String rarity;
  final String element;
  final int power;
  final int agility;
  final int charisma;
  final String ability;

  const CatCardData({
    required this.cardName,
    required this.rarity,
    required this.element,
    required this.power,
    required this.agility,
    required this.charisma,
    required this.ability,
  });

  factory CatCardData.fromJson(Map<String, dynamic> json) => CatCardData(
        cardName: json['cardName'] as String,
        rarity: json['rarity'] as String,
        element: json['element'] as String,
        power: (json['power'] as num).toInt(),
        agility: (json['agility'] as num).toInt(),
        charisma: (json['charisma'] as num).toInt(),
        ability: json['ability'] as String,
      );
}

class GeminiService {
  // ── Gemini (primário) ──────────────────────────────────────────────────────
  // Chaves injetadas em build/run via --dart-define (NUNCA hardcoded).
  // Ex: flutter run --dart-define=GEMINI_API_KEY=... --dart-define=GROQ_API_KEY=...
  static const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  // ── Groq (primário) ───────────────────────────────────────────────────────
  static const _groqKey = String.fromEnvironment('GROQ_API_KEY');
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static const _prompt = '''
Você é um gerador de cartas colecionáveis para o app Gatodex.

Analise a foto deste gato cuidadosamente (cor, pelagem, expressão, postura) e retorne um JSON com:
- cardName: nome criativo em português (2-3 palavras, como "Frajola da Praça" ou "Micio das Sombras")
- rarity: exatamente uma de [Comum, Raro, Épico, Lendário, Mítico] — gatos mais únicos/marcantes recebem raridade maior
- element: exatamente um de [Fogo, Gelo, Luz, Sombra, Natureza, Elétrico, Místico] — escolha baseado na aparência/personalidade
- power: inteiro 1-100 (aspecto imponente/força)
- agility: inteiro 1-100 (aparência ágil/velocidade)
- charisma: inteiro 1-100 (expressividade/simpatia do gato)
- ability: nome de habilidade especial em português (2-4 palavras, como "Miado Fantasma" ou "Garras do Relâmpago")

Responda SOMENTE com o JSON válido, sem markdown, sem explicação, sem blocos de código.
''';

  Future<CatCardData> analyzePhoto(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      return await _callGroq(base64Image);
    } catch (e) {
      debugPrint('[AiCard] Groq falhou ($e) — tentando Gemini...');
      return await _callGemini(base64Image);
    }
  }

  // ── Gemini com 3 retries em 503 ───────────────────────────────────────────

  Future<CatCardData> _callGemini(String base64Image) async {
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {'response_mime_type': 'application/json'},
    });

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final response = await http
          .post(
            Uri.parse(_geminiUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-goog-api-key': _geminiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 503 && attempt < maxAttempts) {
        debugPrint('[Gemini] 503 — tentativa $attempt/$maxAttempts, aguardando ${attempt * 3}s');
        await Future.delayed(Duration(seconds: attempt * 3));
        continue;
      }

      if (response.statusCode != 200) {
        throw Exception('Gemini ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
      final clean = _stripFences(text);

      debugPrint('[Gemini] raw: $text');
      debugPrint('[Gemini] clean: $clean');

      return CatCardData.fromJson(jsonDecode(clean) as Map<String, dynamic>);
    }

    throw Exception('Gemini indisponível após $maxAttempts tentativas.');
  }

  // ── Groq fallback ─────────────────────────────────────────────────────────

  Future<CatCardData> _callGroq(String base64Image) async {
    final body = jsonEncode({
      'model': _groqModel,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            },
          ],
        },
      ],
    });

    final response = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Groq ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = decoded['choices'][0]['message']['content'] as String;
    final clean = _stripFences(text);

    debugPrint('[Groq] raw: $text');
    debugPrint('[Groq] clean: $clean');

    return CatCardData.fromJson(jsonDecode(clean) as Map<String, dynamic>);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _stripFences(String text) => text
      .replaceAll(RegExp(r'```json\s*'), '')
      .replaceAll(RegExp(r'```\s*'), '')
      .trim();
}
