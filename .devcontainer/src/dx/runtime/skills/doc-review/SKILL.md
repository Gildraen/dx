---
name: doc-review
description: 'Relire et auditer un document Markdown existant (README, guide, reference) pour signaler les informations fausses, obsoletes, ambigues ou incompletes ; utilise par l''agent de documentation pour toute relecture sans intention de reecrire.'
---

# Relecture de documentation

## Quand l'utiliser

Utiliser ce skill pour auditer un document Markdown existant : verifier son
exactitude, sa completude et sa clarte sans le reecrire soi-meme.

Ne pas l'utiliser pour creer ou restructurer un document ; utiliser
`doc-write` pour cela, en s'appuyant eventuellement sur les findings produits
ici. Ne pas l'utiliser pour une revue de code, de conception ou de securite.

## Procedure

1. Identifier le public vise et l'objectif annonce ou implicite du document.
2. Lire les fichiers sources, scripts, configurations, tests et documents
   voisins necessaires pour verifier chaque affirmation du document.
3. Relever en priorite les informations fausses, incompletes, ambigues,
   obsoletes ou impossibles a suivre, chacune avec une preuve (fichier,
   commande ou comportement observe) et une correction proposee.
4. Verifier les liens relatifs, les commandes, les chemins, les noms
   d'options et les exemples ; signaler ceux qui sont casses ou perimes.
5. Verifier la coherence avec les documents voisins et les conventions
   documentaires locales lorsque le document appartient a un ensemble
   partage.
6. Distinguer les problemes bloquants (information fausse ou dangereuse) des
   ameliorations souhaitables (clarte, structure) sans les confondre.
7. Ne pas appliquer de correctif ; transmettre les findings pour une decision
   ou un passage a `doc-write`, sauf demande explicite de correction directe.

## Criteres de qualite

- Chaque finding cite une preuve verifiable, pas une impression.
- Les findings sont classes par severite, du plus bloquant au plus mineur.
- Les points positifs et les limites non couvertes par la revue sont
  signales, pas seulement les problemes.
- Aucune supposition ne comble un point non verifiable ; il est signale comme
  tel.

## Sortie attendue

Liste des findings par severite avec preuve et correction proposee, suivie
des points positifs et des limites restantes de la revue.
