---
name: create-agent
description: Workflow pour creer un agent pour clients IA compatibles, partage ou specifique au projet, avec ses metadonnees, son contenu, son chargement et ses validations.
---

# Creation d'agent

## Quand l'utiliser

Utiliser ce skill lorsqu'une demande vise la creation d'un nouvel agent, le
choix de sa portee, son chargement par un client IA compatible ou la verification de sa
structure.

## Procedure

1. Clarifier le role, les utilisateurs, le declencheur de la demande et les
   limites de l'agent.
   Verifier qu'aucun agent existant ne couvre deja ce role.
2. Determiner la portee :
   - partage DX -> `.devcontainer/src/dx/runtime/agents/<nom>.md` ;
   - projet -> `.agents/agents/<nom>.md`.
3. Verifier qu'une instruction, un skill ou un prompt ne correspond pas mieux
   au besoin qu'un agent.
4. Ecrire le frontmatter neutre limite a `name` et `description` :
   ```yaml
   ---
   name: <nom-court>
   description: <role et cas d'utilisation>
   ---
   ```
5. Rediger un role unique avec objectif, activation, contraintes, methode et
   format de sortie.
6. Garder une source unique et verifier son integration au chargement commun.
   Ne pas ajouter
   d'adaptateur ni de lien symbolique par IA, de schema ou de reglage client.
7. Verifier les references, les liens, le frontmatter, les tests Feature et
   les conventions documentaires concernees.

## Criteres de qualite

- La description contient des mots-cles permettant la decouverte de l'agent.
- Le role est assez etroit pour produire des decisions coherentes.
- Les besoins d'outillage restent limites au role, sans API client imposee.
- L'agent ne duplique pas une instruction toujours applicable.
- L'agent explique les cas qu'il refuse ou qu'il delegue.

## Sortie attendue

Donner le chemin canonique de la source, le mode de chargement explicite,
la portee retenue, les validations executees et les limites.
