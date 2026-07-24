import 'safety_classifier.dart';

enum ChatRole { user, coach, system }

enum MessageStatus { sending, streaming, complete, failed, blocked }

/// Structured source reference attached to a coach answer.
class AnswerSource {
  const AnswerSource({required this.title, required this.source, this.date});

  final String title;
  final String source;
  final String? date;

  Map<String, dynamic> toJson() => {
    'title': title,
    'source': source,
    'date': date,
  };

  factory AnswerSource.fromJson(Map<String, dynamic> json) => AnswerSource(
    title: json['title'] as String,
    source: json['source'] as String,
    date: json['date'] as String?,
  );
}

/// A chat message. Coach answers carry the structured fields returned by the
/// backend (answer, explanation, next steps, limitations, sources,
/// confidence) so the UI can render them as distinct sections.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.complete,
    this.explanation,
    this.nextSteps = const [],
    this.limitations,
    this.sources = const [],
    this.confidence,
    this.safetyCategory,
    this.professionalReferral = false,
    this.isStub = false,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  // Structured coach-answer sections (master requirement §8).
  final String? explanation;
  final List<String> nextSteps;
  final String? limitations;
  final List<AnswerSource> sources;

  /// 'established' | 'general' | 'individual' | 'uncertain'
  final String? confidence;
  final SafetyCategory? safetyCategory;
  final bool professionalReferral;

  /// True only for development-stub responses; rendered with a visible
  /// "development stub" label and impossible in production builds.
  final bool isStub;

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    String? explanation,
    List<String>? nextSteps,
    String? limitations,
    List<AnswerSource>? sources,
    String? confidence,
    bool? professionalReferral,
  }) => ChatMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    createdAt: createdAt,
    status: status ?? this.status,
    explanation: explanation ?? this.explanation,
    nextSteps: nextSteps ?? this.nextSteps,
    limitations: limitations ?? this.limitations,
    sources: sources ?? this.sources,
    confidence: confidence ?? this.confidence,
    safetyCategory: safetyCategory,
    professionalReferral: professionalReferral ?? this.professionalReferral,
    isStub: isStub,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'explanation': explanation,
    'nextSteps': nextSteps,
    'limitations': limitations,
    'sources': sources.map((s) => s.toJson()).toList(),
    'confidence': confidence,
    'safetyCategory': safetyCategory?.name,
    'professionalReferral': professionalReferral,
    'isStub': isStub,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: ChatRole.values.byName(json['role'] as String),
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: MessageStatus.values.byName(
      json['status'] as String? ?? 'complete',
    ),
    explanation: json['explanation'] as String?,
    nextSteps: ((json['nextSteps'] as List?) ?? const []).cast<String>(),
    limitations: json['limitations'] as String?,
    sources: ((json['sources'] as List?) ?? const [])
        .map((s) => AnswerSource.fromJson((s as Map).cast<String, dynamic>()))
        .toList(),
    confidence: json['confidence'] as String?,
    safetyCategory: json['safetyCategory'] == null
        ? null
        : SafetyCategory.values.byName(json['safetyCategory'] as String),
    professionalReferral: json['professionalReferral'] as bool? ?? false,
    isStub: json['isStub'] as bool? ?? false,
  );
}
