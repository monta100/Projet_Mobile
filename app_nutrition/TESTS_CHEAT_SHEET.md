# ⚡ Tests - Cheat Sheet

## 🚀 Commandes Essentielles

```bash
flutter test                              # Tous les tests
flutter test --coverage                    # Avec couverture
flutter test test/black_box/              # Black Box uniquement
flutter test test/white_box/              # White Box uniquement
```

## 📂 Structure

```
test/
├── black_box/                            # 46 tests (Specs)
│   └── expense_management_acceptance_test.dart
└── white_box/                            # 73 tests (Code)
    ├── gemini_ai_service_unit_test.dart
    ├── expense_screen_integration_test.dart
    └── local_storage_service_unit_test.dart
```

## 🎯 Deux Approches

| Black Box 🖤 | White Box ⚪ |
|--------------|--------------|
| Sans voir le code | En analysant le code |
| Specs/Docs | Code source |
| Perspective USER | Perspective DEV |
| 46 tests | 73 tests |

## 📚 Documentation

| Niveau | Fichier |
|--------|---------|
| 🟢 Quick | `TESTS_QUICK_START.md` |
| 🟢 Start | `README_TESTS.md` |
| 🟡 Visual | `SCHEMAS_BLACK_BOX_VS_WHITE_BOX.md` |
| 🟠 Summary | `RESUME_IMPLEMENTATION_TESTS.md` |
| 🔴 Complete | `GUIDE_TESTS_BLACK_BOX_WHITE_BOX.md` |
| 📑 Index | `INDEX_FICHIERS_TESTS.md` |

## ✅ Tests Créés

- ✅ **119 tests** au total
- ✅ Gestion des dépenses
- ✅ Recommandations IA
- ✅ Stockage local
- ✅ Navigation
- ✅ Performance
- ✅ Sécurité

## 🎯 Nomenclature

### Black Box
```
ACCEPTANCE-001  # Tests d'acceptation
FUNCTIONAL-001  # Tests fonctionnels
UI-001         # Tests d'interface
DATA-001       # Tests de données
NAV-001        # Tests de navigation
```

### White Box
```
UNIT-001           # Tests unitaires
INTEGRATION-001    # Tests d'intégration
COVERAGE-001      # Tests de couverture
PERF-001          # Tests de performance
SEC-001           # Tests de sécurité
```

## 📊 Stats Rapides

| Métrique | Valeur |
|----------|--------|
| Tests | 119 |
| Black Box | 46 (39%) |
| White Box | 73 (61%) |
| Fichiers | 4 |
| Docs | 6 |

## 🔍 Trouver un Test

| Fonctionnalité | Fichier |
|----------------|---------|
| Plans | `expense_management_acceptance_test.dart` |
| IA | `gemini_ai_service_unit_test.dart` |
| Storage | `local_storage_service_unit_test.dart` |
| Écran | `expense_screen_integration_test.dart` |

---

**💚 119 tests = Qualité assurée !**

