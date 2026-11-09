---
name: contribution-publish
description: 'Publier une contribution Git sur GitHub, ouvrir ou reprendre sa PR, suivre la CI et effectuer un merge autorise apres verification du commit et des checks.'
---

# Publication de contribution

Role proprietaire : [contribution](../../agents/contribution.agent.md).

## Entrees et limites

Partir du depot, de la worktree, du diff retenu, de la branche cible et du
mandat : commit, push, ouverture de PR, suivi ou merge. Ne pas ajouter de
tag, de workflow de release ou de nettoyage au mandat de publication.

## Procedure

1. Verifier le diff complet et les dependencies de la contribution. Comparer
   la base au distant actuel. Une avance rapide compatible avec les edits
   locaux peut conserver le travail ; en cas de divergence ou conflit,
   s'arreter pour etablir la strategie au lieu de reinitialiser le checkout.
2. Obtenir la revue et executer les checks appropries du depot avant la
   publication. Un echec, un finding non resolu ou un check indisponible doit
   etre signale ; ne pas fabriquer une CI verte en ignorant une suite.
3. Si le mandat le couvre, indexer seulement les fichiers retenus, verifier
   le diff indexe, committer puis pousser la branche. Confirmer le SHA distant
   et les changements locaux qui restent hors commit.
4. Chercher une PR existante pour le meme depot, la meme branche source et la
   meme cible avant d'en ouvrir une. Decrire le perimetre, les checks executes,
   leurs limites et les dependances de publication ; ne pas clore une issue
   dont le travail depasse ce diff.
5. Suivre la CI sur le SHA de la PR avec le watcher natif du client en sortie
   non interactive. Verifier les conclusions finales, pas seulement le retour
   de la commande ou l'absence de sortie. En cas d'echec, relever le check et
   les logs utiles sans relancer aveuglement ni exposer de secrets.
6. Si le merge est autorise, verifier la cible, l'absence de conflit et la
   reussite des checks attendus sur le commit courant. Utiliser le SHA attendu
   pour proteger l'integration contre une modification concurrente. Une PR
   modifiee ou une CI encore en cours impose une nouvelle verification.
7. Confirmer l'etat fusionne et le contenu ou contrat disponible sur la
   branche cible. Synchroniser les checkouts concernes sans perdre leurs
   edits locaux. Signaler les conflits et laisser le travail intact plutot
   que forcer la synchronisation.

## Condition d'arret et resultat

Terminer a l'etape autorisee : branche poussee, PR ouverte, checks termines ou
merge confirme. Donner les SHA, le lien de PR, les checks et leurs conclusions,
les modifications non publiees et les limites restantes. Un merge ne prouve
pas a lui seul qu'un artefact a ete publie ou qu'un consommateur a ete migre.