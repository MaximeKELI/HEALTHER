const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { dbRun, dbGet } = require('../config/database');

/**
 * Générer un secret TOTP pour un utilisateur
 * @param {number} userId - ID utilisateur
 * @param {string} username - Nom d'utilisateur
 * @returns {Promise<Object>} - Secret et URL QR code
 */
async function generateTOTPSecret(userId, username) {
  const secret = speakeasy.generateSecret({
    name: `M.A.D.E (${username})`,
    issuer: 'M.A.D.E Health',
    length: 32,
  });
  
  // Générer des backup codes (10 codes à 8 chiffres)
  const backupCodes = Array.from({ length: 10 }, () => 
    Math.floor(10000000 + Math.random() * 90000000).toString()
  ).map(code => ({
    code,
    used: false,
  }));
  
  // Sauvegarder le secret et backup codes
  await dbRun(
    `UPDATE users SET 
      totp_secret = ?,
      totp_backup_codes = ?,
      totp_enabled = 0
    WHERE id = ?`,
    [secret.base32, JSON.stringify(backupCodes), userId]
  );
  
  // Générer le QR code
  const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);
  
  return {
    secret: secret.base32,
    qrCodeUrl,
    backupCodes: backupCodes.map(b => b.code),
  };
}

/**
 * Vérifier un code TOTP
 * @param {number} userId - ID utilisateur
 * @param {string} token - Code TOTP à vérifier
 * @returns {Promise<boolean>} - True si valide
 */
async function verifyTOTP(userId, token) {
  const user = await dbGet('SELECT totp_secret, totp_enabled, totp_backup_codes FROM users WHERE id = ?', [userId]);
  
  if (!user || !user.totp_enabled || !user.totp_secret) {
    return false;
  }
  
  // Vérifier le code TOTP
  const verified = speakeasy.totp.verify({
    secret: user.totp_secret,
    encoding: 'base32',
    token,
    window: 2, // Accepter ±2 périodes (60s chacune)
  });
  
  if (verified) {
    return true;
  }
  
  // Si TOTP échoue, vérifier les backup codes
  if (user.totp_backup_codes) {
    const backupCodes = JSON.parse(user.totp_backup_codes);
    const codeIndex = backupCodes.findIndex(bc => !bc.used && bc.code === token);
    
    if (codeIndex !== -1) {
      // Marquer le backup code comme utilisé
      backupCodes[codeIndex].used = true;
      await dbRun('UPDATE users SET totp_backup_codes = ? WHERE id = ?', [JSON.stringify(backupCodes), userId]);
      return true;
    }
  }
  
  return false;
}

/**
 * Activer 2FA pour un utilisateur
 * @param {number} userId - ID utilisateur
 * @param {string} token - Code TOTP pour confirmer
 * @returns {Promise<boolean>} - True si activé
 */
async function enable2FA(userId, token) {
  const verified = await verifyTOTP(userId, token);
  
  if (verified) {
    await dbRun('UPDATE users SET totp_enabled = 1 WHERE id = ?', [userId]);
    return true;
  }
  
  return false;
}

/**
 * Désactiver 2FA pour un utilisateur
 * @param {number} userId - ID utilisateur
 * @returns {Promise<void>}
 */
async function disable2FA(userId) {
  await dbRun(
    `UPDATE users SET 
      totp_secret = NULL,
      totp_backup_codes = NULL,
      totp_enabled = 0
    WHERE id = ?`,
    [userId]
  );
}

module.exports = {
  generateTOTPSecret,
  verifyTOTP,
  enable2FA,
  disable2FA,
};
