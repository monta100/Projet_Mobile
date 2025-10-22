# 📋 Liste Complète des API - App Nutrition

## 🎯 Toutes les API utilisées dans le projet

### ✅ 1. OpenRouter API - **CONFIGURÉ**
- **Fichier** : `Services/openrouter_service.dart`
- **Variable** : `OPENROUTER_API_KEY`
- **Valeur** : `sk-or-v1-aa7ce633...` ✅
- **Fonctionnalité** : Chatbot IA (Snacky) - Assistant conversationnel
- **Modèle utilisé** : `openai/gpt-3.5-turbo`
- **Gratuit ?** : Oui (avec crédit de départ)
- **Obtenir clé** : https://openrouter.ai/keys
- **État** : ✅ PRÊT À UTILISER

---

### ⚠️ 2. Gemini AI API - À configurer
- **Fichier** : `Services/image_ai_analysis_service.dart`
- **Variable** : `GEMINI_API_KEY`
- **Valeur** : `YOUR_GEMINI_API_KEY_HERE` (placeholder)
- **Fonctionnalité** : VisionAI - Analyse de photos de repas
- **Modèle utilisé** : `gemini-2.0-flash-exp`
- **Gratuit ?** : ✅ Oui (100% gratuit)
- **Obtenir clé** : https://makersuite.google.com/app/apikey
- **État** : ⚠️ Message d'aide affiché si absent

---

### ⚠️ 3. Spoonacular API - Optionnel
- **Fichier** : `Services/nutrition_ai_service.dart`
- **Variable** : `SPOONACULAR_API_KEY`
- **Valeur** : `YOUR_SPOONACULAR_API_KEY_HERE` (placeholder)
- **Fonctionnalité** : Suggestions de recettes depuis base externe
- **Gratuit ?** : ✅ Oui (150 requêtes/jour)
- **Obtenir clé** : https://spoonacular.com/food-api
- **État** : ⚠️ PAS CRITIQUE - L'app a ses propres recettes

---

### ⚠️ 4. SMTP - Emails - Optionnel
- **Fichier** : `Services/email_service.dart`
- **Variables** : 
  - `SMTP_HOST`
  - `SMTP_PORT`
  - `SMTP_USER`
  - `SMTP_PASS`
  - `SMTP_SSL`
- **Fonctionnalité** : Envoi du code de vérification par email
- **Gratuit ?** : ✅ Oui (Gmail gratuit)
- **État** : ⚠️ Code affiché dans console si absent

**Options SMTP** :
- **Gmail** : Mot de passe d'application (https://myaccount.google.com/security)
- **Mailtrap** : Emails de test (https://mailtrap.io)

---

## 📊 Résumé par priorité

| API | Priorité | État | Impact si absent |
|-----|----------|------|------------------|
| OpenRouter | 🔴 **HAUTE** | ✅ Configuré | Chatbot ne fonctionne pas |
| Gemini AI | 🟡 **MOYENNE** | ⚠️ À config | VisionAI désactivé, reste OK |
| Spoonacular | 🟢 **BASSE** | ⚠️ Optionnel | Recettes externes manquantes |
| SMTP | 🟢 **BASSE** | ⚠️ Optionnel | Code dans console |

---

## 🚀 Pour démarrer maintenant

### Ce qui fonctionne DÉJÀ (avec juste OpenRouter) ✅

1. ✅ **Connexion / Inscription**
2. ✅ **Gestion des repas**
3. ✅ **Mes recettes personnelles**
4. ✅ **Recettes globales**
5. ✅ **Chatbot IA (Snacky)** 🤖
6. ✅ **Module Exercices**
7. ✅ **Module Coach**
8. ✅ **Tout sauf VisionAI**

### Ce qui affiche un message d'aide ⚠️

- ⚠️ **VisionAI** : "VisionAI n'est pas configuré..."
- ⚠️ **Code vérification** : Affiché dans console Flutter

---

## 🔧 Configuration rapide (optionnel)

### Pour activer VisionAI (2 minutes)

1. Allez sur https://makersuite.google.com/app/apikey
2. Créez une clé API Gemini (gratuit, pas de carte bancaire)
3. Copiez la clé
4. Modifiez `.env` :
   ```env
   GEMINI_API_KEY=AIza...votre_clé_ici
   ```
5. Redémarrez l'app : `q` puis `flutter run`

---

## ✅ Fichier .env final

Le fichier `.env` contient MAINTENANT :

```env
# ✅ CONFIGURÉES
OPENROUTER_API_KEY=sk-or-v1-... (votre clé)

# ⚠️ À CONFIGURER (optionnel)
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
SPOONACULAR_API_KEY=YOUR_SPOONACULAR_API_KEY_HERE

# ⚠️ SMTP (commentées - optionnel)
# SMTP_HOST=...
# SMTP_PORT=...
# etc.
```

---

## 🎯 PROCHAINE ÉTAPE

**REDÉMARREZ L'APP** pour charger le `.env` :

```bash
# Dans le terminal Flutter
Appuyez sur 'q'
Puis: flutter run
```

**Testez le chatbot** dans l'onglet "Assistant IA" ! 🚀

