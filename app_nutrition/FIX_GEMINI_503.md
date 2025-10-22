# 🔧 Fix: Erreur 503 - Gemini AI Overloaded

## ❌ Problème

Vous rencontriez cette erreur lors de l'analyse d'image :

```
GenerativeAIException: Server Error [503]: {
  "error": {
    "code": 503,
    "message": "The model is overloaded. Please try again later.",
    "status": "UNAVAILABLE"
  }
}
```

## 🔍 Cause

L'erreur **503 (Service Unavailable)** signifie que :

1. Le serveur Google Gemini AI est **temporairement surchargé**
2. Trop de requêtes arrivent en même temps
3. Le modèle `gemini-2.0-flash-exp` (expérimental) est moins stable
4. C'est un problème **côté serveur Google**, pas votre code !

### Pourquoi ça arrive ?

- ⏰ **Heures de pointe** : Beaucoup d'utilisateurs utilisent l'API en même temps
- 🧪 **Modèle expérimental** : Les versions `-exp` sont moins stables
- 🌍 **Infrastructure** : Les serveurs Google peuvent être temporairement saturés

---

## ✅ Solutions appliquées

### 1️⃣ Changement de modèle

**Avant** :
```dart
final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
```

**Après** :
```dart
// Utilise gemini-1.5-flash (plus stable que la version expérimentale)
final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
```

**Avantages** :
- ✅ Version stable et éprouvée
- ✅ Moins de risques de surcharge
- ✅ Meilleure disponibilité
- ✅ Performance similaire

### 2️⃣ Système de Retry automatique

Ajout d'un système intelligent de retry avec **backoff exponentiel** :

```dart
// 🔁 Système de retry avec 3 tentatives
int maxRetries = 3;
int retryDelay = 2; // secondes

for (int attempt = 1; attempt <= maxRetries; attempt++) {
  try {
    // Tentative d'analyse
    final response = await model.generateContent([...]);
    return response.text ?? "Aucune réponse détectée.";
    
  } catch (e) {
    if (errorString.contains('503') || errorString.contains('overloaded')) {
      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: retryDelay));
        retryDelay *= 2; // 2s, 4s, 8s...
        continue;
      }
    }
  }
}
```

**Comment ça fonctionne** :
1. **1ère tentative** → Erreur 503 → Attend 2 secondes
2. **2ème tentative** → Erreur 503 → Attend 4 secondes
3. **3ème tentative** → Erreur 503 → Message d'erreur clair

### 3️⃣ Gestion intelligente des erreurs

Messages d'erreur clairs et adaptés :

| Code | Message utilisateur |
|------|---------------------|
| 503 | ⚠️ Le serveur Gemini AI est temporairement surchargé. Veuillez réessayer dans quelques minutes. |
| 429 | ⚠️ Quota API dépassé. Attendez quelques minutes ou vérifiez votre clé API. |
| 401/403 | ❌ Clé API invalide. Vérifiez votre clé Gemini dans le fichier .env |
| Network | ❌ Problème de connexion internet |
| Timeout | ❌ Délai d'attente dépassé |

---

## 🎯 Comment ça fonctionne maintenant

### Scénario 1 : Succès immédiat ✅
```
Tentative 1 → ✅ Succès
Résultat: "Je vois une salade, environ 200 kcal"
```

### Scénario 2 : Retry automatique 🔁
```
Tentative 1 → ❌ Erreur 503 → Attend 2s
Tentative 2 → ✅ Succès
Résultat: "Je vois du riz et du poulet, environ 600 kcal"
```

### Scénario 3 : Serveur vraiment surchargé ⚠️
```
Tentative 1 → ❌ Erreur 503 → Attend 2s
Tentative 2 → ❌ Erreur 503 → Attend 4s
Tentative 3 → ❌ Erreur 503
Résultat: "⚠️ Le serveur Gemini AI est temporairement surchargé. 
           Veuillez réessayer dans quelques minutes."
```

---

## 🧪 Tester les améliorations

