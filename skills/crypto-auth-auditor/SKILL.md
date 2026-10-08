---
name: crypto-auth-auditor
description: Audit pointu des flux d'authentification, gestion des sessions et primitives cryptographiques.
---

# Checklist Crypto & Authentification

- Remplacement obligatoire de `Math.random()` par `crypto.getRandomValues()` ou `crypto.randomBytes()` pour tout identifiant de session ou token de réinitialisation.
- Cookies de session obligatoires : `httpOnly: true`, `secure: true`, `sameSite: 'strict' | 'lax'`.
- Validation stricte de l'expiration (`exp`) et de l'audience (`aud`) sur tous les tokens JWT.
- Détection des attaques par temporisation (Timing Attacks) : forcer l'usage de `crypto.timingSafeEqual` lors de la comparaison de hashes ou de signatures HMAC.
