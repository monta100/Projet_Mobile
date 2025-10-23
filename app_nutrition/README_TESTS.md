# 🧪 Tests - Application Nutrition

## 📚 Bienvenue dans la Suite de Tests

Ce dossier contient tous les tests de l'application nutrition, implémentés selon **deux approches complémentaires** :

- 🖤 **Black Box** : Tests basés sur les spécifications
- ⚪ **White Box** : Tests basés sur le code source

---

## 🚀 Démarrage Rapide

### Exécuter Tous les Tests

```bash
flutter test
```

### Exécuter par Catégorie

```bash
# Tests Black Box (Acceptation)
flutter test test/black_box/

# Tests White Box (Unitaires/Intégration)
flutter test test/white_box/
```

### Générer la Couverture

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📂 Structure des Fichiers

```
test/
├── black_box/                              # Tests Black Box
│   └── expense_management_acceptance_test.dart
│       └── 46 tests d'acceptation
│
└── white_box/                              # Tests White Box
    ├── gemini_ai_service_unit_test.dart
    │   └── 31 tests unitaires
    ├── expense_screen_integration_test.dart
    │   └── 26 tests d'intégration
    └── local_storage_service_unit_test.dart
        └── 16 tests unitaires

TOTAL : 119 tests
```

---

## 📖 Documentation

### Guides Principaux

| Fichier | Description |
|---------|-------------|
| `GUIDE_TESTS_BLACK_BOX_WHITE_BOX.md` | Guide complet (400+ lignes) |
| `RESUME_IMPLEMENTATION_TESTS.md` | Résumé rapide |
| `SCHEMAS_BLACK_BOX_VS_WHITE_BOX.md` | Schémas visuels |
| `README_TESTS.md` | Ce fichier |

### Lecture Recommandée

1. **Débutant** : Commencez par `SCHEMAS_BLACK_BOX_VS_WHITE_BOX.md`
2. **Intermédiaire** : Lisez `RESUME_IMPLEMENTATION_TESTS.md`
3. **Avancé** : Consultez `GUIDE_TESTS_BLACK_BOX_WHITE_BOX.md`

---

## 🎯 Les Deux Approches

### 🖤 Black Box (Boîte Noire)

**Principe** : Tester sans regarder le code, uniquement les spécifications

```dart
// Exemple
testWidgets('L\'utilisateur peut créer un plan', (tester) async {
  // SOURCE: Documentation utilisateur
  // TEST: Comportement visible
  await tester.tap(find.text('Nouveau plan'));
  expect(find.text('Formulaire'), findsOneWidget);
});
```

**Fichiers** :
- `test/black_box/expense_management_acceptance_test.dart`

**46 tests** couvrant :
- ✅ Tests d'acceptation (5)
- ✅ Tests fonctionnels (3)
- ✅ Tests de navigation (2)
- ✅ Tests de données (2)
- ✅ Tests d'interface (3)

### ⚪ White Box (Boîte Blanche)

**Principe** : Tester en analysant le code source

```dart
// Exemple
test('addPlan() encode en JSON', () async {
  // SOURCE: Analyse du code (lignes 45-52)
  // TEST: Logique interne
  await service.addPlan({'weeks': 8});
  final json = prefs.getString('plans');
  expect(json, contains('weeks'));
});
```

**Fichiers** :
- `test/white_box/gemini_ai_service_unit_test.dart`
- `test/white_box/expense_screen_integration_test.dart`
- `test/white_box/local_storage_service_unit_test.dart`

**73 tests** couvrant :
- ✅ Tests unitaires (47)
- ✅ Tests d'intégration (26)
- ✅ Tests de performance (4)
- ✅ Tests de sécurité (2)

---

## 📊 Statistiques

| Métrique | Valeur |
|----------|--------|
| **Total de tests** | 119 |
| **Tests Black Box** | 46 (39%) |
| **Tests White Box** | 73 (61%) |
| **Fichiers de test** | 4 |
| **Lignes de code** | ~1200 |
| **Couverture visée** | 80% |

---

## 🔍 Trouver un Test Spécifique

### Par Fonctionnalité

| Fonctionnalité | Fichier de Test |
|----------------|-----------------|
| **Création de plan** | `black_box/expense_management_acceptance_test.dart` |
| **Recommandations IA** | `black_box/expense_management_acceptance_test.dart` <br> `white_box/gemini_ai_service_unit_test.dart` |
| **Sauvegarde de plan** | `white_box/local_storage_service_unit_test.dart` |
| **Navigation** | `white_box/expense_screen_integration_test.dart` |

### Par Code à Tester

| Code Source | Test White Box |
|-------------|----------------|
| `Services/gemini_ai_service.dart` | `white_box/gemini_ai_service_unit_test.dart` |
| `Services/local_storage_service.dart` | `white_box/local_storage_service_unit_test.dart` |
| `Screens/expense_screen.dart` | `white_box/expense_screen_integration_test.dart` |

---

## 🛠️ Commandes Utiles

### Exécution

