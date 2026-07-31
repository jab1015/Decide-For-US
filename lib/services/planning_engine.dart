import '../models/planning_engine_request.dart';
import '../models/planning_response.dart';
import 'ai_service.dart';

abstract interface class PlanningEngine {
  Future<PlanningResponse> createPlan(PlanningEngineRequest request);
}

class DefaultPlanningEngine implements PlanningEngine {
  const DefaultPlanningEngine();

  @override
  Future<PlanningResponse> createPlan(PlanningEngineRequest request) async {
    final activities = await AIService.getIdeas(
      request.toRecommendationRequest(),
    );
    return PlanningResponse.fromActivities(
      mode: request.mode,
      activities: activities,
    );
  }
}
