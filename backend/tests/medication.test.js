/**
 * Tests pour Medication Service
 */

const medicationService = require('../services/medication_service');

describe('Medication Service', () => {
  test('should search drug in OpenFDA', async () => {
    const result = await medicationService.searchDrugOpenFDA('aspirin');
    expect(result).toHaveProperty('success');
  }, 10000);

  test('should normalize drug name with RxNorm', async () => {
    const result = await medicationService.normalizeDrugNameRxNorm('aspirin');
    expect(result).toHaveProperty('success');
  }, 10000);

  test('should check drug interactions', async () => {
    const result = await medicationService.checkDrugInteractions(['aspirin', 'warfarin']);
    expect(result).toHaveProperty('hasInteractions');
  }, 15000);
});

