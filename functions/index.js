const functions = require("firebase-functions");
const admin = require("firebase-admin");
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Permite obtener los usuarios que son administradores.
const uid1 = 'qnUcHYKzxZgsjUkCvDA6q1D37v92';
const uid2 = 'bZHayFSRwlQ6dkeGaSpqFmcthQf1';

// Establece custom claims para el primer usuario
admin.auth().setCustomUserClaims(uid1, { admin: true })
  .then(() => {
    console.log('Custom claims set for user', uid1);
  })
  .catch(error => {
    console.error('Error setting custom claims for user 1:', error);
  });

// Establece custom claims para el segundo usuario
admin.auth().setCustomUserClaims(uid2, { admin: true })
  .then(() => {
    console.log('Custom claims set for user', uid2);
  })
  .catch(error => {
    console.error('Error setting custom claims for user 2:', error);
  });