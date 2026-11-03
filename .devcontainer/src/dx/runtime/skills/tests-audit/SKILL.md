---
name: tests-audit
description: 'Cartographier la couverture de tests reelle d un projet entier (modules, scripts, workflows, taskfiles), identifier les zones non testees ou mal testees et les prioriser par risque, sans ecrire aucun test ; a utiliser par dx-tests avant toute completion de la suite de tests.'
---

# Audit de couverture de tests

## Quand l'utiliser

Utiliser ce skill lorsqu'il faut etablir ou verifier l'etat reel de la
couverture de tests d'un projet entier, avant d'ecrire ou de completer des
tests. Ce mode est non mutatif : il ne cree, ne modifie et ne supprime aucun
fichier. Ne pas l'utiliser pour la revue d'un diff ponctuel pendant une code
review : ce cas reste couvert par le mode `review-tests` de `dx-review`.

## Procedure

1. Identifier le perimetre reel du projet : modules, packages, scripts,
   workflows, taskfiles et points d'entree, pas uniquement les fichiers
   recemment modifies.
2. Reperer les frameworks, runners et commandes de test deja en place (par
   exemple `task test`, `task validate`, `task feature:test`) et les
   conventions de nommage et de structure existantes, plutot que d'en
   imposer de nouvelles sans justification.
3. Construire une cartographie du perimetre teste et non teste : pour chaque
   module ou script, verifier s'il existe un test du comportement nominal,
   d'un cas d'erreur ou limite, et d'une non-regression pour tout bug connu.
4. Prioriser les lacunes selon le risque reel (chemin critique, comportement
   public, script invoque en CI ou par des consommateurs) plutot que de
   viser une couverture uniforme sans discernement.
5. Arreter l'analyse des qu'une cartographie exploitable et une liste de
   lacunes priorisees sont etablies ; laisser l'ecriture des tests au skill
   `tests-complete`.

## Contraintes

- Ne modifier, creer ni supprimer aucun fichier pendant cet audit.
- Ne pas se limiter au diff en cours ; parcourir le perimetre pertinent du
  projet pour reperer les angles morts de couverture.
- Ne pas presumer d'une lacune sans verifier l'absence reelle du test
  correspondant.
- Ne pas imposer un nouveau framework ou outil de test a ce stade ; se
  limiter a constater l'existant.

## Sortie attendue

Cartographie des zones testees et non testees avec leur niveau de risque,
liste des lacunes priorisees avec leur justification, et outils/conventions
de test deja en place a reutiliser pour la completion.