```bash
# Test spécifique
flutter test test/white_box/gemini_ai_service_unit_test.dart

# Avec mode verbose
flutter test --reporter expanded

# Avec surveillance continue
flutter test --watch
```

### Couverture

```bash
# Générer la couverture
flutter test --coverage

# Voir le rapport
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Couverture d'un fichier spécifique
flutter test --coverage test/white_box/
```

### Débogage

```bash
# Avec print détaillés
flutter test --verbose-trace

# Un seul test
flutter test --plain-name "UNIT-001"

# Avec debugger
flutter test --start-paused
```

---

## 📝 Écrire de Nouveaux Tests

### Black Box Test

```dart
testWidgets('ACCEPTANCE-XXX: Description de l\'exigence', 
  (WidgetTester tester) async {
  // SOURCE: Référence documentation (ex: GUIDE_X.md)
  // SPEC: Exigence utilisateur claire
  
  // Arrange
  await tester.pumpWidget(const MyApp());
  
  // Act
  await tester.tap(find.text('Bouton'));
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Résultat Attendu'), findsOneWidget,
    reason: 'Message explicatif selon la spec');
});
```

### White Box Test

```dart
test('UNIT-XXX: Description de la logique testée', () async {
  // ANALYSE DU CODE (lignes X-Y):
  // [Extrait du code analysé]
  
  // Arrange
  final service = MyService();
  
  // Act
  final result = await service.myMethod();
  
  // Assert
  expect(result, expectedValue,
    reason: 'Explication basée sur l\'implémentation');
});
```

---

## ✅ Checklist Avant Commit

- [ ] Tous les tests passent : `flutter test`
- [ ] Couverture ≥ 80% : `flutter test --coverage`
- [ ] Pas de tests ignorés (skip)
- [ ] Documentation des tests mise à jour
- [ ] Nomenclature respectée (CATEGORY-NUMBER)

---

## 🐛 Résolution de Problèmes

### Tests qui échouent

```bash
# Voir les détails d'erreur
flutter test --reporter expanded

# Exécuter en mode debug
flutter test --start-paused

# Vérifier un test spécifique
flutter test --plain-name "UNIT-001"
```

### Problèmes de Couverture

```bash
# Nettoyer et regénérer
flutter clean
flutter test --coverage

# Vérifier les fichiers ignorés
cat coverage/lcov.info
```

### Problèmes de Performance

```bash
# Profiler les tests
flutter test --enable-observatory

# Tests en parallèle
flutter test --concurrency=4
```

---

## 📈 Évolution des Tests

### Prochain Ajouts Prévus

1. **Tests E2E** (Bout en bout)
   - Scénarios utilisateur complets
   - Tests sur vrais appareils

2. **Tests de Performance**
   - Temps de chargement
   - Consommation mémoire

3. **Tests d'Accessibilité**
   - Contraste des couleurs
   - Taille des textes

4. **Tests de Sécurité**
   - Injection de code
   - Failles XSS

---

## 🎓 Ressources d'Apprentissage

### Documentation Flutter
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)

### Nos Guides
- `GUIDE_TESTS_BLACK_BOX_WHITE_BOX.md` - Guide détaillé
- `SCHEMAS_BLACK_BOX_VS_WHITE_BOX.md` - Schémas visuels
- `RESUME_IMPLEMENTATION_TESTS.md` - Résumé rapide

---

## 🤝 Contribution

### Ajouter un Test

1. Identifier le type (Black Box ou White Box)
2. Choisir le fichier approprié
3. Suivre la nomenclature (CATEGORY-NUMBER)
4. Documenter la source (spec ou code)
5. Ajouter des raisons explicites

### Nomenclature

**Black Box** :
- `ACCEPTANCE-XXX` : Tests d'acceptation
- `FUNCTIONAL-XXX` : Tests fonctionnels
- `UI-XXX` : Tests d'interface
- `DATA-XXX` : Tests de données
- `NAV-XXX` : Tests de navigation

**White Box** :
- `UNIT-XXX` : Tests unitaires
- `INTEGRATION-XXX` : Tests d'intégration
- `COVERAGE-XXX` : Tests de couverture
- `PERF-XXX` : Tests de performance
- `SEC-XXX` : Tests de sécurité

---

## 📞 Support

### Questions ?

1. **Documentation** : Consultez `GUIDE_TESTS_BLACK_BOX_WHITE_BOX.md`
2. **Exemples** : Regardez les tests existants
3. **Schémas** : Voir `SCHEMAS_BLACK_BOX_VS_WHITE_BOX.md`

### Problèmes ?

1. Vérifier que tous les packages sont installés
2. Nettoyer le projet : `flutter clean`
3. Régénérer : `flutter pub get`
4. Relancer les tests : `flutter test`

---

## 🎉 Commencer Maintenant !

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Exécuter les tests
flutter test

# 3. Voir la couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 4. Admirer vos 119 tests qui passent ! 🎊
```

---

**Bonne chance avec vos tests !** 🚀

*119 tests vous attendent pour garantir la qualité de votre application.*

