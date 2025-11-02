# Test Manuel d'Inscription HEALTHER

## Prérequis
- Backend Node.js en cours d'exécution sur `http://localhost:3000`
- Base de données SQLite initialisée

## Test 1 : Vérification de l'écran d'inscription

1. Lancer l'application Flutter :
   ```bash
   cd healther && flutter run -d linux
   ```

2. Depuis l'écran de connexion, cliquer sur "Pas encore de compte ? S'inscrire"

3. Vérifier que l'écran d'inscription s'affiche avec :
   - Logo HEALTHER
   - Titre "Créer un compte"
   - Champs :
     - Nom d'utilisateur * (obligatoire)
     - Email * (obligatoire)
     - Nom (optionnel)
     - Prénom (optionnel)
     - Centre de santé (optionnel)
     - Mot de passe * (obligatoire)
     - Confirmer le mot de passe * (obligatoire)
   - Bouton "S'inscrire"
   - Lien "Déjà un compte ? Se connecter"

## Test 2 : Validation côté client

### Test 2.1 : Champs vides
1. Cliquer sur "S'inscrire" sans remplir les champs
2. Vérifier que les messages d'erreur apparaissent :
   - "Veuillez entrer un nom d'utilisateur"
   - "Veuillez entrer un email"
   - "Veuillez entrer un mot de passe"

### Test 2.2 : Email invalide
1. Remplir :
   - Nom d'utilisateur : testuser
   - Email : email-invalide (sans @)
   - Mot de passe : password123
   - Confirmer mot de passe : password123
2. Cliquer sur "S'inscrire"
3. Vérifier que le message "Veuillez entrer un email valide" apparaît

### Test 2.3 : Mot de passe trop court
1. Remplir :
   - Nom d'utilisateur : testuser
   - Email : test@example.com
   - Mot de passe : 12345 (5 caractères)
   - Confirmer mot de passe : 12345
2. Cliquer sur "S'inscrire"
3. Vérifier que le message "Le mot de passe doit contenir au moins 6 caractères" apparaît

### Test 2.4 : Nom d'utilisateur trop court
1. Remplir :
   - Nom d'utilisateur : ab (2 caractères)
   - Email : test@example.com
   - Mot de passe : password123
   - Confirmer mot de passe : password123
2. Cliquer sur "S'inscrire"
3. Vérifier que le message "Le nom d'utilisateur doit contenir au moins 3 caractères" apparaît

### Test 2.5 : Mots de passe ne correspondent pas
1. Remplir :
   - Nom d'utilisateur : testuser
   - Email : test@example.com
   - Mot de passe : password123
   - Confirmer mot de passe : password456
2. Cliquer sur "S'inscrire"
3. Vérifier que le message "Les mots de passe ne correspondent pas" apparaît

### Test 2.6 : Masquage/Affichage mot de passe
1. Entrer du texte dans le champ "Mot de passe"
2. Vérifier que le texte est masqué (points)
3. Cliquer sur l'icône œil
4. Vérifier que le texte est visible

## Test 3 : Inscription réussie

### Test 3.1 : Inscription avec tous les champs
1. Remplir tous les champs :
   - Nom d'utilisateur : `testuser_${DateTime.now().millisecondsSinceEpoch}`
   - Email : `test_${DateTime.now().millisecondsSinceEpoch}@example.com`
   - Nom : Test
   - Prénom : User
   - Centre de santé : Centre Test
   - Mot de passe : password123
   - Confirmer mot de passe : password123
2. Cliquer sur "S'inscrire"
3. Vérifier :
   - Un message de succès s'affiche : "Inscription réussie ! Bienvenue sur HEALTHER"
   - L'utilisateur est automatiquement connecté
   - Redirection vers l'écran d'accueil (HomeScreen)

### Test 3.2 : Inscription avec champs minimum
1. Remplir uniquement les champs obligatoires :
   - Nom d'utilisateur : `minimal_${DateTime.now().millisecondsSinceEpoch}`
   - Email : `minimal_${DateTime.now().millisecondsSinceEpoch}@example.com`
   - Mot de passe : password123
   - Confirmer mot de passe : password123
2. Cliquer sur "S'inscrire"
3. Vérifier que l'inscription réussit et redirige vers l'accueil

## Test 4 : Erreurs serveur

### Test 4.1 : Nom d'utilisateur déjà existant
1. Essayer de créer un compte avec un nom d'utilisateur existant
2. Vérifier qu'un message d'erreur s'affiche : "Un utilisateur avec ce nom ou email existe déjà"

### Test 4.2 : Email déjà existant
1. Essayer de créer un compte avec un email existant
2. Vérifier qu'un message d'erreur s'affiche : "Un utilisateur avec ce nom ou email existe déjà"

## Test 5 : Navigation

1. Depuis l'écran d'inscription, cliquer sur "Déjà un compte ? Se connecter"
2. Vérifier qu'on retourne à l'écran de connexion

## Résultat attendu

Tous les tests doivent passer avec succès, confirmant que :
- ✅ L'interface d'inscription fonctionne correctement
- ✅ La validation côté client fonctionne
- ✅ L'inscription réussit et connecte automatiquement l'utilisateur
- ✅ Les erreurs sont gérées correctement
- ✅ La navigation entre les écrans fonctionne

