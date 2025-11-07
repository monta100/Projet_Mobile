import '../models/health_record.dart';

class Point {final num x; final num y; const Point(this.x, this.y);} 

class StatsUtils {
  static List<Point> seriesFor(HealthMetricType t, List<HealthRecord> rs) {
    rs.sort((a,b) => a.dateTime.compareTo(b.dateTime));
    switch (t) {
      case HealthMetricType.bloodPressure:
        return [
          for (int i=0;i<rs.length;i++) Point(i, rs[i].values['systolic'] ?? 0),
        ];
      case HealthMetricType.glucose:
        return [for (int i=0;i<rs.length;i++) Point(i, rs[i].values['value'] ?? 0)];
      case HealthMetricType.sleep:
        return [for (int i=0;i<rs.length;i++) Point(i, rs[i].values['hours'] ?? 0)];
      case HealthMetricType.weight:
        return [for (int i=0;i<rs.length;i++) Point(i, rs[i].values['kg'] ?? 0)];
      case HealthMetricType.heartRate:
        return [for (int i=0;i<rs.length;i++) Point(i, rs[i].values['bpm'] ?? 0)];
      case HealthMetricType.custom:
        return [for (int i=0;i<rs.length;i++) Point(i, rs[i].values['value'] ?? 0)];
    }
  }

  static num avg(List<Point> pts) => pts.isEmpty ? 0 : pts.map((e)=>e.y).reduce((a,b)=>a+b)/pts.length;
  static num max(List<Point> pts) => pts.isEmpty ? 0 : pts.map((e)=>e.y).reduce((a,b)=>a>b?a:b);
  static num min(List<Point> pts) => pts.isEmpty ? 0 : pts.map((e)=>e.y).reduce((a,b)=>a<b?a:b);
}