# Composants DX

Reference pour les mainteneurs et les consommateurs : responsabilites,
dependances et interfaces des composants fournis ou integres par ce depot.
L'[architecture](architecture.md) decrit leur integration et le chargement
du runtime ; le [guide consommateur](consumer.md) decrit le bootstrap local.

## Sources et distribution

`Gildraen/dx` porte la Feature, distribuee par OCI sous `ghcr.io/gildraen/dx/dx`.
`Gildraen/dx-agents` porte `AGENTS.md`, `instructions/`, `agents/` et `skills/` ;
`Gildraen/dx-tools` porte `bin/` et `taskfiles/` ; `Gildraen/ci-workflows`
porte les workflows portables. La Feature acquiert les refs Git agents et
tools independamment, sans copie de leurs sources versionnee dans DX.
La version OCI, les refs des composants et les refs CI sont independantes.
Les composants agents et tools utilisent le tag candidat `v0.1.0-rc.1` pour le
suivi Renovate et enregistrent les commits correspondants par SHA dans les
options Feature et les gitlinks. Les workflows CI utilisent leur SHA avec le
tag en commentaire ; le preset Renovate conserve sa reference tag native. Cette
preversion n'est pas stable. Les sous-modules enregistrent les commits resolus par gitlink,
sans champ de version independant dans `.gitmodules`.

Le [workflow de publication](../.github/workflows/release.yml) est declenche
sur `main`. Son job unique a deux etapes : checkout de `github.sha`, puis
action Dev Containers `v1.4.3` avec la CLI `0.88.0`.
La version du [manifeste](../.devcontainer/src/dx/devcontainer-feature.json)
identifie l'artefact OCI ; la CLI gere les aliases de version. `generate-docs: false` et
`disable-repo-tagging: true` limitent cette livraison a la Feature.
Ce workflow ne cree pas de references Git pour les autres composants.

## Responsabilites et interfaces

| Composant | Responsabilite | Dependances et interface actuelles |
| --- | --- | --- |
| [Feature](../.devcontainer/src/dx/devcontainer-feature.json) et [installer](../.devcontainer/src/dx/install.sh) | Installer les composants | Features tierces, paires `agentsVersion`/`agentsCommit` et `toolsVersion`/`toolsCommit`, `/opt/dx`, variables et liens de compatibilite, stockage gh |
| [Entree IA](../.devcontainer/components/agents/AGENTS.md) | Charger les regles et orienter vers roles et skills | `Gildraen/dx-agents`, bootstrap racine, `DX_AGENTS_HOME`, liens relatifs et metadonnees |
| [Lanceur MCP](../.devcontainer/components/tools/bin/dx-mcp) | Lancer le serveur GitHub officiel | `Gildraen/dx-tools`, `dx-mcp github [server options...]`, Docker et daemon accessibles, image `v1.10.1`, callback `127.0.0.1:8085` |
| [Taskfile partage](../.devcontainer/components/tools/taskfiles/base.yml) | Exposer `doctor` et `mcp:github` | `Gildraen/dx-tools`, include distant avec ref Git ; `DX_TOOLS_HOME`, repli `DX_HOME`, executable `dx-mcp` |
| CI validate : `Gildraen/ci-workflows/.github/workflows/reusable-validate.yml` | Executer le contrat Task du consommateur | Task `3.53.1` sur le runner ; input `task-name`, defaut `validate` ; confiance Task distante pour `github.com` |
| CI devcontainer-test : `Gildraen/ci-workflows/.github/workflows/reusable-devcontainer-test.yml` | Executer `task test` dans le conteneur consommateur | `.devcontainer/devcontainer.json` et Task disponible dans ce conteneur ; aucune image poussee |
| CI maintenance : `Gildraen/ci-workflows/.github/workflows/reusable-maintenance.yml` | Verifier les liens avec lychee | Inputs `link-check-paths` et `link-check-excludes` sur le checkout appelant |
| [CI Feature-test](../.github/workflows/reusable-feature-test.yml) | Tester le produit Feature DX | [Script DX](../.devcontainer/test/dx/feature-test.sh) dans le checkout appelant |
| [Configuration DX](../.devcontainer/devcontainer.json), [regles racine](../AGENTS.md), [Taskfile DX](../Taskfile.yml) | Developper et verifier DX | Feature locale, sous-modules agents et tools epingles, Docker-outside-of-Docker, MCP et contrats du depot |

## Couplages du runtime

L'installer acquiert agents et tools par deux refs distinctes.
Les liens entre roles et skills et la hierarchie des regles reposent sur la
topologie de `dx-agents`. Le Markdown IA ne depend pas fonctionnellement de
Docker, de MCP ou de Node ; son chargement depend du bootstrap `AGENTS.md`.

