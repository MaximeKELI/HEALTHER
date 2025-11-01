/**
 * Service d'intégration FHIR/HL7
 * Placeholder pour intégration avec systèmes de laboratoire
 */

/**
 * Convertir un diagnostic en Observation FHIR
 * @param {Object} diagnostic - Diagnostic à convertir
 * @returns {Object} - Observation FHIR
 */
function diagnosticToFHIR(diagnostic) {
  return {
    resourceType: 'Observation',
    id: `diagnostic-${diagnostic.id}`,
    status: 'final',
    category: [
      {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/observation-category',
            code: 'laboratory',
            display: 'Laboratory',
          },
        ],
      },
    ],
    code: {
      coding: [
        {
          system: 'http://loinc.org',
          code: diagnostic.maladie_type === 'paludisme' ? '664-3' : '664-3', // TODO: Codes LOINC appropriés
          display: diagnostic.maladie_type === 'paludisme' ? 'Malaria' : diagnostic.maladie_type,
        },
      ],
    },
    subject: {
      reference: `Patient/${diagnostic.user_id}`,
    },
    effectiveDateTime: diagnostic.created_at,
    valueString: diagnostic.statut,
    interpretation: [
      {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
            code: diagnostic.statut === 'positif' ? 'POS' : 'NEG',
            display: diagnostic.statut === 'positif' ? 'Positive' : 'Negative',
          },
        ],
      },
    ],
    note: diagnostic.commentaires ? [{ text: diagnostic.commentaires }] : [],
  };
}

/**
 * Convertir un échantillon en Specimen FHIR
 * @param {Object} sample - Échantillon à convertir
 * @returns {Object} - Specimen FHIR
 */
function sampleToFHIR(sample) {
  return {
    resourceType: 'Specimen',
    id: `sample-${sample.id}`,
    identifier: [
      {
        system: 'http://made.health/specimen',
        value: sample.barcode || sample.id.toString(),
      },
    ],
    status: 'available',
    type: {
      coding: [
        {
          system: 'http://snomed.info/sct',
          code: sample.sample_type || '119297000', // Blood specimen
          display: sample.sample_type || 'Blood specimen',
        },
      ],
    },
    collection: {
      collectedDateTime: sample.collection_date || new Date().toISOString(),
    },
    receivedTime: sample.received_date || new Date().toISOString(),
  };
}

/**
 * Envoyer une Observation FHIR à un endpoint
 * @param {string} endpoint - URL du endpoint FHIR
 * @param {Object} observation - Observation FHIR
 * @param {string} apiKey - Clé API (si requise)
 * @returns {Promise<Object>} - Réponse du serveur FHIR
 */
async function sendFHIRObservation(endpoint, observation, apiKey = null) {
  const http = require('http');
  const https = require('https');
  const url = require('url');
  
  const parsedUrl = new url.URL(endpoint);
  const isHttps = parsedUrl.protocol === 'https:';
  const client = isHttps ? https : http;
  
  return new Promise((resolve, reject) => {
    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (isHttps ? 443 : 80),
      path: parsedUrl.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/fhir+json',
        'Accept': 'application/fhir+json',
      },
    };
    
    if (apiKey) {
      options.headers['Authorization'] = `Bearer ${apiKey}`;
    }
    
    const req = client.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`FHIR Error: ${res.statusCode} - ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(JSON.stringify(observation));
    req.end();
  });
}

module.exports = {
  diagnosticToFHIR,
  sampleToFHIR,
  sendFHIRObservation,
};
