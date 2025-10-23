# ⚡ Quick Start - Tests

## 🚀 Lancer les Tests en 30 Secondes

```bash
# Tout exécuter
flutter test

# Avec couverture
flutter test --coverage
```

## 📁 Fichiers Créés

```
test/
├── black_box/                                    46 tests
│   └── expense_management_acceptance_test.dart  (Specs)
│
└── white_box/                                    73 tests
    ├── gemini_ai_service_unit_test.dart         (Code)
    ├── expense_screen_integration_test.dart     (Code)
    └── local_storage_service_unit_test.dart     (Code)

TOTAL : 119 TESTS
```

## 🎯 Les Deux Approches

### 🖤 Black Box = Tests sans voir le code
- **Source** : Documentation
- **Tests** : Acceptation, Fonctionnels
- **Vérifie** : "Est-ce que ça marche ?"

### ⚪ White Box = Tests en analysant le code
- **Source** : Code source
- **Tests** : Unitaires, Intégration
- **Vérifie** : "Comment ça marche ?"

## 📚 Documentation

| Fichier | Pour Qui ? |
|---------|------------|
| `README_TESTS.md` | 🟢 Débutant - Commencez ici |
| `SCHEMAS_BLACK_BOX_VS_WHITE_BOX.md` | 🟡 Visuel - Schémas |
| `RESUME_IMPLEMENTATION_TESTS.md` | 🟠 Résumé complet |
| `GUIDE_TESTS_BLACK_BOX_WHITE_BOX.md` | 🔴 Guide détaillé (400+ lignes) |

## ✅ Ce Qui Est Testé

- ✅ Gestion des dépenses (création, calcul, sauvegarde)
- ✅ Recommandations IA (génération, affichage, matching)
- ✅ Stockage local (CRUD, JSON, persistance)
- ✅ Navigation (entre écrans, dialogues)
- ✅ Gestion d'erreurs
- ✅ Performance
- ✅ Sécurité

## 🎊 Résultat

**119 tests garantissent la qualité de votre application !**

🖤 Black Box (46) + ⚪ White Box (73) = 💚 **Qualité**

---

**Lancez `flutter test` maintenant !** 🚀

