import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:healther/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:healther/screens/register_screen.dart';
import 'package:healther/providers/auth_provider.dart';

void main() {
  group('Tests d\'inscription', () {
    testWidgets('L\'écran d\'inscription s\'affiche correctement', (WidgetTester tester) async {
      // Construire l'écran d'inscription
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Vérifier que les champs obligatoires sont présents
      expect(find.text('Nom d\'utilisateur *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Mot de passe *'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe *'), findsOneWidget);
      expect(find.text('S\'inscrire'), findsOneWidget);
      
      // Vérifier que les champs optionnels sont présents
      expect(find.text('Nom (optionnel)'), findsOneWidget);
      expect(find.text('Prénom (optionnel)'), findsOneWidget);
      expect(find.text('Centre de santé (optionnel)'), findsOneWidget);
    });

    testWidgets('Validation - Champs obligatoires vides', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Tenter de soumettre le formulaire vide
      final submitButton = find.text('S\'inscrire');
      await tester.tap(submitButton);
      await tester.pump();

      // Vérifier que les messages d'erreur apparaissent
      expect(find.text('Veuillez entrer un nom d\'utilisateur'), findsWidgets);
      expect(find.text('Veuillez entrer un email'), findsWidgets);
      expect(find.text('Veuillez entrer un mot de passe'), findsWidgets);
    });

    testWidgets('Validation - Email invalide', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Entrer un email invalide
      final emailField = find.widgetWithText(TextFormField, 'Email *').first;
      await tester.enterText(emailField, 'email-invalide');
      await tester.pump();

      // Tenter de soumettre
      final submitButton = find.text('S\'inscrire');
      await tester.tap(submitButton);
      await tester.pump();

      // Vérifier que le message d'erreur d'email apparaît
      expect(find.text('Veuillez entrer un email valide'), findsWidgets);
    });

    testWidgets('Validation - Mot de passe trop court', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Entrer un mot de passe trop court
      final passwordField = find.widgetWithText(TextFormField, 'Mot de passe *').first;
      await tester.enterText(passwordField, '12345'); // 5 caractères
      await tester.pump();

      // Tenter de soumettre
      final submitButton = find.text('S\'inscrire');
      await tester.tap(submitButton);
      await tester.pump();

      // Vérifier que le message d'erreur apparaît
      expect(
        find.text('Le mot de passe doit contenir au moins 6 caractères'),
        findsWidgets,
      );
    });

    testWidgets('Validation - Nom d\'utilisateur trop court', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Entrer un nom d'utilisateur trop court
      final usernameField = find.widgetWithText(TextFormField, 'Nom d\'utilisateur *').first;
      await tester.enterText(usernameField, 'ab'); // 2 caractères
      await tester.pump();

      // Tenter de soumettre
      final submitButton = find.text('S\'inscrire');
      await tester.tap(submitButton);
      await tester.pump();

      // Vérifier que le message d'erreur apparaît
      expect(
        find.text('Le nom d\'utilisateur doit contenir au moins 3 caractères'),
        findsWidgets,
      );
    });

    testWidgets('Validation - Mots de passe ne correspondent pas', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Entrer un mot de passe
      final passwordField = find.widgetWithText(TextFormField, 'Mot de passe *').first;
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Entrer un mot de passe de confirmation différent
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmer le mot de passe *').first;
      await tester.enterText(confirmPasswordField, 'password456');
      await tester.pump();

      // Tenter de soumettre
      final submitButton = find.text('S\'inscrire');
      await tester.tap(submitButton);
      await tester.pump();

      // Vérifier que le message d'erreur apparaît
      expect(
        find.text('Les mots de passe ne correspondent pas'),
        findsWidgets,
      );
    });

    testWidgets('Bouton de masquage/afficher mot de passe fonctionne', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Trouver le bouton d'affichage du mot de passe
      final toggleButton = find.byIcon(Icons.visibility_off).first;
      expect(toggleButton, findsOneWidget);

      // Cliquer sur le bouton
      await tester.tap(toggleButton);
      await tester.pump();

      // Vérifier que l'icône change
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('Formulaire valide - tous les champs remplis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegisterScreen(),
          ),
        ),
      );

      // Remplir tous les champs avec des données valides
      final usernameField = find.widgetWithText(TextFormField, 'Nom d\'utilisateur *').first;
      await tester.enterText(usernameField, 'testuser');
      
      final emailField = find.widgetWithText(TextFormField, 'Email *').first;
      await tester.enterText(emailField, 'test@example.com');
      
      final nomField = find.widgetWithText(TextFormField, 'Nom (optionnel)').first;
      await tester.enterText(nomField, 'Doe');
      
      final prenomField = find.widgetWithText(TextFormField, 'Prénom (optionnel)').first;
      await tester.enterText(prenomField, 'John');
      
      final centreField = find.widgetWithText(TextFormField, 'Centre de santé (optionnel)').first;
      await tester.enterText(centreField, 'Centre Test');
      
      final passwordField = find.widgetWithText(TextFormField, 'Mot de passe *').first;
      await tester.enterText(passwordField, 'password123');
      
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmer le mot de passe *').first;
      await tester.enterText(confirmPasswordField, 'password123');
      
      await tester.pump();

      // Vérifier que le bouton d'inscription est disponible
      final submitButton = find.text('S\'inscrire');
      expect(submitButton, findsOneWidget);

      // Le formulaire devrait être valide maintenant
      // Note: Le test réel de soumission nécessiterait un mock du backend
    });
  });
}

