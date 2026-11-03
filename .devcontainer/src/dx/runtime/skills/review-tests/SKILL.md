---
name: review-tests
description: Revue de la couverture et de la qualite des tests, a utiliser pour tout changement qui ajoute ou modifie un comportement testable.
---

# Revue tests

## Quand l'utiliser

Changement qui ajoute, modifie ou corrige un comportement observable
(fonction, endpoint, regle metier, script).

## Checklist

- Le comportement nominal et au moins un cas d'erreur/limite sont couverts
  par un test.
- Un bug corrige est accompagne d'un test qui aurait echoue avant le
  correctif (test de non-regression).
- Les tests verifient un comportement, pas un detail d'implementation
  fragile.
- Les tests ajoutes/modifies passent localement (`task test` ou equivalent
  du repository) avant publication.
- Pas de test desactive, skippe ou affaibli silencieusement pour faire
  passer la CI.

## Sortie attendue

Liste des lacunes de couverture identifiees, avec le cas de test concret
propose pour chacune.
