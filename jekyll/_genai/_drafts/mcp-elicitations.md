---
layout: post
title: ???
date: 2026-06-07
---

Le protocole MCP offre aux agents IA un moyen d'interagir avec des systèmes
externes. Il permet ainsi de donner à un agent la capacité d'accéder à des
données et même de réaliser des actions en écriture, donnant tout son sens au
terme "agent".

La plupart des discussions autour de MCP évoquent les _tools_, parfois les
_resources_ ou les _prompts_. Parmi les mécanismes définits par la
spécification, l'un d'eux est, il me semble, trop peu commenté voir méconnu
alors qu'il adresse un point primordial de l'interaction agent-utilisateur.
Cette fonctionnalités, ce sont **les élicitations**.

# Une épée à double tranchant

Un agent peut décider, à tout moment, d'exécuter des _tools_ (fournis notamment
par un serveur MCP) pour répondre à une demande, et ce même si l'utilisateur ne
formule pas explicitement la demande.
En cela, on peut qualifier ces systèmes "d'agents **autonomes**" car ils disposent
d'une **capacité de prise de décisions** : il peuvent réaliser des actions
intermédiaires pour atteindre un but final formulé par l'utilisateur. C'est ce
qui fait la puissance et l'intérêt de ses systèmes.

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
confidentielle au regard du LLM. Ce mécanisme peut donc être utilisé pour
échanger des informations dont le LLM ne doit pas avoir connaissance, pour des
raisons de sécurité ou dans une logique de contrôle de la fenêtre de contexte.

<!-- Insérer un schéma décrivant le flux -->

# Des cas d'usage concrets

Illustrons l'intérêt des élicitations par un exemple concret, démontrant 2
usages possibles de la fonctionnalité :

Un agent doit avoir accès à un système de gestion de tâches (Jira, Linear,
ServiceNow, etc.). Il est alors connecté à un serveur MCP exposant des _tools_
permettant de créer, lister, consulter, modifier et supprimer des tickets.

Les opérations de suppression de ticket étant irreversibles dans ce cas,
l'agent ne doit donc pas pouvoir exécuter le _tool_ de suppression sans
validation humaine. Le serveur MCP peut donc implémenter une élicitation en
début d'exécution de la fonction, informant l'utilisateur de l'opération et lui
demandant confirmation.

Dans une interface, cela pourrait se traduire par une boîte de dialogue
apparaîssant lorsque l'agent tente de supprimer un ticket. La fenêtre
informerait l'utilisateur du numéro de ticket en cours de suppression et
demanderait confirmation. Si la réponse est négative, le serveur renverra une
réponse à l'agent l'informant que l'action a été déclinée.

<!-- Insérer un bout de code en exemple -->

Imaginons désormais que les opérations d'écriture (créer, modifier et supprimer
un ticket) nécessitent une authentification nominative afin d'associer les
actions réalisées par l'agent à l'utilisateur de celui-ci, pour des raisons de
traçabilités. Les opérations de lecture, quant à elles, sont accessibles à tous
sans authentification préalable. L'authentification, dans notre exemple, se
fait au travers d'un _ID token_ fournit par un _provider_ OIDC.

Pour répondre à ces exigences, le serveur MCP peut de nouveau tirer parti des
élicitations. Pour les 3 _tools_ d'écriture, le serveur émet une élicitation
dans le mode "URL". Cela lui permet de rediriger le client (l'application qui
implémente l'agent et qui est présentée à l'utilsateur) vers une URL, qui est
la mire d'authentification OIDC dans notre cas. L'utilisateur saisit alors ses
identifiant, et un ID token est renvoyé au serveur MCP qui peut l'utiliser pour
accéder en écriture au système de gestion de ticket sous-jacent.

# Pourquoi avoir besoin de ça ? Pourquoi par demander à l'agent ?

D'aucuns pourraient penser que les élicitations apportent une solution à un
problème déjà résolu : pourquoi ce mécanisme alors qu'il suffirait d'ordonner
au LLM de demander confirmation à l'utilisateur pour certaines actions, ou
le solliciter pour obtenir des informations complémentaires ?

Si on laisse le soin à l'agent de demander confirmation à l'utilisateur, on n'a
aucune garantie qu'il le fera. Rappelons que les LLM sont des outils
non-déterministe, dont il est difficile de prévoir les décisions. Ceci sans
compter le coût induit et la latence supplémentaire pour ce qui peut être une
communication direct entre le client et le serveur.
