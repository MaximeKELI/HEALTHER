const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const readline = require('readline');

const dbPath = path.join(__dirname, '..', 'data', 'made.db');
const db = new sqlite3.Database(dbPath);

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function createUser() {
  try {
    console.log('\n📝 Création d\'un nouvel utilisateur\n');
    
    const username = await question('Nom d\'utilisateur: ');
    const email = await question('Email: ');
    const password = await question('Mot de passe (sera stocké en clair pour le POC): ');
    const nom = await question('Nom (optionnel): ');
    const prenom = await question('Prénom (optionnel): ');
    const centreSante = await question('Centre de santé (optionnel): ');
    const role = await question('Rôle (agent/admin, défaut: agent): ') || 'agent';

    // Vérifier si l'utilisateur existe déjà
    db.get('SELECT * FROM users WHERE username = ? OR email = ?', [username, email], (err, row) => {
      if (err) {
        console.error('❌ Erreur:', err);
        rl.close();
        db.close();
        return;
      }

      if (row) {
        console.log('❌ Un utilisateur avec ce nom ou email existe déjà');
        rl.close();
        db.close();
        return;
      }

      // Créer l'utilisateur
      db.run(
        `INSERT INTO users (username, email, password_hash, nom, prenom, centre_sante, role)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [username, email, password, nom || null, prenom || null, centreSante || null, role],
        function(err) {
          if (err) {
            console.error('❌ Erreur lors de la création:', err);
          } else {
            console.log(`\n✅ Utilisateur créé avec succès! ID: ${this.lastID}`);
            console.log(`\nVous pouvez maintenant vous connecter avec:`);
            console.log(`Username: ${username}`);
            console.log(`Password: ${password}\n`);
          }
          rl.close();
          db.close();
        }
      );
    });
  } catch (error) {
    console.error('❌ Erreur:', error);
    rl.close();
    db.close();
  }
}

createUser();


