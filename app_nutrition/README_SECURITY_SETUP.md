# 🚀 Setup Rapide - Sécurité API

## Installation en 3 étapes

### 1. Copier le template
```bash
cp .env.example .env
```

### 2. Ajouter vos clés API dans `.env`

Ouvrez `.env` et remplacez :

```env
SPOONACULAR_API_KEY=votre_cle_spoonacular_ici
GEMINI_API_KEY=votre_cle_gemini_ici
OPENROUTER_API_KEY=votre_cle_openrouter_ici
```

### 3. Installer et lancer
```bash
flutter pub get
flutter run
```

## ⚠️ IMPORTANT

- ❌ **NE JAMAIS** commit le fichier `.env`
- ✅ Le fichier `.env` est déjà dans `.gitignore`
- ✅ Utilisez `.env.example` comme template

## 🔑 Où obtenir les clés ?

| Service | URL | Variable |
|---------|-----|----------|
| Spoonacular | https://spoonacular.com/food-api | `SPOONACULAR_API_KEY` |
| Google Gemini | https://makersuite.google.com/app/apikey | `GEMINI_API_KEY` |
| OpenRouter | https://openrouter.ai/keys | `OPENROUTER_API_KEY` |

## 📚 Documentation complète

Pour plus de détails, consultez [SECURITY.md](./SECURITY.md)

---

✅ **Vous êtes prêt !** Vos clés API sont maintenant sécurisées.


