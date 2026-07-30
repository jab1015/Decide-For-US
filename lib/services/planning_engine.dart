import '../models/planning_mode.dart';
import '../models/planning_request.dart';
import '../models/planning_response.dart';
import 'ai_service.dart';

abstract interface class PlanningEngine {
  Future<PlanningResponse> createPlan(PlanningRequest request);
}

class DefaultPlanningEngine implements PlanningEngine {
  const DefaultPlanningEngine();

  @override
  Future<PlanningResponse> createPlan(PlanningRequest request) async {
    final activities = await AIService.getIdeas(request);
    return PlanningResponse.fromActivities(
      mode: request.isDateNight
          ? PlanningMode.dateNight
          : PlanningMode.quickDecision,
      activities: activities,
    );
  }
}
