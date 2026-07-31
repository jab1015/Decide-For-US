import '../models/planning_candidate.dart';
import '../models/planning_engine_request.dart';
import 'ai_service.dart';
import 'candidate_provider.dart';

class RecommendationCandidateProvider implements CandidateProvider {
  const RecommendationCandidateProvider();

  @override
  String get id => 'recommendations';

  @override
  Future<List<PlanningCandidate>> fetch(PlanningEngineRequest request) async {
    final activities = await AIService.getIdeas(
      request.toRecommendationRequest(),
    );
    return activities.map(PlanningCandidate.fromActivity).toList();
  }
}
