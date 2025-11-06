# 📊 GUIDE : 2 Modules Indépendants de Gestion Financière

## 🎯 Accès aux Modules

### 📍 Localisation dans l'Application

Les 2 modules sont accessibles **directement depuis le Dashboard** (l'écran d'accueil). 

Vous verrez une nouvelle section appelée **"Gestion Financière"** avec 2 boutons cliquables :

```
┌─────────────────────────────────────────┐
│  Gestion Financière                      │
├─────────────────┬───────────────────────┤
│                 │                       │
│  📅             │  💰                   │
│  Plans &        │  Suivi                │
│  Budgets        │  Dépenses             │
│                 │                       │
└─────────────────┴───────────────────────┘
```

---

## 📋 Module 1 : Plans & Budgets

**Fichier** : `lib/Screens/training_expenses_module_screen.dart`

### 🎯 Objectif
Créer et gérer des plans d'entraînement personnalisés avec budgets associés.

### 📱 Écrans Accessibles

#### 1️⃣ **Nouveau Plan**
- **Icône** : ➕ (Plus)
- **Destination** : `UserInfoScreen`
- **Fonction** : 
  - Entrer vos informations personnelles (poids, taille, âge, etc.)
  - Créer un plan d'entraînement avec budgets
  - Recevoir des recommandations AI

#### 2️⃣ **Mes Plans Sauvegardés**
- **Icône** : 📜 (Histoire)
- **Destination** : `SavedPlansScreen`
- **Fonction** : 
  - Consulter tous vos plans précédents
  - Voir les coûts détaillés
  - Supprimer ou gérer les plans

### 💡 Flux d'Utilisation

```
Dashboard
    ↓
[Plans & Budgets] (bouton bleu)
    ↓
Deux options :
├─ [+ Nouveau Plan]
│  ├─ Remplir infos personnelles
│  ├─ Entrer durée d'entraînement
│  ├─ Entrer budget salle + nourriture
│  └─ Voir résumé des coûts
│
└─ [📜 Mes Plans]
   └─ Liste des plans précédents
```

---

## 💸 Module 2 : Suivi des Dépenses

**Fichier** : `lib/Screens/expenses_tracker_module_screen.dart`

### 🎯 Objectif
Suivre toutes vos dépenses d'entraînement et nutrition.

### 📱 Écrans Accessibles

#### 1️⃣ **Historique des Dépenses**
- **Icône** : 🧾 (Reçu)
- **Destination** : `ExpensesHistoryScreen`
- **Fonction** : 
  - Voir toutes les dépenses enregistrées
  - Filtrer par catégorie
  - Analyser vos dépenses

### 📂 Catégories de Dépenses Suivies

Le module affiche les 5 catégories de dépenses :

| Catégorie | Icône | Couleur |
|-----------|-------|--------|
| **Abonnement Salle** | 🏋️ | Bleu |
| **Nourriture & Nutrition** | 🍽️ | Vert |
| **Suppléments** | 🛍️ | Violet |
| **Équipement** | 🔧 | Rouge |
| **Autres Dépenses** | ➕ | Ambre |

### 💡 Flux d'Utilisation

```
Dashboard
    ↓
[Suivi Dépenses] (bouton orange)
    ↓
[Historique des Dépenses]
    ├─ Voir toutes les dépenses
    ├─ Consultez les catégories
    └─ Analysez vos dépenses
```

---

## 🔄 Navigation Complète

```
┌─ Dashboard (Accueil)
│
└─ Gestion Financière
   ├─ 📅 Plans & Budgets
   │  ├─ ➕ Nouveau Plan
   │  │  ├─ UserInfoScreen (infos perso)
   │  │  ├─ TrainingPlanScreen (plan)
   │  │  └─ ResultsScreen (résultats & AI)
   │  │
   │  └─ 📜 Mes Plans
   │     └─ SavedPlansScreen (liste plans)
   │
   └─ 💰 Suivi Dépenses
      └─ 🧾 Historique Dépenses
         └─ ExpensesHistoryScreen (détails)
```

---

## 🛠️ Fichiers Créés/Modifiés

### ✅ Fichiers Créés

1. **`training_expenses_module_screen.dart`**
   - Module 1 : Gestion des plans d'entraînement
   - 2 cartes de navigation

2. **`expenses_tracker_module_screen.dart`**
   - Module 2 : Suivi des dépenses
   - Affichage des catégories

### ✅ Fichiers Modifiés

1. **`user_dashboard_screen.dart`**
   - Ajout imports des 2 modules
   - Ajout fonction `_buildExpensesManagementCard()`
   - Ajout fonction `_buildFinanceModuleButton()`
   - Intégration dans la colonne du dashboard

2. **`physical_activities_main_screen.dart`**
   - Suppression de l'import `expenses_module_screen.dart`
   - Suppression de l'écran des dépenses
   - Suppression du bouton de navigation

### ❌ Fichiers Supprimés

- `expenses_module_screen.dart` (ancien module non structuré)

---

## 🎨 Design & UX

### ✨ Caractéristiques

- **Cartes interactives** avec icons et gradients
- **Couleurs distinctes** pour chaque module (Bleu pour plans, Orange pour dépenses)
- **Animations fluides** au clic
- **Support du thème clair/sombre**
- **Responsive** sur tous les appareils

### 🎯 Principes de Design

✅ **Simplicité** : 2 modules clairs et distincts
✅ **Indépendance** : Modules totalement séparés
✅ **Cohérence** : Design unifié avec le reste de l'app
✅ **Accessibilité** : Navigation intuitive

---

## 📝 Points Importants

✅ Les modules sont **totalement indépendants**
✅ Pas d'intégration aux activités physiques
✅ Cartes cliquables dans le dashboard
✅ Réutilise les écrans existants (UserInfoScreen, SavedPlansScreen, etc.)
✅ Aucune modification à la logique métier

---

## 🚀 Prochaines Étapes (Optionnel)

Vous pouvez améliorer les modules en ajoutant :

- Statistiques et graphiques de dépenses
- Export des données en PDF/CSV
- Notifications de budget dépassé
- Comparaison entre plans
- Budget prévisionnel

---

**Créé le** : 6 novembre 2025
**Dernière mise à jour** : 6 novembre 2025
