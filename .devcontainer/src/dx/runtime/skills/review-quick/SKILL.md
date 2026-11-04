---
name: review-quick
description: Revue de code rapide et generale (lisibilite, style, evidences), utilisee par defaut par l'agent de review.
---

# Revue rapide

## Quand l'utiliser

Mode par defaut pour tout changement, sans risque particulier identifie.

## Checklist

- Le diff correspond exactement a l'intention annoncee, rien d'accidentel
  (fichiers oublies, code de debug, commentaires morts).
- Noms, structure et style coherents avec le reste du fichier/module.
- Pas de duplication evidente evitable avec le code existant a proximite.
- Erreurs et cas limites evidents geres, ou explicitement hors scope.
- Les commandes de validation disponibles (`task validate`, `task test`,
  lint) sont executees, ou leur absence est justifiee.

## Sortie attendue

Liste courte des findings avec fichier/ligne, ou confirmation explicite
qu'aucun probleme bloquant n'a ete trouve.
