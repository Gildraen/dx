---
name: contribution-maintenance
description: 'Inventorier, mettre en pause, reprendre ou nettoyer des branches et worktrees Git en conservant les edits, stashes et commits uniques avant une suppression autorisee.'
---

# Conservation et nettoyage

Role proprietaire : [contribution](../../agents/contribution.agent.md).

## Entrees et limites

Preciser le depot, les branches et worktrees concernees, puis l'operation :
pause, reprise ou nettoyage. Un inventaire seul ne retire aucune reference.
Les tags, stashes, fichiers utilisateur et autres taches restent hors du
nettoyage de branches sauf mandat distinct.

## Mise en pause

1. Examiner les edits indexes, non indexes, non suivis et ignores dans la
   worktree, ainsi que les commits propres a la branche. Determiner ce qui
   doit etre conserve et ce qui peut etre retire.
2. Choisir une sauvegarde adaptee au contenu. Un stash nomme peut conserver
   les edits Git et les fichiers non suivis retenus, mais pas les fichiers
   ignores ; un bundle conserve les commits et references, pas les edits du
   checkout. Ne pas placer de secrets dans une sauvegarde Git.
3. Verifier la sauvegarde avant tout retrait : contenu attendu, lisibilite,
   emplacement et identifiant stable. Conserver le SHA du stash plutot qu'un
   indice qui changera avec les prochaines sauvegardes.
4. Retirer uniquement la worktree devenue propre et la branche dont le
   retrait est autorise. Signaler les contenus non sauvegardes et s'arreter
   plutot que forcer leur suppression.

## Reprise

1. Verifier si le travail sauvegarde est deja integre : etat et SHA de la PR,
   contenu ou equivalence du patch, notamment apres un squash. Ne pas reappliquer
   automatiquement une sauvegarde dont le travail est deja present.
2. Pour le travail restant, preparer une worktree sur la base appropriee et
   appliquer la sauvegarde par son identifiant stable sans la supprimer.
3. Inspecter le diff et les conflits, puis executer les checks utiles avant
   de poursuivre. En cas de conflit, conserver les deux versions et la
   sauvegarde pour une resolution explicite.

## Nettoyage

1. Rapprocher l'inventaire local des branches distantes actuelles et des PR.
   Confirmer le SHA a retirer, pas seulement le nom d'une PR ancienne : une
   branche peut avoir recu du travail apres son merge.
2. Pour chaque candidat, distinguer travail integre, travail unique abandonne
   explicitement et travail encore actif. Une PR fermee ne prouve pas un merge.
   Pour une integration par squash, verifier la PR au SHA concerne ou le patch.
   Conserver une sauvegarde verifiee des commits uniques avant leur retrait.
3. Verifier les fichiers locaux avant de retirer une worktree. Si son chemin
   est inaccessible, ne pas la declarer propre : limiter un retrait autorise
   a son enregistrement Git obsolete, sans supprimer des fichiers sur un
   emplacement non inspectable.
4. Supprimer uniquement les references autorisees, jamais la branche cible
   principale. Proteger les suppressions distantes par leurs SHA attendus ;
   une modification concurrente exige une nouvelle decision. Un rejet de
   suppression locale apres squash exige une preuve d'integration ou une
   sauvegarde, pas une suppression forcee par reflexe.
5. Nettoyer les references de suivi obsoletes et verifier l'inventaire final,
   les edits conserves et les sauvegardes. Ne pas supprimer les stashes ou
   expirer les sauvegardes pour obtenir artificiellement un depot propre.

## Resultat

Lister ce qui a ete retire, ce qui reste actif et les contenus preserves.
Donner les identifiants et emplacements de reprise, avec toute limite de
verification, notamment une worktree inaccessible ou une sauvegarde incomplete.