Les ressources propres au projet restent dans `.agents/agents/*.agent.md`
et `.agents/skills/*/SKILL.md` a la racine du consommateur. Le checkout DX utilise
`DX_AGENTS_HOME=.devcontainer/components/agents` et
`DX_TOOLS_HOME=.devcontainer/components/tools` avec des chemins absolus dans
le conteneur. `initializeCommand` lance `git submodule update --init --recursive`.
La decouverte native et les sous-agents dependent du client ; la disponibilite
des fichiers ne garantit pas leur chargement automatique.

Le wrapper installe dans `/usr/local/bin/dx-mcp` execute
`DX_TOOLS_HOME/bin/dx-mcp` ; `DX_HOME/bin/dx-mcp` reste compatible.
`doctor` controle d'abord `DX_TOOLS_HOME`, puis utilise son repli `DX_HOME`.
L'installation fixe `DX_HOME=/opt/dx`,
`DX_AGENTS_HOME=/opt/dx/components/agents` et
`DX_TOOLS_HOME=/opt/dx/components/tools`. Les six liens sous `/opt/dx` sont
`AGENTS.md`, `instructions/`, `agents/` et `skills/` vers les ressources de
`components/agents`, puis `bin/` et `taskfiles/` vers celles de `components/tools`.
`/opt/dx/agents` pointe vers `components/agents/agents`, pas vers le home du
composant ; les homes sous `components/` evitent cette collision.

La Feature declare Node LTS, gh, Task `3.53.1`, Git, jq, ripgrep et libatomic1.
Elle persiste la configuration gh via `GH_CONFIG_DIR` et le bind mount de
`.devcontainer`. Les secrets et l'etat d'authentification restent hors Git.
Docker est un prerequis du lanceur, pas un outil fourni par cette Feature.

## Contrats Git et CI

Les trois workflows portables se trouvent dans `.github/workflows` de
`Gildraen/ci-workflows`, epingles ici a
`v0.1.0-rc.1`.
Leurs appels selectionnent une ref Git et leurs jobs operent sur le checkout
du consommateur. Les contrats `validate`, `test` et `lint` appartiennent au
Taskfile de ce consommateur, pas aux deux helpers du Taskfile partage.
Feature-test utilise une procedure specifique a DX.

DX conserve trois facades `reusable-validate.yml`,
`reusable-devcontainer-test.yml` et `reusable-maintenance.yml` dans
`.github/workflows/`. Ces wrappers deleguent au tag externe ci-dessus et
transmettent leurs inputs, sans copie d'implementation, pour les appels qui
utilisent des references DX flottantes.

Le Taskfile distant utilise une URL HTTP directe avec le SHA du commit dans le
chemin, distinct des tags OCI. Le commentaire conserve le tag `v0.1.0-rc.1`
comme flux de mise à jour Renovate. Task `3.53.1` utilise cet include HTTP.
L'exemple exact et la confiance restreinte
a `github.com` sont dans [consumer.md](consumer.md#3-remote-taskfile-optional-shared-helpers).
Le workflow validate conserve `TASK_REMOTE_TRUSTED_HOSTS=github.com`, suffisant
pour l'URL `https://github.com/Gildraen/dx-tools/raw/6630f37ffdc3a8c51af0f4795145a4743a61584b/taskfiles/base.yml # v0.1.0-rc.1`.
Les valeurs par defaut de `agentsVersion` et `toolsVersion` sont
`v0.1.0-rc.1`; `agentsCommit` et `toolsCommit` contiennent les SHA resolves
correspondants. L'installateur refuse une paire tag/SHA incoherente.
Le preset Renovate utilise ici
`github>Gildraen/renovate-config#v0.1.0-rc.1`,
fixe au tag candidat independamment des autres composants.

## Controles presents

| Contrat | Sources de verification |
| --- | --- |
| Hierarchie et decouverte IA | [Hierarchie](../.devcontainer/components/agents/tests/test-runtime-hierarchy.sh), [decouverte](../.devcontainer/test/dx/test-resource-discovery.sh) |
| Resolution Task | [Doctor](../.devcontainer/components/tools/tests/test-task-doctor.sh) |
| Lanceur MCP | [Image et arguments](../.devcontainer/components/tools/tests/test-dx-mcp-image.sh), [resolution du runtime](../.devcontainer/test/dx/test-dx-mcp-resolution.sh) |
| Installation Feature | [Procedure Feature-test](../.devcontainer/test/dx/feature-test.sh), [test installe](../.devcontainer/test/dx/test.sh) |