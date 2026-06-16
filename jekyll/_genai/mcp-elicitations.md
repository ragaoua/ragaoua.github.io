---
layout: post
title: "MCP : les élicitations, ce mécanisme dont on ne parle pas assez"
date: 2026-06-14
---

Le protocole MCP offre aux agents IA un moyen d'interagir avec des systèmes
externes. Il permet ainsi de doter un agent de la capacité d'accéder à des
données et même de réaliser des actions en écriture, donnant tout son sens au
terme "agent".

La plupart des discussions autour de MCP évoquent les _tools_, parfois les
_resources_ ou les _prompts_. Parmi les mécanismes définis par la
spécification, l'un d'eux est, il me semble, trop peu commenté voire méconnu
alors qu'il adresse un point primordial de l'interaction agent-utilisateur.
Il s'agit des **élicitations**.

# Une épée à double tranchant

Un agent peut décider, à tout moment, d'exécuter des _tools_ (fournis notamment
par un serveur MCP) pour répondre à une demande, et ce même si l'utilisateur ne
formule pas explicitement la demande.
En cela, on peut qualifier ces systèmes "d'agents **autonomes**" car ils disposent
d'une **capacité de prise de décisions** : ils peuvent réaliser des actions
intermédiaires pour atteindre un but final. C'est ce qui fait la puissance et
l'intérêt de ces systèmes.

Cette capacité peut néanmoins être la source de problèmes. Puisqu'il est
autonome dans sa prise de décision, il arrive qu'un agent fasse un choix de
_tool_ inadapté à l'objectif formulé.
Si l'action implique des opérations d'écriture voire de suppression, l'impact
d'une telle erreur peut être important, voire catastrophique (on a tous lu
des témoignages décrivant comment un agent a supprimé une base de données
entière par erreur). Même pour des _tools_ de lecture, l'effet peut s'avérer
significatif : surconsommation de tokens, latence accrue, charge inutile sur
une infra ou un service, pollution du contexte de l'agent, etc.

# Les élicitations

Les élicitations ont été intégrées à la spécification MCP par la révision
`2025-06-18`, et répondent exactement à cette problématique. Ce mécanisme
permet à un serveur MCP d'émettre une demande **à destination de
l'utilisateur** lors de l'exécution d'un _tool_, de sorte à intégrer la
nécessité d'une intervention humaine dans le processus d'appel de fonction.

Durant l'exécution d'un _tool_, le serveur MCP peut décider d'émettre une
élicitation sur la base de conditions prédéfinies. Cela se traduit par une
requête comprenant un message décrivant la demande. L'utilisateur doit alors
répondre pour fournir les informations demandées (qui peuvent prendre la forme
d'une confirmation de l'action) afin de permettre au serveur MCP de reprendre
l'exécution du _tool_.

Notons que l'agent n'a pas connaissance de ce processus. De son point de vue,
il a demandé à exécuter une fonction et en a reçu le retour. L'interaction
entre le serveur MCP et l'utilisateur est donc tout à fait transparente et
confidentielle au regard du LLM. Ce mécanisme peut être utilisé pour échanger
des informations dont le LLM ne doit pas avoir connaissance, pour des raisons
de sécurité ou dans une logique de contrôle de la fenêtre de contexte.

<picture>
    <source srcset="/assets/elicitations.dark.svg" media="(prefers-color-scheme: dark)">
    <img src="/assets/elicitations.svg" alt="Elicitations" style="max-width: 100%;">
</picture>

# Des cas d'usage concrets

Illustrons l'intérêt des élicitations par un exemple concret, démontrant deux
usages possibles de la fonctionnalité :

Un agent doit avoir accès à un système de gestion de tâches (Jira, Linear,
ServiceNow, etc.). Il est alors connecté à un serveur MCP exposant des _tools_
permettant de créer, lister, consulter, modifier et supprimer des tickets.

Les opérations de suppression de ticket étant irréversibles dans ce cas,
l'agent ne doit pas pouvoir exécuter le _tool_ de suppression sans validation
humaine. Le serveur MCP peut donc, avant de procéder, émettre une élicitation
pour informer l'utilisateur de l'opération et lui demander confirmation.

Dans une interface, cela peut se traduire par une boîte de dialogue
apparaissant lorsque l'agent tente de supprimer un ticket. La fenêtre
informerait l'utilisateur du numéro de ticket en cours de suppression et
demanderait confirmation. Si la réponse est négative, le serveur renverra une
réponse à l'agent l'informant que l'opération a été déclinée.

