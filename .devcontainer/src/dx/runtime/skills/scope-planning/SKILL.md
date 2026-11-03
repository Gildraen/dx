---
name: scope-planning
description: 'Planifier une intervention après analyse : comparer les options, poser les questions nécessaires et décider d une action sans l exécuter.'
---

# Scope planning

## Quand l'utiliser

Utiliser ce skill après `scope-analysis`, lorsqu'une demande nécessite un choix
d'architecture, une clarification des exigences ou un plan avant modification.
Ce mode est non mutatif : il prépare une décision mais n'exécute aucun
changement.

## Procedure

1. Partir uniquement des faits vérifiés par l'analyse de périmètre et lister
   les inconnues qui peuvent changer la solution.
2. Définir au plus trois options réalistes, dont l'option de ne rien changer
   lorsque le besoin n'est pas démontré.
3. Comparer chaque option selon le gain attendu, le coût, le couplage, la
   compatibilité, les risques, la testabilité et la réversibilité.
4. Choisir l'option proportionnée au problème ; préférer la plus petite
   modification qui traite la cause et respecte les contrats.
5. Poser uniquement les questions bloquantes, avec le contexte nécessaire et
   une conséquence claire pour chaque réponse.
6. Définir un plan séquencé : fichiers ou composants, tests, documentation,
   migration et condition d'arrêt.
7. Attendre la décision ou les réponses de l'utilisateur avant toute édition.

## Contraintes

- Ne modifier aucun fichier et ne lancer aucune migration pendant ce mode.
- Ne pas présenter une préférence comme une décision validée.
- Ne pas multiplier les options théoriques sans différence concrète.
- Ne pas planifier de compatibilité ou d'abstraction sans consommateur ou
  risque qui le justifie.

## Sortie attendue

Présenter :

- périmètre retenu et hypothèses ;
- options comparées et compromis ;
- recommandation argumentée ;
- questions bloquantes, s'il y en a ;
- plan d'implémentation et validations prévues ;
- décision attendue de l'utilisateur avant modification.
