/// Entité représentant une dépense liée à un plan d'entraînement
class Expense {
  final int? id;
  final int? planId;
  final double gymSubscription;
  final double foodCosts;
  final double? supplementsCosts;
  final double? equipmentCosts;
  final double? otherCosts;
  final double totalCost;

  Expense({
    this.id,
    this.planId,
    required this.gymSubscription,
    required this.foodCosts,
    this.supplementsCosts,
    this.equipmentCosts,
    this.otherCosts,
    required this.totalCost,
  });

  /// Convertit l'objet Expense en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'gym_subscription': gymSubscription,
      'food_costs': foodCosts,
      'supplements_costs': supplementsCosts,
      'equipment_costs': equipmentCosts,
      'other_costs': otherCosts,
      'total_cost': totalCost,
    };
  }

  /// Crée un objet Expense à partir d'une Map de la base de données
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      planId: map['plan_id'] as int?,
      gymSubscription: (map['gym_subscription'] as num).toDouble(),
      foodCosts: (map['food_costs'] as num).toDouble(),
      supplementsCosts: map['supplements_costs'] != null 
          ? (map['supplements_costs'] as num).toDouble() 
          : null,
      equipmentCosts: map['equipment_costs'] != null 
          ? (map['equipment_costs'] as num).toDouble() 
          : null,
      otherCosts: map['other_costs'] != null 
          ? (map['other_costs'] as num).toDouble() 
          : null,
      totalCost: (map['total_cost'] as num).toDouble(),
    );
  }

  /// Crée une copie de l'objet Expense avec des modifications
  Expense copyWith({
    int? id,
    int? planId,
    double? gymSubscription,
    double? foodCosts,
    double? supplementsCosts,
    double? equipmentCosts,
    double? otherCosts,
    double? totalCost,
  }) {
    return Expense(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      gymSubscription: gymSubscription ?? this.gymSubscription,
      foodCosts: foodCosts ?? this.foodCosts,
      supplementsCosts: supplementsCosts ?? this.supplementsCosts,
      equipmentCosts: equipmentCosts ?? this.equipmentCosts,
      otherCosts: otherCosts ?? this.otherCosts,
      totalCost: totalCost ?? this.totalCost,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, planId: $planId, gymSubscription: $gymSubscription, '
           'foodCosts: $foodCosts, supplementsCosts: $supplementsCosts, '
           'equipmentCosts: $equipmentCosts, otherCosts: $otherCosts, '
           'totalCost: $totalCost)';
  }
}

