# Transfert de publication

Cette note suit la transition de la Feature depuis `Gildraen/dx` vers
[`Gildraen/dx-dev-feature`](https://github.com/Gildraen/dx-dev-feature). Elle
est temporaire et devra être retirée une fois le transfert vérifié.

## État

- La nouvelle source conserve l'identifiant Feature et le namespace OCI
  historiques.
- Le dépôt `dx` ne doit plus publier cette Feature après la conversion en
  catalogue.
- La nouvelle source est fusionnée, mais une fusion ne prouve pas qu'un nouvel
  artefact a été publié ni qu'il est accessible anonymement.
- Les consommateurs connus restent `dx-agents` et `renovate-config`; leur
  configuration doit rester intacte jusqu'à la vérification du nouvel artefact.

## Étapes de transfert

1. Retirer l'ancien workflow de publication du dépôt `dx`.
2. Vérifier que `dx-dev-feature` a le rôle **Write** sur les packages existants
   via **Manage Actions access**. Ne pas créer un package concurrent sous un
   autre chemin sans décision explicite.
3. Configurer l'application Release Please dans `dx-dev-feature`, puis activer
   sa garde de publication seulement après la désactivation de l'ancien
   publisher et la vérification des permissions.
4. Publier depuis le nouveau dépôt et vérifier le pull anonyme du tag attendu.
5. Après cette preuve, mettre à jour les lockfiles des consommateurs connus et
   reconstruire leurs conteneurs. Garder les anciens artefacts GHCR tant que
   des consommateurs les référencent.

## Anciens wrappers GitHub Actions

Les chemins `Gildraen/dx/.github/workflows/reusable-validate.yml`,
`reusable-devcontainer-test.yml` et `reusable-maintenance.yml` ne sont plus
maintenus ici. Les consommateurs doivent appeler directement le workflow
correspondant de `Gildraen/ci-workflows`, épinglé par SHA avec son tag dans un
commentaire Renovate. `reusable-feature-test.yml` n'a pas d'équivalent
générique; son test reste dans le dépôt `dx-dev-feature`.

Aucun appelant interne aux trois wrappers génériques n'a été trouvé lors du
recensement. L'ancien workflow `validate.yml` appelait le wrapper de test
Feature; ce test est désormais détenu par `dx-dev-feature`. Les usages externes
publics des anciens chemins n'ont pas pu être exhaustivement vérifiés.

Le statut de chaque étape doit être confirmé dans le dépôt propriétaire; cette
note ne remplace ni les checks de publication ni les vérifications GHCR.