# Responsabilités des projets DX

Chaque dépôt est propriétaire de son code, de son cycle de vie et de sa
publication. `Gildraen/dx` fournit uniquement cette carte documentaire.

| Dépôt | Responsabilité | Consommation |
| --- | --- | --- |
| [dx-dev-feature](https://github.com/Gildraen/dx-dev-feature) | Assemblage et publication de la Dev Container Feature `dx`; télécharge les snapshots des sources agents et outils. | Référence Feature OCI, après publication. |
| [dx-agents](https://github.com/Gildraen/dx-agents) | Source canonique des instructions, rôles et skills partagés. | Plugin ou checkout selon le consommateur. |
| [dx-tools](https://github.com/Gildraen/dx-tools) | Source canonique des outils et Taskfiles partagés. | Commandes et includes Taskfile choisis par le consommateur. |
| [ci-workflows](https://github.com/Gildraen/ci-workflows) | Workflows GitHub Actions réutilisables. | Appels versionnés par les dépôts consommateurs. |
| [renovate-config](https://github.com/Gildraen/renovate-config) | Preset de dépendances et gestionnaires personnalisés Renovate. | Configuration Renovate des dépôts. |

## Relations

La Feature est un assemblage, pas la source des agents ou des outils. Elle
installe des snapshots versionnés de `dx-agents` et `dx-tools`; les dépôts
consommateurs choisissent séparément leurs workflows et dépendances Renovate.
Une modification dans un dépôt propriétaire doit y être publiée avant que les
consommateurs puissent la sélectionner.

## Consommateurs connus

`dx-agents` et `renovate-config` consomment actuellement la Feature. Le
transfert de son code vers `dx-dev-feature` ne change pas à lui seul un pin
consommateur ni ne prouve qu'un nouvel artefact GHCR a été publié. Voir la
[note de transition](transition.md).