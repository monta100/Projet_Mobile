# 📡 État des API - App Nutrition

## ✅ Configuration actuelle

### 1. OpenRouter (Chatbot IA - Snacky) ✅
**État** : CONFIGURÉ  
**Clé** : `sk-or-v1-aa7ce633...` (masquée)  
**Fonctionnalité** : Assistant IA conversationnel  
**Test** : Allez dans l'onglet "Assistant IA" et envoyez "Bonjour"

### 2. Gemini AI (Analyse d'images) ⚠️
**État** : NON CONFIGURÉ  
**Clé** : Placeholder (`YOUR_GEMINI_KEY_HERE`)  
**Fonctionnalité** : VisionAI - Analyse de photos de repas  
**Solution** : 
- L'app affichera un message d'aide au lieu de crasher
- Pour activer : Obtenez une clé sur https://makersuite.google.com/app/apikey

### 3. Spoonacular (Recettes) ⚠️
**État** : NON CONFIGURÉ (OPTIONNEL)  
**Clé** : Placeholder  
**Fonctionnalité** : Suggestions de recettes externes  
**Note** : Non critique - l'app fonctionne sans

---

## 🚀 POUR FAIRE FONCTIONNER L'APP MAINTENANT

### Étape 1 : Redémarrer l'application

**IMPORTANT** : Le fichier `.env` n'est chargé qu'au **démarrage** !

Dans le terminal Flutter :
```bash
# Arrêtez l'app
Appuyez sur 'q'

# Relancez
flutter run
```

### Étape 2 : Tester

1. **Chatbot (devrait fonctionner)** ✅
   - Allez dans "Assistant IA" (🤖)
   - Envoyez : "Bonjour"
   - Snacky devrait répondre

2. **VisionAI (message d'info)** ⚠️
   - Allez dans "VisionAI" (🖼️)
   - Prenez une photo
   - Message : "VisionAI n'est pas configuré"

---

## 🔧 Pour activer VisionAI (optionnel)

1. Allez sur https://makersuite.google.com/app/apikey
2. Créez une clé API Gemini (GRATUIT)
3. Modifiez `.env` :
   ```env
   GEMINI_API_KEY=VOTRE_CLE_ICI
   ```
4. Redémarrez l'app

---

## 🐛 Dépannage

### "Erreur IA 401: User not found"
- **Cause** : OpenRouter ne reconnaît pas la clé
- **Solution** : Redémarrez l'app (le .env n'a pas été chargé)

### "Toutes les API tombent en panne"
- **Cause** : .env pas chargé ou clés invalides
- **Solution** : 
  1. Vérifiez que `.env` existe dans `app_nutrition/`
  2. Redémarrez **complètement** l'app (pas Hot Reload)
  3. Cherchez dans les logs : "Loaded .env from asset bundle"

### VisionAI ne marche pas
- **Normal** : Vous n'avez pas de clé Gemini
- **Solution** : Ignorez VisionAI pour l'instant, utilisez le chatbot

---

## ✅ Ce qui fonctionne SANS API

- ✅ Connexion / Inscription
- ✅ Gestion des repas
- ✅ Mes recettes
- ✅ Recettes globales
- ✅ Module Exercices
- ✅ Module Coach
- ✅ Tout sauf le Chatbot IA et VisionAI

---

## 📊 Résumé

| Fonctionnalité | État | API Requise | Gratuit ? |
|----------------|------|-------------|-----------|
| Connexion/Inscription | ✅ | Aucune | - |
| Gestion Repas | ✅ | Aucune | - |
| Recettes | ✅ | Aucune | - |
| Chatbot IA | ✅ | OpenRouter | ✅ Oui |
| VisionAI | ⚠️ | Gemini | ✅ Oui |
| Email vérification | ⚠️ | SMTP Gmail | ✅ Oui |
| Exercices/Coach | ✅ | Aucune | - |

---

## 🎯 PROCHAINES ÉTAPES

1. ✅ **Redémarrez l'app** (`q` puis `flutter run`)
2. ✅ **Testez le chatbot** (devrait marcher)
3. ⏳ **Optionnel** : Ajoutez une clé Gemini pour VisionAI

