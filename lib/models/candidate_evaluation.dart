import 'planning_candidate.dart';

class CandidateEvaluation {
  const CandidateEvaluation({
    required this.candidate,
    required this.eligible,
    required this.score,
    this.rejectionReasons = const [],
    this.scoreReasons = const [],
  });

  final PlanningCandidate candidate;
  final bool eligible;
  final double score;
  final List<String> rejectionReasons;
  final List<String> scoreReasons;
}
