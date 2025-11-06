# 📋 GUIDE : Module Gestion des Dépenses dans Activités Physiques

## 🎯 Comment Accéder au Module

### Étape 1 : Naviguer vers les Activités Physiques
1. Depuis l'écran d'accueil, cliquez sur **"Explorer mes activités"**
2. Vous arrivez à la page **Activités Physiques** avec une barre de navigation en bas

### Étape 2 : Accéder au Module Dépenses
Dans la barre de navigation en bas, vous verrez 6 onglets :
- 🏋️ **Exercices** (index 0)
- ⏱️ **Sessions** (index 1)
- 📈 **Progression** (index 2)
- 📅 **Programmes** (index 3)
- 💡 **Conseils** (index 4)
- 💰 **Dépenses** (index 5) ← **NOUVEAU**

Cliquez sur l'onglet **"Dépenses"** avec l'icône 💰

## 📱 Écran du Module Dépenses

Une fois dans le module, vous verrez **3 cartes de navigation** :

### 1️⃣ **Nouveau Plan**
- **Icône** : ➕
- **Couleur** : Bleu
- **Fonction** : Créer un nouveau plan d'entraînement avec budgets
- **Destination** : Écran `UserInfoScreen`

### 2️⃣ **Plans Sauvegardés**
- **Icône** : 📜
- **Couleur** : Vert
- **Fonction** : Consulter tous vos plans précédents
- **Destination** : Écran `SavedPlansScreen`

### 3️⃣ **Historique des Dépenses**
- **Icône** : 🧾
- **Couleur** : Orange
- **Fonction** : Voir toutes les dépenses enregistrées
- **Destination** : Écran `ExpensesHistoryScreen`

## 🔄 Flux de Naviguation

```
Activités Physiques
    ↓
Clic sur "Dépenses" (onglet)
    ↓
Module Dépenses (ExpensesModuleScreen)
    ↓
    ├─ Nouveau Plan → UserInfoScreen → TrainingPlanScreen → ResultsScreen
    ├─ Plans Sauvegardés → SavedPlansScreen
    └─ Historique Dépenses → ExpensesHistoryScreen
```

## 📝 Fichiers Modifiés/Créés

### ✅ Créés
- `lib/Screens/expenses_module_screen.dart` - Panneau principal avec 3 cartes

### ✅ Modifiés
- `lib/Screens/physical_activities_main_screen.dart`
  - Ajout import : `expenses_module_screen.dart`
  - Ajout écran dans la liste `_screens`
  - Ajout bouton navigation "Dépenses" avec couleur rouge

## 💡 Points Importants

✅ **Aucune modification à la logique existante**
✅ **Utilise les écrans déjà présents** (UserInfoScreen, SavedPlansScreen, ExpensesHistoryScreen)
✅ **Intégration simple** via cartes cliquables
✅ **Navigation cohérente** avec le reste de l'application

---

**Créé le**: 6 novembre 2025
