# Composants DX

Reference pour les mainteneurs et les consommateurs : responsabilites,
dependances et interfaces des composants presents dans ce depot.
L'[architecture](architecture.md) decrit leur integration et le chargement
du runtime ; le [guide consommateur](consumer.md) decrit le bootstrap local.

## Sources et distribution

Les sources des composants sont dans `Gildraen/dx`. La Feature distribue un
snapshot du runtime par OCI sous `ghcr.io/gildraen/dx/dx`. Les workflows,
le Taskfile distant et le preset Renovate sont consommes par references Git.
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
| [CI validate](../.github/workflows/reusable-validate.yml) | Executer le contrat Task du consommateur | Task `3.53.1` sur le runner ; input `task-name`, defaut `validate` ; confiance Task distante pour `github.com` |
| [CI devcontainer-test](../.github/workflows/reusable-devcontainer-test.yml) | Executer `task test` dans le conteneur consommateur | `.devcontainer/devcontainer.json` et Task disponible dans ce conteneur ; aucune image poussee |
| [CI maintenance](../.github/workflows/reusable-maintenance.yml) | Verifier les liens avec lychee | Inputs `link-check-paths` et `link-check-excludes` sur le checkout appelant |
| [CI Feature-test](../.github/workflows/reusable-feature-test.yml) | Tester le produit Feature DX | [Script DX](../.devcontainer/test/dx/feature-test.sh) dans le checkout appelant |
| [Preset Renovate](../default.json) | Configurer les mises a jour partagees | Preset GitHub, regles recommandees, digests Actions, manager devcontainer et regex Task pour `Gildraen/dx` |
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

Les workflows reutilisables se trouvent directement dans `.github/workflows`.
Leurs appels selectionnent une ref Git et leurs jobs operent sur le checkout
du consommateur. Les contrats `validate`, `test` et `lint` appartiennent au
Taskfile de ce consommateur, pas aux deux helpers du Taskfile partage.
Feature-test utilise une procedure specifique a DX.

Le Taskfile distant selectionne une URL Git, un chemin et une ref. La regex
Renovate reconnait les includes `Gildraen/dx.git//...?ref=vX.Y.Z` et consulte
les tags Git via `github-tags`. Cette interface est distincte des tags OCI.

## Controles presents

| Contrat | Sources de verification |
| --- | --- |
| Hierarchie et decouverte IA | [Hierarchie](../.devcontainer/test/dx/test-runtime-hierarchy.sh), [decouverte](../.devcontainer/test/dx/test-resource-discovery.sh) |
| Resolution Task | [Doctor](../.devcontainer/test/dx/test-task-doctor.sh) |
| Lanceur MCP | [Image et arguments](../.devcontainer/test/dx/test-dx-mcp-image.sh), [resolution du runtime](../.devcontainer/test/dx/test-dx-mcp-resolution.sh) |
| Installation Feature | [Procedure Feature-test](../.devcontainer/test/dx/feature-test.sh), [test installe](../.devcontainer/test/dx/test.sh) |