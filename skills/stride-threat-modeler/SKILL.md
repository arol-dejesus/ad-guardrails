---
name: stride-threat-modeler
description: Analyse l'architecture logicielle et produit une matrice formelle STRIDE avec contre-mesures associées.
---

# Méthodologie STRIDE pour Claude

Pour toute architecture ou API examinée :
1. **S - Spoofing (Usurpation d'identité)** : Les tokens et sessions peuvent-ils être falsifiés ?
2. **T - Tampering (Altération des données)** : Les requêtes ou payloads en transit peuvent-ils être modifiés sans détection (HMAC, signatures) ?
3. **R - Repudiation (Répudiation)** : Existe-t-il des logs immuables et auditables pour toutes les actions critiques ?
4. **I - Information Disclosure (Divulgation d'informations)** : Des données sensibles ou des stack traces fuitent-elles dans les réponses d'erreur ?
5. **D - Denial of Service (Déni de service)** : Les endpoints sont-ils protégés par du rate-limiting et des timeouts ?
6. **E - Elevation of Privilege (Élévation de privilèges)** : Un utilisateur simple peut-il passer en rôle administrateur par modification de payload JSON ?
