import '../../map/read_model/map_feedback_view.dart';
import 'research_view.dart';

final class ResearchDiscoveryView {
  const ResearchDiscoveryView({
    required this.identity,
    required this.technology,
  });

  final MapEventIdentityView identity;
  final TechnologyIdView technology;
}
