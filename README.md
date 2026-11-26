# dx

Catalogue documentaire des projets qui composent l'environnement de
developpement partage de Gildraen. Ce depot ne publie pas de Feature, d'outil,
 de Taskfile ni de workflow reutilisable.

## Projets

| Projet | Responsabilite |
| --- | --- |
| [dx-dev-feature](https://github.com/Gildraen/dx-dev-feature) | Source, tests et publication de la Dev Container Feature `dx`. |
| [dx-agents](https://github.com/Gildraen/dx-agents) | Instructions, roles et skills partages. |
| [dx-tools](https://github.com/Gildraen/dx-tools) | Outils et Taskfiles partages, dont le lanceur MCP GitHub. |
| [ci-workflows](https://github.com/Gildraen/ci-workflows) | Workflows GitHub Actions reutilisables. |
| [renovate-config](https://github.com/Gildraen/renovate-config) | Preset Renovate partage. |

Voir la [carte des responsabilites](docs/components.md) et la [transition de
publication](docs/transition.md).

## Transition

La source de la Feature a ete transferee vers `dx-dev-feature`; le transfert de
sa publication GHCR reste a terminer. D'ici la, ne deduis pas la disponibilite
d'un nouvel artefact de la seule fusion du code. Les consommateurs connus sont
`dx-agents` et `renovate-config`; leurs references restent inchangees jusqu'a
la verification de la nouvelle publication.
