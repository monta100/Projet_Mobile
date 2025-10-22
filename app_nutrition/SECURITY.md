# 🔒 Guide de Sécurité - Protection des Clés API

## ⚠️ IMPORTANT

**NE JAMAIS** commiter le fichier `.env` sur Git !  
Ce fichier contient vos clés API secrètes et ne doit **JAMAIS** être partagé publiquement.

---

## 📋 Configuration des Clés API

### 1. Premier Setup

Lorsque vous clonez ce projet pour la première fois :

```bash
# 1. Copiez le fichier template
cp .env.example .env

# 2. Éditez .env et ajoutez vos vraies clés API
# Ouvrez .env dans votre éditeur et remplacez les valeurs
```

### 2. Obtenir vos Clés API

#### Spoonacular (Nutrition)
- Site: https://spoonacular.com/food-api
- Créez un compte gratuit
- Obtenez votre clé API
- Ajoutez-la dans `.env` : `SPOONACULAR_API_KEY=votre_cle_ici`

#### Google Gemini AI (Analyse d'image)
- Site: https://makersuite.google.com/app/apikey
- Connectez-vous avec votre compte Google
- Créez une clé API
- Ajoutez-la dans `.env` : `GEMINI_API_KEY=votre_cle_ici`

#### OpenRouter (Chatbot)
- Site: https://openrouter.ai/keys
- Créez un compte
- Générez une clé API
- Ajoutez-la dans `.env` : `OPENROUTER_API_KEY=votre_cle_ici`

---

## 🛡️ Bonnes Pratiques de Sécurité

### ✅ À FAIRE

1. **Garder `.env` local uniquement**
   - Le fichier `.env` est dans `.gitignore`
   - Il ne sera jamais envoyé sur GitHub

2. **Utiliser `.env.example` comme documentation**
   - Commiter `.env.example` (sans les vraies clés)
   - Les autres développeurs peuvent le copier

3. **Partager les clés en privé**
   - Si vous travaillez en équipe, partagez les clés par email/message privé
   - Ne les postez JAMAIS publiquement

4. **Vérifier avant de commit**
   ```bash
   # Vérifiez que .env n'est pas tracké
   git status
   
   # Si .env apparaît, ne le commitez pas !
   ```

### ❌ À NE JAMAIS FAIRE

1. ❌ Commiter le fichier `.env`
2. ❌ Mettre les clés directement dans le code
3. ❌ Partager les clés sur Slack/Discord/forums publics
4. ❌ Copier-coller les clés dans les issues GitHub
5. ❌ Publier les clés dans les screenshots

---

## 🔍 Vérifier la Sécurité

### Avant de pusher sur Git

```bash
# 1. Vérifier que .env est ignoré
git status

# 2. Vérifier le contenu de ce qui sera commit
git diff

# 3. Rechercher des clés API dans les fichiers tracés
git grep -i "api[_-]key"
git grep -E "sk-|AIza"

# Si vous trouvez des clés, NE POUSSEZ PAS !
```

### Si vous avez accidentellement commit une clé

**⚠️ ALERTE SÉCURITÉ** : Si vous avez commit une clé API :

1. **Révoquez immédiatement la clé** sur le site du fournisseur
2. **Générez une nouvelle clé**
3. **Nettoyez l'historique Git** :

```bash
# Option 1: Retirer le dernier commit (si pas encore pushé)
git reset HEAD~1

# Option 2: Si déjà pushé, contacter le fournisseur de la clé
# et regénérer une nouvelle clé immédiatement
```

---

## 🚀 Installation pour un Nouveau Développeur

Si quelqu'un clone le projet :

```bash
# 1. Cloner le repo
git clone https://github.com/votre-repo/app_nutrition.git
cd app_nutrition

# 2. Copier le template
cp .env.example .env

# 3. Demander les clés à l'équipe (en privé)
# Les ajouter dans .env

# 4. Installer les dépendances
flutter pub get

# 5. Lancer l'app
flutter run
```

---

## 📁 Fichiers de Configuration

### `.env` (PRIVÉ - Ne jamais commit)
```env
SPOONACULAR_API_KEY=1f6fa3aff2334e7fb4254f735eb58d5b
GEMINI_API_KEY=AIzaSyByO3OR5XqG09UOZpYXjA1JprjahSXLeGA
OPENROUTER_API_KEY=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
```

### `.env.example` (PUBLIC - À commit)
```env
SPOONACULAR_API_KEY=votre_cle_spoonacular_ici
GEMINI_API_KEY=votre_cle_gemini_ici
OPENROUTER_API_KEY=votre_cle_openrouter_ici
```

### `.gitignore` (vérifie que .env est ignoré)
```
.env
.env.local
.env.*.local
*.env
```

---

## 🔧 Dépannage

### Erreur: "Env file not found"

```bash
# Vérifiez que .env existe
ls -la .env

# Si absent, copiez le template
cp .env.example .env
```

### Erreur: "API Key not found"

Vérifiez que les clés sont bien définies dans `.env` :

```bash
cat .env
# Doit afficher vos clés
```

### L'app ne charge pas les clés

1. Vérifiez que `.env` est dans `pubspec.yaml` > `assets`
2. Relancez `flutter pub get`
3. Redémarrez l'app (pas juste hot reload)

---

## 📞 Support

Si vous avez des questions sur la sécurité :

1. **Ne postez JAMAIS vos clés dans les issues**
2. Contactez l'équipe en privé
3. Consultez ce guide en premier

---

## 📝 Checklist avant Push

- [ ] `.env` est dans `.gitignore`
- [ ] `.env` n'apparaît pas dans `git status`
- [ ] `.env.example` est à jour (sans vraies clés)
- [ ] Aucune clé en dur dans le code
- [ ] Tests passent avec les variables d'environnement

---

**Date de création** : 22 octobre 2025  
**Version** : 1.0.0  
**Statut** : 🔒 Sécurisé


