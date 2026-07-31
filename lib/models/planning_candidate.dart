import 'activity.dart';

enum CandidateKind {
  place('place'),
  event('event');

  const CandidateKind(this.wireName);
  final String wireName;

  static CandidateKind fromWireName(String? value) {
    return CandidateKind.values.firstWhere(
      (kind) => kind.wireName == value,
      orElse: () => CandidateKind.place,
    );
  }
}

enum CandidateSource {
  googlePlaces('google_places'),
  ticketmaster('ticketmaster'),
  unknown('unknown');

  const CandidateSource(this.wireName);
  final String wireName;

  static CandidateSource fromWireName(String? value) {
    final normalized = value?.toLowerCase().replaceAll(' ', '_');
    return CandidateSource.values.firstWhere(
      (source) => source.wireName == normalized,
      orElse: () => CandidateSource.unknown,
    );
  }
}

class PlanningCandidate {
  const PlanningCandidate({
    required this.activity,
    required this.kind,
    required this.source,
    required this.providerId,
    this.isVerified = true,
    this.sourceUrl,
  });

  final Activity activity;
  final CandidateKind kind;
  final CandidateSource source;
  final String providerId;
  final bool isVerified;
  final String? sourceUrl;

  factory PlanningCandidate.fromActivity(Activity activity) {
    final isEvent = activity.eventUrl?.isNotEmpty == true ||
        activity.eventStart != null ||
        activity.source?.toLowerCase() == 'ticketmaster';
    final source = isEvent
        ? CandidateSource.ticketmaster
        : activity.source?.isNotEmpty == true
            ? CandidateSource.fromWireName(activity.source)
            : CandidateSource.googlePlaces;

    return PlanningCandidate(
      activity: activity,
      kind: isEvent ? CandidateKind.event : CandidateKind.place,
      source: source,
      providerId: activity.id,
      sourceUrl: activity.eventUrl,
    );
  }

  factory PlanningCandidate.fromJson(Map<String, dynamic> json) {
    final activityJson = json['activity'];
    return PlanningCandidate(
      activity: Activity.fromJson(
        activityJson is Map
            ? Map<String, dynamic>.from(activityJson)
            : const <String, dynamic>{},
      ),
      kind: CandidateKind.fromWireName(json['kind']?.toString()),
      source: CandidateSource.fromWireName(json['source']?.toString()),
      providerId: json['providerId']?.toString() ?? '',
      isVerified: json['isVerified'] != false,
      sourceUrl: json['sourceUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'activity': activity.toJson(),
        'kind': kind.wireName,
        'source': source.wireName,
        'providerId': providerId,
        'isVerified': isVerified,
        'sourceUrl': sourceUrl,
      };
}
