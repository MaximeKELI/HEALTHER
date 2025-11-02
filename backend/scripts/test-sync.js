/**
 * Script de test de synchronisation Backend / Frontend / Base de Données
 * 
 * Ce script vérifie que :
 * - Les routes API sont bien configurées
 * - Les services existent
 * - Les tables de base de données existent
 * - Les permissions sont configurées
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

console.log('🔍 Vérification de Synchronisation Backend / Frontend / Base de Données\n');

let errors = [];
let warnings = [];
let success = [];

// ========== VÉRIFICATION BACKEND ==========

console.log('📦 VÉRIFICATION BACKEND\n');

// Vérifier les routes dans server.js
const serverPath = path.join(__dirname, '..', 'server.js');
if (fs.existsSync(serverPath)) {
  const serverContent = fs.readFileSync(serverPath, 'utf8');
  
  // Routes à vérifier
  const requiredRoutes = [
    'contact-tracing',
    'notifications-multichannel',
    'medications'
  ];
  
  requiredRoutes.forEach(route => {
    if (serverContent.includes(route)) {
      success.push(`✅ Route /api/${route} trouvée dans server.js`);
    } else {
      errors.push(`❌ Route /api/${route} MANQUANTE dans server.js`);
    }
  });
  
  // Vérifier les imports
  const requiredImports = [
    'contact_tracing',
    'multi_channel_notifications',
    'medications'
  ];
  
  requiredImports.forEach(importName => {
    if (serverContent.includes(importName)) {
      success.push(`✅ Import ${importName}Routes trouvé`);
    } else {
      errors.push(`❌ Import ${importName}Routes MANQUANT`);
    }
  });
} else {
  errors.push('❌ server.js non trouvé');
}

// Vérifier les fichiers de routes
const routesDir = path.join(__dirname, '..', 'routes');
const requiredRouteFiles = [
  'contact_tracing.js',
  'multi_channel_notifications.js',
  'medications.js'
];

requiredRouteFiles.forEach(file => {
  const filePath = path.join(routesDir, file);
  if (fs.existsSync(filePath)) {
    success.push(`✅ Route ${file} existe`);
  } else {
    errors.push(`❌ Route ${file} MANQUANTE`);
  }
});

// Vérifier les services
const servicesDir = path.join(__dirname, '..', 'services');
const requiredServices = [
  'contact_tracing_service.js',
  'multi_channel_notification_service.js',
  'medication_service.js'
];

requiredServices.forEach(file => {
  const filePath = path.join(servicesDir, file);
  if (fs.existsSync(filePath)) {
    success.push(`✅ Service ${file} existe`);
  } else {
    errors.push(`❌ Service ${file} MANQUANT`);
  }
});

// Vérifier package.json
const packagePath = path.join(__dirname, '..', 'package.json');
if (fs.existsSync(packagePath)) {
  const packageContent = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
  if (packageContent.dependencies && packageContent.dependencies.nodemailer) {
    success.push('✅ nodemailer dans package.json');
  } else {
    warnings.push('⚠️ nodemailer manquant dans package.json (requis pour Email SMTP)');
  }
}

console.log(success.join('\n'));
if (warnings.length > 0) {
  console.log('\n' + warnings.join('\n'));
}
if (errors.length > 0) {
  console.log('\n' + errors.join('\n'));
}

success = [];
warnings = [];
errors = [];

// ========== VÉRIFICATION BASE DE DONNÉES ==========

console.log('\n🗄️ VÉRIFICATION BASE DE DONNÉES\n');

const dbPath = path.join(__dirname, '..', 'data', 'made.db');

if (fs.existsSync(dbPath)) {
  const db = new sqlite3.Database(dbPath);
  
  // Vérifier les tables
  const requiredTables = [
    'medication_reminders',
    'medication_adherence'
  ];
  
  requiredTables.forEach(table => {
    db.get(
      `SELECT name FROM sqlite_master WHERE type='table' AND name=?`,
      [table],
      (err, row) => {
        if (err) {
          errors.push(`❌ Erreur vérification table ${table}: ${err.message}`);
        } else if (row) {
          success.push(`✅ Table ${table} existe`);
        } else {
          errors.push(`❌ Table ${table} MANQUANTE`);
        }
      }
    );
  });
  
  // Vérifier les permissions
  db.all(
    `SELECT * FROM permissions WHERE resource IN ('medications', 'notifications')`,
    [],
    (err, rows) => {
      if (err) {
        warnings.push(`⚠️ Erreur vérification permissions: ${err.message}`);
      } else if (rows && rows.length > 0) {
        success.push(`✅ ${rows.length} permission(s) trouvée(s) pour medications/notifications`);
      } else {
        warnings.push('⚠️ Permissions pour medications/notifications non trouvées');
      }
      
      // Afficher les résultats
      setTimeout(() => {
        console.log(success.join('\n'));
        if (warnings.length > 0) {
          console.log('\n' + warnings.join('\n'));
        }
        if (errors.length > 0) {
          console.log('\n' + errors.join('\n'));
        }
        
        // Résumé final
        console.log('\n' + '='.repeat(50));
        console.log('📊 RÉSUMÉ DE VÉRIFICATION');
        console.log('='.repeat(50));
        console.log(`✅ Succès: ${success.length}`);
        console.log(`⚠️ Avertissements: ${warnings.length}`);
        console.log(`❌ Erreurs: ${errors.length}`);
        
        if (errors.length === 0 && warnings.length === 0) {
          console.log('\n🎉 Tous les composants sont synchronisés !');
        } else if (errors.length === 0) {
          console.log('\n✅ Synchronisation OK (quelques avertissements)');
        } else {
          console.log('\n❌ Des erreurs doivent être corrigées');
        }
        
        db.close();
      }, 1000);
    }
  );
} else {
  console.log('⚠️ Base de données non trouvée. Exécutez "npm run init-db" pour la créer.');
  console.log('📝 Chemin attendu:', dbPath);
}

// ========== VÉRIFICATION FRONTEND ==========

console.log('\n📱 VÉRIFICATION FRONTEND (Flutter)\n');

const flutterServicesDir = path.join(__dirname, '..', '..', 'healther', 'lib', 'services');
const flutterScreensDir = path.join(__dirname, '..', '..', 'healther', 'lib', 'screens');

const requiredFlutterServices = [
  'contact_tracing_service.dart',
  'medication_service.dart',
  'multi_channel_notification_service.dart'
];

const requiredFlutterScreens = [
  'contact_tracing_screen.dart',
  'dashboard_patient_screen.dart',
  'lab_results_screen.dart',
  'medication_reminders_screen.dart'
];

// Vérifier les services Flutter
requiredFlutterServices.forEach(file => {
  const filePath = path.join(flutterServicesDir, file);
  if (fs.existsSync(filePath)) {
    success.push(`✅ Service Flutter ${file} existe`);
  } else {
    warnings.push(`⚠️ Service Flutter ${file} MANQUANT`);
  }
});

// Vérifier les écrans Flutter
requiredFlutterScreens.forEach(file => {
  const filePath = path.join(flutterScreensDir, file);
  if (fs.existsSync(filePath)) {
    success.push(`✅ Écran Flutter ${file} existe`);
  } else {
    warnings.push(`⚠️ Écran Flutter ${file} MANQUANT`);
  }
});

console.log(success.join('\n'));
if (warnings.length > 0) {
  console.log('\n' + warnings.join('\n'));
}

