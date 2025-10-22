# 📧 Configuration de l'envoi d'emails

## Problème actuel
Les emails de vérification ne s'envoient pas car le fichier `.env` n'était pas configuré.

## ✅ Solution

### Option 1 : Gmail (Recommandé pour développement)

1. **Activer la validation en 2 étapes sur votre compte Google**
   - Allez sur https://myaccount.google.com/security
   - Activez "Validation en deux étapes"

2. **Créer un mot de passe d'application**
   - Toujours sur https://myaccount.google.com/security
   - Cliquez sur "Mots de passe des applications"
   - Sélectionnez "Autre (nom personnalisé)"
   - Nommez-le "App Nutrition"
   - Copiez le mot de passe généré (16 caractères)

3. **Modifier le fichier `.env`**
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=votre.email@gmail.com
   SMTP_PASS=xxxx xxxx xxxx xxxx  # Le mot de passe d'application
   SMTP_SSL=false
   ```

4. **Redémarrer l'application**
   ```bash
   flutter run
   ```

---

### Option 2 : Mailtrap (Pour tests - emails simulés)

**Avantage** : Les emails ne sortent pas vraiment, parfait pour tester !

1. **Créer un compte gratuit**
   - Allez sur https://mailtrap.io
   - Créez un compte gratuit

2. **Obtenir les identifiants**
   - Dans "Email Testing" → "Inboxes"
   - Cliquez sur votre inbox
   - Copiez les identifiants SMTP

3. **Modifier le fichier `.env`**
   ```env
   SMTP_HOST=smtp.mailtrap.io
   SMTP_PORT=2525
   SMTP_USER=votre_username
   SMTP_PASS=votre_password
   SMTP_SSL=false
   ```

4. **Redémarrer l'application**
   ```bash
   flutter run
   ```

5. **Voir les emails**
   - Retournez sur mailtrap.io
   - Les emails apparaissent dans votre inbox virtuelle

---

### Option 3 : Désactiver l'envoi d'email (Mode développement)

Si vous ne voulez pas configurer d'email pour l'instant :

1. Le **code de vérification s'affiche dans la console** (logs Flutter)
2. Cherchez dans les logs :
   ```
   EmailService not configured: verification code: 123456
   ```
3. Utilisez ce code pour vérifier le compte

---

## 🔍 Comment vérifier que ça marche

1. **Inscrivez un nouveau compte**
2. **Vérifiez la console Flutter**, vous devriez voir :
   ```
   SMTP config loaded: host=smtp.gmail.com port=587 user=votre@email.com ssl=false
   Email envoyé: ...
   ```

3. **Si configuré avec Gmail** : Vérifiez votre boîte mail
4. **Si configuré avec Mailtrap** : Vérifiez votre inbox sur mailtrap.io
5. **Si pas configuré** : Le code apparaît dans la console

---

## ⚠️ Important

- **NE JAMAIS** commiter le fichier `.env` dans Git (déjà dans .gitignore)
- Le mot de passe d'application Gmail est différent de votre mot de passe Gmail normal
- Pour la production, utilisez un service d'email professionnel (SendGrid, Mailgun, etc.)

---

## 🐛 Dépannage

### "Erreur envoi email: ..."
- Vérifiez que les identifiants SMTP sont corrects
- Vérifiez que le port est bon (587 pour Gmail sans SSL)
- Vérifiez votre connexion internet

### "EmailService not configured"
- Le fichier `.env` n'est pas chargé
- Vérifiez que le fichier `.env` est dans le dossier `app_nutrition/`
- Redémarrez l'application (pas juste Hot Reload)

### Le code ne s'affiche pas dans la console
- Regardez tout en haut des logs Flutter
- Le message apparaît juste après l'inscription

