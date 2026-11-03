---
name: improve-agent
description: Workflow pour auditer et ameliorer un ou plusieurs agents pour clients IA compatibles, verifier leur pertinence, reduire leur ambiguite et valider leur comportement.
---

# Amelioration d'agent

## Quand l'utiliser

Utiliser ce skill lorsqu'un agent existant doit etre relu, corrige, rendu plus
precis ou audite avec tous les agents d'un repertoire ou du runtime.

## Procedure

1. Definir le perimetre : agent nomme, agents d'un dossier, agents partages du
   runtime ou agents du projet. Ne pas elargir le perimetre sans le signaler.
2. Lire chaque agent en entier ainsi que ses skills, instructions, delegations,
   tests et references directement lies.
3. Pour chaque agent, verifier :
   - pertinence du role par rapport a son usage reel ;
   - description et mots-cles de decouverte ;
   - frontmatter neutre limite a `name` et `description` ;
   - absence de responsabilites qui devraient appartenir a une instruction,
     un skill ou un prompt ;
   - limites, outils, delegations et risques de boucle ;
   - clarté de la methode, des criteres de decision et de la sortie attendue ;
   - doublons ou contradictions avec d'autres agents ;
   - liens, chemins de chargement et tests, sans garantie de decouverte native.
4. Classer chaque constat : confirme, amelioration utile, non pertinent,
   ambigu ou hors perimetre. Ne jamais modifier un agent uniquement parce
   qu'il pourrait etre formule autrement.
5. Pour chaque modification proposee, expliquer le probleme observe, le
   comportement vise et le risque de regression. Preferer la plus petite
   modification qui augmente precision, pertinence ou efficacité.
6. Appliquer les ameliorations confirmees, puis relire l'agent complet et ses
   references. Mettre a jour les tests ou la documentation si le contrat
   change.
7. Executer les validations disponibles et signaler les comportements qui ne
   peuvent pas etre verifies automatiquement.

## Principes de challenge

- Une demande d'amelioration n'est pas une preuve qu'un agent est deficient.
- Une instruction generale ne doit pas etre transformee en agent pour la
  rendre plus visible.
- Une reformulation stylistique ne justifie pas une modification sans gain
  concret de decouverte, decision, securite ou maintenabilite.
- Un agent doit avoir un seul role principal et des frontieres explicites.
- Conserver le comportement existant lorsque le gain n'est pas demontre.

## Sortie attendue

Pour chaque agent audite :

- verdict de pertinence ;
- constats verifies et preuves ;
- changements appliques ou refuses, avec justification ;
- validations executees et resultat ;
- risques residuels et prochaines actions eventuelles.

Terminer par une synthese des agents ameliores, conserves sans changement et
candidats a une refonte ou une suppression.
