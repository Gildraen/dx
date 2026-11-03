---
name: improve-skill
description: Workflow pour auditer et ameliorer un ou plusieurs skills pour clients IA compatibles, verifier leur pertinence, reduire leur ambiguite et valider leur chargement.
---

# Amelioration de skill

## Quand l'utiliser

Utiliser ce skill lorsqu'un skill existant doit etre relu, corrige, rendu plus
precis ou audite avec tous les skills d'un repertoire ou du runtime.

## Procedure

1. Definir le perimetre : skill nomme, skills d'un dossier, skills partages du
   runtime ou skills du projet. Ne pas elargir le perimetre sans le signaler.
2. Lire chaque SKILL.md en entier ainsi que ses references, scripts, assets et
   les agents qui l'utilisent.
3. Pour chaque skill, verifier :
   - pertinence de la procedure par rapport a son usage reel ;
   - description et mots-cles de decouverte, presence du "quand l'utiliser" ;
   - nom du dossier identique au champ `name` du frontmatter ;
   - format Agent Skills avec `name` et `description`, sans API client imposee ;
   - absence de responsabilites qui devraient appartenir a une instruction,
     un agent ou un prompt ;
   - taille du SKILL.md et chargement progressif (detail volumineux
     externalise en reference/script/asset) ;
   - chemins relatifs corrects vers les ressources ;
   - doublons ou chevauchement avec d'autres skills ;
    - liens, chemins de chargement et tests concernes, sans garantie de
       decouverte native.
4. Classer chaque constat : confirme, amelioration utile, non pertinent,
   ambigu ou hors perimetre. Ne jamais modifier un skill uniquement parce
   qu'il pourrait etre formule autrement.
5. Pour chaque modification proposee, expliquer le probleme observe, le
   comportement vise et le risque de regression. Preferer la plus petite
   modification qui augmente precision, pertinence ou decouvrabilite.
6. Appliquer les ameliorations confirmees, puis relire le skill complet et ses
   references. Mettre a jour les tests ou la documentation si le contrat
   partage change.
7. Executer les validations disponibles et signaler les comportements qui ne
   peuvent pas etre verifies automatiquement.

## Principes de challenge

- Une demande d'amelioration n'est pas une preuve qu'un skill est deficient.
- Une regle toujours applicable ne doit pas rester un skill pour la rendre
  plus visible ; elle appartient a une instruction.
- Une reformulation stylistique ne justifie pas une modification sans gain
  concret de decouverte, clarte ou maintenabilite.
- Un skill doit couvrir une seule tache repetable avec une procedure claire.
- Conserver le comportement existant lorsque le gain n'est pas demontre.

## Sortie attendue

Pour chaque skill audite :

- verdict de pertinence ;
- constats verifies et preuves ;
- changements appliques ou refuses, avec justification ;
- validations executees et resultat ;
- risques residuels et prochaines actions eventuelles.

Terminer par une synthese des skills ameliores, conserves sans changement et
candidats a une refonte ou une suppression.
