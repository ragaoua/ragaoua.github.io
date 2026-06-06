---
layout: post
title: ???
date: 2026-06-07
---

Il y a une feature dans MCP que je trouve super et personne n'en parle : les
élicitations.

# MCP tools

Un serveur MCP expose des tools. Ce sont des fonctions que l'agent peut décider
d'exécuter à tout moment.

Le problème, qui est aussi la feature, c'est que l'agent est (le plus souvent)
totalement autonome dans le choix d'exécuter ou non un tool. c'est d'ailleurs
ce qui fait l'utilité d'un agent (certains diront "son intelligence") : sa
capable d'inférer, à partir du langage naturel, la nécessité de réaliser une
certaine action sans que cela ne soit demandé explicitement.

Malgré tout, ça peut être un problème car il se peut qu'il se "trompe" et
exécute la mauvaise instruction, ou que certaines actions nécessitent une
intervention humaine (pour confirmer l'action ou ajouter des éléments
supplémentaires), ou encore qu'un appel de fonction nécessite une intervention
humaine.

# Les élicitations

Les élicitations font partie intégrante de la spec MCP depuis la révision
2025-06-18, et répondent exactement à ces problématiques.

Durant l'exécution d'un _tool_, le serveur MCP peut décider d'émettre une
élicitation. Celle-ci permettra à l'utilisateur de l'agent d'intéragir avec le
serveur MCP dans le contexte de cet appel de fonction. Il pourra alors
confirmer ou refuser une action, ou encore donner des informations
complémentaires. L'élicitation halte temporairement l'exécution de la fonction
tant que l'utilisateur n'y a pas répondu (ou qu'un timeout n'a pas expiré).
Du point de vue du LLM, rien à signaler, tout se passe comme si de rien n'était
pour lui.

Par exemple, si la fonction a pour but de supprimer une données, on peut
demander confirmation

# Pourquoi avoir besoin de ça ? Pourquoi par demander à l'agent ?

Et pourquoi pas un retour de fonction classique ? Pourquoi ne pas simplement
répondre au LLM de demander confirmation à l'utilisateur ou de fournir les
informations complémentaires ?

Si on laisse le soin à l'agent de demander confirmation à l'utilisateur, on n'a
aucune garantie qu'il le fera. Rappelons que les LLM sont des outils
non-déterministe, dont il est difficile de prévoir les décisions. Ceci sans
compter le coût induit et la latence supplémentaire pour ce qui peut être une
communication direct entre le client et le serveur.

Notons que les élicitations ne doivent pas être communiqué au LLM. La spec le
dit bien : les élicitations doivent être transmise à l'utilisateur, pas à
l'agent. Bien sûr, en dehors de la spec, rien n'empêche de le faire, comme rien
ne vous empêche non plus de renvoyer une erreur 500 au lieu de 401 pour
signifier un accès non autorisé à un serveur HTTP, mais c'est contrevenir à la
spécification.

[Insérer un schéma décrivant le flux]
