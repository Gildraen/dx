---
name: create-skill
description: Workflow pour creer un skill pour clients IA compatibles, partage ou specifique au projet, avec son frontmatter Agent Skills, sa structure de fichiers et ses validations.
---

# Creation de skill

## Quand l'utiliser

Utiliser ce skill lorsqu'une demande vise la creation d'un nouveau skill, le
choix de sa portee, son chargement par un client IA compatible ou la verification de sa
structure.

## Procedure

1. Clarifier la tache repetable a outiller, ses declencheurs et ses limites.
   Verifier qu'il s'agit d'un workflow a la demande et non d'une regle
   toujours applicable, d'une persona ou d'une tache ponctuelle parametree.
2. Determiner la portee :
   - partage DX -> `.devcontainer/src/dx/runtime/skills/<nom>/SKILL.md` ;
   - projet -> `.agents/skills/<nom>/SKILL.md`.
3. Verifier qu'une instruction, un agent ou un prompt ne correspond pas mieux
   au besoin qu'un skill, et qu'aucun skill existant ne couvre deja la tache.
4. Ecrire un frontmatter au format Agent Skills avec `name` et `description`,
   et `name` identique au nom du dossier :
   ```yaml
   ---
   name: <nom-dossier>
   description: '<ce que fait le skill et quand l'utiliser, mots-cles inclus>'
   ---
   ```
5. Rediger le corps : quand l'utiliser, procedure pas a pas, criteres de
   qualite, sortie attendue. Garder le fichier sous 500 lignes et deplacer le
   detail volumineux vers `references/`, `scripts/` ou `assets/` avec des
   chemins relatifs `./`.
6. Si le skill est partage, verifier que `docs/architecture.md`,
   `docs/consumer.md` et les tests Feature
   (`.devcontainer/test/dx/test.sh`) refletent le nouveau skill.
7. Verifier les references, les liens, le frontmatter et les conventions
   documentaires concernees. Garder une source unique et verifier son
   integration au chargement commun. Ne pas ajouter
   d'adaptateur ni de lien symbolique par IA, de schema ou de reglage client.

## Criteres de qualite

- La description contient des mots-cles permettant la decouverte du skill et
  precise quand l'utiliser.
- Le nom du dossier correspond exactement au champ `name`.
- La procedure est autonome et actionnable sans contexte externe manquant.
- Aucune API client n'est imposee.
- Le SKILL.md reste concis; le detail secondaire est externalise.
- Le skill ne duplique pas un autre skill existant ni une instruction
  toujours applicable.

## Sortie attendue

Donner le chemin du SKILL.md, la portee retenue, les validations executees et
les questions ou limites restantes.
