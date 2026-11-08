# Composants DX

Reference pour les mainteneurs et les consommateurs : responsabilites,
dependances et interfaces des composants fournis ou integres par ce depot.
L'[architecture](architecture.md) decrit leur integration et le chargement
du runtime ; le [guide consommateur](consumer.md) decrit le bootstrap local.

## Sources et distribution

Les sources de la Feature, du runtime et du Taskfile distant sont dans
`Gildraen/dx`. Les workflows CI portables sont dans
[Gildraen/ci-workflows](https://github.com/Gildraen/ci-workflows/blob/v1.0.0/README.md).
La Feature distribue un snapshot du runtime par OCI sous
`ghcr.io/gildraen/dx/dx`. Les workflows et le Taskfile distant sont consommes
par references Git.
La version OCI et les refs Git sont choisies independamment.

Le [workflow de publication](../.github/workflows/release.yml) est declenche
sur `main`. Son job unique a deux etapes : checkout de `github.sha`, puis
action Dev Containers epinglee par SHA avec la CLI `0.88.0`.
La version du [manifeste](../.devcontainer/src/dx/devcontainer-feature.json)
identifie l'artefact OCI ; la CLI gere les aliases de version. `generate-docs: false` et
`disable-repo-tagging: true` limitent cette livraison a la Feature.
Ce workflow ne cree pas de references Git pour les autres composants.

## Responsabilites et interfaces

| Composant | Responsabilite | Dependances et interface actuelles |
| --- | --- | --- |
| [Feature](../.devcontainer/src/dx/devcontainer-feature.json) et [installer](../.devcontainer/src/dx/install.sh) | Installer les outils et le runtime | Features tierces, copie vers `/opt/dx`, `DX_HOME`, `GH_CONFIG_DIR`, bind mount et reglages VS Code |
| [Entree IA](../.devcontainer/src/dx/runtime/AGENTS.md) | Charger les regles et orienter vers roles et skills | Bootstrap racine, `DX_HOME`, liens relatifs et metadonnees ; roles `*.agent.md`, skills `*/SKILL.md` |
| [Lanceur MCP](../.devcontainer/src/dx/runtime/bin/dx-mcp) | Lancer le serveur GitHub officiel | `dx-mcp github [server options...]`, Docker et daemon accessibles, image `v1.10.1`, callback `127.0.0.1:8085` |
| [Taskfile partage](../.devcontainer/src/dx/runtime/taskfiles/base.yml) | Exposer `doctor` et `mcp:github` | Include distant avec ref Git ; `DX_HOME` et executable `dx-mcp` pour les helpers |
| [CI validate](https://github.com/Gildraen/ci-workflows/blob/v1.0.0/.github/workflows/reusable-validate.yml) | Appeler le contrat Task `validate` ou un contrat choisi du consommateur | Référence Git indépendante ; interface décrite dans le dépôt source |
| [CI devcontainer-test](https://github.com/Gildraen/ci-workflows/blob/v1.0.0/.github/workflows/reusable-devcontainer-test.yml) | Appeler `task test` dans le conteneur consommateur | Référence Git indépendante ; aucune image poussée |
| [CI maintenance](https://github.com/Gildraen/ci-workflows/blob/v1.0.0/.github/workflows/reusable-maintenance.yml) | Appeler le contrôle de liens du dépôt consommateur | Référence Git indépendante ; interface décrite dans le dépôt source |
| [CI Feature-test](../.github/workflows/reusable-feature-test.yml) | Tester le produit Feature DX | [Script DX](../.devcontainer/test/dx/feature-test.sh) dans le checkout appelant |
| [Configuration DX](../.devcontainer/devcontainer.json), [regles racine](../AGENTS.md), [Taskfile DX](../Taskfile.yml) | Developper et verifier DX | Feature locale, runtime source, Docker-outside-of-Docker, configuration MCP et contrats du depot |

## Couplages du runtime

L'installer livre ensemble instructions, roles, skills, lanceur et Taskfile.
Les liens entre roles et skills et la hierarchie des regles reposent sur la
topologie du runtime. Le Markdown IA ne depend pas fonctionnellement de
Docker, de MCP ou de Node ; son chargement depend du bootstrap `AGENTS.md`.

Les ressources propres au projet restent dans `.agents/agents/*.agent.md`
et `.agents/skills/*/SKILL.md` a la racine du consommateur. La Feature configure
le picker VS Code pour `.agents/agents`. Le checkout DX ajoute son propre
chemin `.devcontainer/src/dx/runtime/agents` et utilise un `DX_HOME` source.
La decouverte native et les sous-agents dependent du client ; la disponibilite
des fichiers ne garantit pas leur chargement automatique.

Le wrapper installe dans `/usr/local/bin/dx-mcp` execute
`DX_HOME/bin/dx-mcp`. Sans valeur explicite, il cherche le runtime dogfood
dans `.devcontainer/.dx`, puis utilise `/opt/dx`. `doctor` applique le meme
ordre de resolution et controle l'existence du repertoire.

La Feature declare Node LTS, gh, Task `3.53.1`, Git, jq, ripgrep et libatomic1.
Elle persiste la configuration gh via `GH_CONFIG_DIR` et le bind mount de
`.devcontainer`. Les secrets et l'etat d'authentification restent hors Git.
Docker est un prerequis du lanceur, pas un outil fourni par cette Feature.

## Contrats Git et CI

Les sources des workflows CI portables sont dans `Gildraen/ci-workflows`.
Les dépôts consommateurs sélectionnent leur référence Git; les jobs opèrent
sur leur checkout et leurs contrats Task. DX conserve les appels et le workflow
Feature-test, spécifique à ce dépôt.

Le Taskfile distant selectionne une URL Git, un chemin et une ref.
Cette interface est distincte des tags OCI.

## Controles presents

| Contrat | Sources de verification |
| --- | --- |
| Hierarchie et decouverte IA | [Hierarchie](../.devcontainer/test/dx/test-runtime-hierarchy.sh), [decouverte](../.devcontainer/test/dx/test-resource-discovery.sh) |
| Resolution Task | [Doctor](../.devcontainer/test/dx/test-task-doctor.sh) |
| Lanceur MCP | [Image et arguments](../.devcontainer/test/dx/test-dx-mcp-image.sh), [resolution du runtime](../.devcontainer/test/dx/test-dx-mcp-resolution.sh) |
| Installation Feature | [Procedure Feature-test](../.devcontainer/test/dx/feature-test.sh), [test installe](../.devcontainer/test/dx/test.sh) |