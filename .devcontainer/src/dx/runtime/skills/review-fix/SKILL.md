---
name: review-fix
description: Verifier, challenger et corriger les findings d'une revue de code avec une preuve independante avant tout correctif.
---

# Revue - correction des findings

## Quand l'utiliser

Utiliser ce skill apres une revue (`review-quick`, `review-security`,
`review-architecture`, `review-performance` ou `review-tests`) lorsque les
findings produits doivent etre verifies puis corriges. Ne jamais considerer un
finding comme vrai par principe : sa validite doit venir du code, des
contrats, des tests et du comportement observable.

## Procedure

1. Recuperer le diff, le finding complet, son fichier, sa ligne, sa severite,
   son impact et les hypotheses qui le soutiennent.
2. Reproduire ou verifier le chemin concerne dans le code et ses appelants,
   puis consulter les tests, la configuration et la documentation utiles.
3. Classer le finding : confirme, partiellement confirme, non reproduit,
   ambigu ou hors perimetre. Expliquer les elements qui justifient ce choix.
4. Challenger explicitement le finding quand son niveau de severite, sa cause,
   sa portee ou sa preuve ne tient pas. Ne pas fabriquer de correctif pour un
   probleme non etabli.
5. Pour un finding confirme, appliquer le plus petit correctif qui traite la
   cause racine, puis ajouter ou ajuster un test quand le comportement le
   permet.
6. Executer le test le plus proche du changement, puis les validations du
   depot disponibles. Reexaminer les effets de bord et les findings connexes.

## Contraintes

- Ne jamais accepter un finding uniquement parce qu'il vient d'une revue ou
  d'un reviewer.
- Ne jamais rejeter un finding sans verifier le chemin de code concerne et
  fournir une raison falsifiable.
- Distinguer un bug, un risque theorique, une amelioration de qualite et un
  desaccord de style.
- Preserver l'intention du changement et eviter les refontes hors sujet.
- Ne pas masquer un finding confirme en baissant sa severite.

## Sortie attendue

Pour chaque finding :

- verdict : confirme, partiellement confirme, non reproduit, ambigu ou hors
  perimetre ;
- preuves verifiees, avec fichier et ligne lorsque possible ;
- decision : correctif applique, correctif propose ou aucune modification ;
- validations executees et resultat ;
- risques residuels ou question ouverte.

Terminer par une synthese des findings corriges, rejetes ou restant a traiter.
