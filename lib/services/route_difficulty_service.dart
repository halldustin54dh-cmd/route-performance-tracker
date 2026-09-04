import '../models/delivery_route.dart';

class RouteDifficulty {
  const RouteDifficulty({
    required this.score,
    required this.band,
    required this.dataCompleteness,
    required this.workload,
    required this.complexityTravel,
    required this.context,
  });

  final double score;
  final String band;
  final double dataCompleteness;
  final double workload;
  final double complexityTravel;
  final double context;
}

class RouteDifficultyService {
  const RouteDifficultyService();

  RouteDifficulty? calculate(DeliveryRoute route) {
    if (route.startingStops <= 0 || route.startingLocations <= 0 || route.startingPackages <= 0) return null;

    final optionalValues = <num>[
      route.apartmentStops,
      route.businessStops,
      route.ruralStops,
      route.multiLocationStops,
      route.averageDriveMinutes,
      route.weatherSeverity,
      route.accessDifficulty,
      route.routeSpread,
    ];
    final suppliedContext = optionalValues.where((value) => value > 0).length;
    if (suppliedContext < 1) return null;

    final locationsPerStop = route.startingLocations / route.startingStops;
    final packagesPerStop = route.startingPackages / route.startingStops;
    final stops = route.startingStops.toDouble();

    double clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

    final workload =
        10 * clamp01(route.startingStops / 200) +
        7 * clamp01(packagesPerStop / 2.2) +
        8 * clamp01(locationsPerStop / 1.4);

    final complexityTravel =
        12 * clamp01((route.apartmentStops / stops) * 3) +
        8 * clamp01((route.businessStops / stops) * 4) +
        10 * clamp01((route.multiLocationStops / stops) * 3) +
        12 * clamp01((route.ruralStops / stops) * 4) +
        10 * clamp01(route.averageDriveMinutes / 3) +
        8 * clamp01(route.routeSpread / 5);

    final context =
        5 * clamp01(route.weatherSeverity / 5) +
        5 * clamp01(route.accessDifficulty / 5) +
        5 * clamp01(route.documentedDelayMinutes / 60);

    final score = (workload + complexityTravel + context).clamp(0.0, 100.0).toDouble();
    final band = score < 30
        ? 'Low'
        : score < 50
            ? 'Moderate'
            : score < 70
                ? 'High'
                : score < 85
                    ? 'Very High'
                    : 'Extreme';

    final completeness = ((3 + suppliedContext) / 11).clamp(0.0, 1.0).toDouble();
    return RouteDifficulty(
      score: score,
      band: band,
      dataCompleteness: completeness,
      workload: workload,
      complexityTravel: complexityTravel,
      context: context,
    );
  }
}