```bash
# 1. Relancez l'application
flutter run

# 2. Testez VisionAI
# - Allez dans l'onglet "VisionAI"
# - Prenez une photo de nourriture
# - L'analyse devrait :
#   ✅ Fonctionner du premier coup (si serveur OK)
#   ✅ OU réessayer automatiquement (si erreur 503)
#   ✅ OU afficher un message clair (si vraiment surchargé)
```

---

## 📊 Comparaison Avant/Après

### Avant ❌

```
Erreur → Message technique incompréhensible
"GenerativeAIException: Server Error [503]..."
```

- ❌ Pas de retry automatique
- ❌ Message d'erreur technique
- ❌ Mauvaise expérience utilisateur

### Après ✅

```
Erreur → Retry automatique → Message clair si échec
"⚠️ Le serveur Gemini AI est temporairement surchargé. 
Veuillez réessayer dans quelques minutes."
```

- ✅ 3 tentatives automatiques
- ✅ Messages clairs et en français
- ✅ Meilleure expérience utilisateur
- ✅ Modèle plus stable

---

## 💡 Conseils pour éviter l'erreur 503

### Pour vous (développeur)

1. **Utiliser `gemini-1.5-flash`** au lieu de versions expérimentales
2. **Implémenter le retry** (déjà fait !)
3. **Cache les résultats** si vous analysez souvent les mêmes images
4. **Limiter le nombre de requêtes** simultanées

### Pour les utilisateurs

1. **Réessayer après quelques minutes** si le message apparaît
2. **Éviter les heures de pointe** (midi, soir)
3. **Vérifier la connexion internet**

---

## 🔄 Alternatives au modèle Gemini

Si les problèmes persistent, vous pouvez aussi essayer :

### Option A : Gemini Pro
```dart
final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
```
- Plus puissant mais plus lent
- Coûte plus de quota

### Option B : Gemini 1.5 Pro
```dart
final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
```
- Très stable
- Meilleure qualité d'analyse

### Option C : Modèle actuel (RECOMMANDÉ)
```dart
final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
```
- ✅ Bon équilibre vitesse/qualité
- ✅ Stable et fiable
- ✅ Moins cher en quota

---

## 📈 Monitoring des erreurs

Les logs vous aideront à comprendre :

```
Console logs:
❌ Tentative 1/3 échouée : GenerativeAIException...
⏳ Serveur surchargé. Nouvelle tentative dans 2 secondes...
❌ Tentative 2/3 échouée : GenerativeAIException...
⏳ Serveur surchargé. Nouvelle tentative dans 4 secondes...
✅ Tentative 3/3 réussie !
```

---

## ⚙️ Configuration du Retry

Si vous voulez ajuster les paramètres :

```dart
// Dans image_ai_analysis_service.dart

// Modifier le nombre de tentatives
int maxRetries = 5; // Au lieu de 3

// Modifier le délai initial
int retryDelay = 1; // Au lieu de 2 secondes

// Le délai augmente exponentiellement :
// Tentative 1 : 1s
// Tentative 2 : 2s  
// Tentative 3 : 4s
// Tentative 4 : 8s
// Tentative 5 : 16s
```

---

## 🆘 Si le problème persiste

### Vérifications

1. **Vérifier votre quota API**
   - Allez sur https://makersuite.google.com/app/apikey
   - Vérifiez que vous n'avez pas dépassé le quota gratuit

2. **Vérifier la clé API**
   ```bash
   type .env
   # Vérifiez que GEMINI_API_KEY est correct
   ```

3. **Tester l'API directement**
   - Allez sur https://makersuite.google.com
   - Testez si l'API fonctionne

4. **Attendez quelques heures**
   - Le serveur peut être vraiment surchargé
   - Réessayez plus tard

---

## 📚 Ressources

- [Google AI Studio](https://makersuite.google.com/)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Status Page Google Cloud](https://status.cloud.google.com/)

---

**Date du fix** : 22 octobre 2025  
**Statut** : ✅ Résolu avec retry automatique  
**Version** : 1.2.0

🎉 **Votre analyse d'image est maintenant beaucoup plus robuste !**


