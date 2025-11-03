const request = require('supertest');
const path = require('path');
const fs = require('fs');

// Forcer le stockage local pendant les tests
process.env.STORAGE_PROVIDER = 'local';
process.env.API_BASE_URL = 'http://localhost:3000';

const app = require('../server');

describe('Users - Profile picture upload', () => {
  let token;
  let userId;

  beforeAll(async () => {
    // Créer un utilisateur unique
    const username = `testuser_${Date.now()}`;
    const email = `${username}@example.com`;
    const password = 'password123';

    const regRes = await request(app)
      .post('/api/users/register')
      .send({ username, email, password });

    expect(regRes.statusCode).toBe(201);
    expect(regRes.body).toHaveProperty('user');
    userId = regRes.body.user.id;

    const loginRes = await request(app)
      .post('/api/users/login')
      .send({ username, password });

    expect(loginRes.statusCode).toBe(200);
    expect(loginRes.body).toHaveProperty('token');
    token = loginRes.body.token;
  }, 20000);

  test('should upload profile picture and return signed url', async () => {
    // Générer une image PNG minimale en mémoire
    const pngHeader = Buffer.from('89504E470D0A1A0A', 'hex'); // PNG signature
    const minimalIHDR = Buffer.from(
      '0000000D49484452000000010000000108020000009077S1',
      'hex'
    );
    // Si la ligne ci-dessus pose problème, fallback vers un fichier temporaire arbitraire
    const tmpFile = path.join(__dirname, 'tmp-profile.png');
    fs.writeFileSync(tmpFile, Buffer.concat([pngHeader]));

    const res = await request(app)
      .put(`/api/users/${userId}/profile-picture`)
      .set('Authorization', `Bearer ${token}`)
      .attach('profile_picture', tmpFile);

    // Nettoyage fichier temporaire
    if (fs.existsSync(tmpFile)) fs.unlinkSync(tmpFile);

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('profile_picture');
    expect(res.body).toHaveProperty('profile_picture_url');
  }, 20000);
});