Imaginons désormais que les opérations d'écriture (créer, modifier et supprimer
un ticket) nécessitent une authentification nominative afin d'associer les
actions réalisées par l'agent à l'utilisateur de celui-ci, pour des raisons de
traçabilité. Les opérations de lecture, quant à elles, sont accessibles à tous
sans authentification préalable. L'authentification, dans notre exemple, se
fait au travers d'un _ID token_ fourni par un _provider_ OIDC.

Pour répondre à ces exigences, le serveur MCP peut de nouveau tirer parti des
élicitations. Pour les 3 _tools_ d'écriture, le serveur émet une élicitation
dans le mode "URL". Cela lui permet de rediriger le client (l'application qui
implémente l'agent et qui est présentée à l'utilisateur) vers une URL, qui est
la mire d'authentification OIDC dans notre cas. L'utilisateur saisit alors ses
identifiants, et un _ID token_ est renvoyé au serveur MCP qui peut l'utiliser
pour accéder en écriture au système de gestion de ticket sous-jacent.

On peut imaginer que le serveur MCP mette l'_ID token_ en cache, auquel cas il
vérifiera d'abord la présence du _token_ pour la session MCP courante, et ne
renverra l'utilisateur vers la mire d'authentification que s'il est absent.

Il est important de préciser que, dans le processus décrit, le serveur MCP
lui-même n'a pas accès aux identifiants de l'utilisateur, seulement à l'_ID
token_ qui lui a été fourni par le _provider_ OIDC. Il s'agit d'une
redirection totale effectuée vers la mire d'authentification permettant à
l'utilisateur de s'authentifier de manière fiable et sécurisée.

# Pourquoi ne pas simplement demander à l'agent ?

D'aucuns pourraient penser que les élicitations ne font qu'apporter une
solution à un problème déjà résolu : pourquoi ce mécanisme alors qu'il
suffirait d'ordonner au LLM de demander confirmation à l'utilisateur pour
certaines actions, ou le solliciter pour obtenir des informations
complémentaires ?

Confier cette responsabilité à l'agent, c'est d'abord renoncer à toute garantie
qu'elle soit assumée. Rappelons que les LLM sont des outils non déterministes,
dont il est difficile de prévoir le comportement : rien n'empêche un agent
d'omettre la demande de confirmation. À cela s'ajoutent un coût et une latence
supplémentaires pour ce qui peut être une communication directe entre
l'utilisateur et le serveur MCP.

Par ailleurs, transiter par le LLM implique que l'ensemble des informations
échangées avec l'utilisateur passent par la fenêtre de contexte de l'agent, y
compris celles qui ne lui sont d'aucune utilité. Cette pollution du contexte a
un impact direct sur les performances et le coût de l'agent. Plus encore,
certaines informations sensibles (identifiants, données personnelles, secrets)
ne doivent tout simplement pas être exposées au LLM, ce qui restreint d'autant
les cas d'usage envisageables avec cette méthode.

Enfin, les élicitations offrent nativement des fonctionnalités qu'un LLM ne
saurait fournir seul, comme la redirection de l'utilisateur vers une URL
externe.

# Adoption et perspectives

À mesure que les agents s'installent dans des contextes de production, ce type
de mécanisme va devenir incontournable.

Seulement, le support des élicitations est encore limité, en particulier côté
client. Parmi les agents de code populaires, on peut notamment citer Gemini CLI
et OpenCode qui ne tiennent toujours pas compte de ce mécanisme, bien que la
demande soit remontée régulièrement au travers des issues GitHub. Côté serveur,
l'adoption peine également à décoller car la plupart des implémentations MCP
s'en tiennent aux _tools_, sans tirer parti des autres possibilités offertes
par le protocole.

Malgré tout, MCP est un standard jeune, porté par une communauté active, et qui
évolue rapidement. Les élicitations en sont elles-mêmes l'illustration, ayant
été ajoutées au protocole en cours de route. D'autres fonctionnalités pourraient
suivre et venir enrichir l'arsenal à disposition des concepteurs de serveurs
MCP. J'ai d'ailleurs partagé quelques [propositions d'amélioration de la boucle
agentique]({% link
_genai/mcp-trois-propositions-pour-ameliorer-la-boucle-agentique.md %}) dans un
autre article. Espérons que l'adoption, côté client comme côté serveur, emboîte
le pas, pour que ce type de mécanisme devienne la norme plutôt que l'exception.
