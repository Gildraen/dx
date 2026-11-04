---
name: doc-write
description: 'Creer, restructurer ou mettre a jour un document Markdown (README, guide, reference) a partir du contexte reel du projet ; utilise par l''agent de documentation pour toute production ou refonte de contenu.'
---

# Ecriture de documentation

## Quand l'utiliser

Utiliser ce skill pour creer un nouveau document Markdown, restructurer un
document existant (refonte de plan, fusion, decoupage) ou mettre a jour son
contenu suite a un changement de comportement, de configuration ou de
contrat.

Ne pas l'utiliser pour une simple relecture sans intention de modifier le
document ; utiliser `doc-review` pour cela. Ne pas l'utiliser pour une revue
de code, de conception ou de securite.

## Procedure

1. Identifier le public vise, l'objectif du document, son emplacement final
   et le comportement ou le contrat qu'il doit decrire.
2. Lire les fichiers sources, scripts, configurations, tests et documents
   voisins necessaires pour verifier chaque fait avant d'ecrire ; ne jamais
   inventer un comportement, une commande ou une promesse non verifiee.
3. Pour une refonte, identifier d'abord ce qui doit etre conserve (sens
   technique, ton, exemples encore valides) avant de reorganiser.
4. Organiser ou reorganiser le contenu autour des parcours reels du lecteur :
   pre-requis, installation, utilisation, configuration, verification et
   limites, uniquement lorsque ces rubriques sont utiles au document concerne.
5. Preferer des exemples executables et des instructions observables aux
   explications generiques.
6. Verifier les liens relatifs, les commandes, les chemins, les noms
   d'options et les exemples ; corriger ou signaler ceux qui sont invalides.
7. Garder le changement proportionne au besoin annonce ; ne pas modifier le
   code ou la configuration sauf demande explicite et necessite demontree.
8. Si le document appartient a un ensemble documentaire partage (par exemple
   `docs/architecture.md`, `docs/consumer.md`), verifier la coherence avec les
   documents voisins et les conventions locales avant de conclure.

## Criteres de qualite

- Chaque affirmation technique est verifiable dans le projet ; les points non
  verifiables sont signales plutot que completes par supposition.
- Le plan correspond aux parcours reels du lecteur, sans rubrique vide ou
  generique ajoutee par habitude.
- Les liens, commandes et exemples fonctionnent ou sont explicitement marques
  comme non executes.
- Le changement reste dans le perimetre demande ; aucune reecriture non
  sollicitee du ton ou du sens existant.

## Sortie attendue

Indiquer le document cree ou modifie, les faits verifies avec leur source,
les changements apportes, les liens/commandes controles et les questions ou
limites restantes.
