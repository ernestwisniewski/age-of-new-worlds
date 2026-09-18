import '../../../l10n/l10n.dart';
import '../read_model/production_ranking_view.dart';
import '../read_model/production_view.dart';

enum ProductionBuildingSort {
  recommended,
  fastestImpact,
  bestReturn,
  growth,
  industry,
  science,
  defenseMilitary,
  economy;

  String label(AonwLocalizations l10n) => switch (this) {
    recommended => l10n.cityBuildingSortRecommended,
    fastestImpact => l10n.cityBuildingSortFastestImpact,
    bestReturn => l10n.cityBuildingSortBestReturn,
    growth => l10n.cityBuildingSortGrowth,
    industry => l10n.cityBuildingSortIndustry,
    science => l10n.cityBuildingSortScience,
    defenseMilitary => l10n.cityBuildingSortDefenseMilitary,
    economy => l10n.cityBuildingSortEconomy,
  };

  int _priority(ProductionBuildingRankView rank) => switch (this) {
    recommended => rank.recommended,
    fastestImpact => -rank.turnsForScore,
    bestReturn => rank.bestReturn,
    growth => rank.growth,
    industry => rank.industry,
    science => rank.science,
    defenseMilitary => rank.defenseMilitary,
    economy => rank.economy,
  };

  List<ProductionOptionView> order(
    List<ProductionOptionView> options,
    List<ProductionBuildingRankView> ranks,
    String Function(ProductionTargetView) title,
  ) {
    if (ranks.isEmpty) return options;
    final byBuilding = {for (final rank in ranks) rank.building: rank};
    ProductionBuildingRankView rankFor(ProductionOptionView option) =>
        byBuilding[(option.target as BuildingProductionTargetView).building]!;
    return [...options]..sort((left, right) {
      final a = rankFor(left);
      final b = rankFor(right);
      final priority = _priority(b).compareTo(_priority(a));
      if (priority != 0) return priority;
      final turns = a.turnsForScore.compareTo(b.turnsForScore);
      return turns != 0
          ? turns
          : title(left.target).compareTo(title(right.target));
    });
  }
}
