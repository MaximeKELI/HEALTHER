#!/bin/bash
# Script pour capturer les erreurs Flutter de manière concise

cd /home/maxime/HEALTHER/healther

echo "🔍 Analyse du code - erreurs uniquement:"
flutter analyze 2>&1 | grep -E "^\s*error" | head -20

echo ""
echo "✅ Aucune erreur trouvée" || echo "❌ Erreurs détectées ci-dessus"

