---
layout: post
title: "MCP : quelques suggestions"
date: 2026-06-06
---

Depuis sa première version publiée en novembre 2024, la spécification MCP n'a
cessé de vivre et d'évoluer. Sa prochaine révision est prévue pour le 28
juillet 2026, et il y a fort à parier qu'il ne s'agira pas de la dernière.

La spécification évolue car les usages changent ou se précisent. MCP est un
standard "ouvert" (_open standard_), c'est-à-dire qu'il est développé par une
communauté, et non une seule entité. Dans cet esprit, je souhaite partager mes
propositions d'amélioration de la _spec_ après près de 2 ans à utiliser, mais
aussi à développer, des serveurs MCP en tout genre.

# La boucle agentique

Difficile de parler de MCP sans parler d'agents, et des cas d'usage associés.

Ce que permet MCP (et ce que permettait déjà le _function calling_/_tool
calling_), c'est de généraliser la logique qui sous-tend la **boucle
agentique**. Un agent, c'est finalement un pipeline assez simple :

1. L'utilisateur envoie une requête ;
2. L'agent peut répondre, ou demander à exécuter une des fonctions dont son
   concepteur l'a doté pour répondre à la demande ;
3. Si l'agent émet une demande d'appel de fonction, le pipeline l'exécute après
   avoir vérifié la légitimité de la demande\*. Le résultat de la fonction est
   ensuite renvoyé à l'agent et le pipeline reprend à l'étape 2. Si l'agent n'a
   pas émis de demande d'appel de fonction, le texte qu'il a généré est envoyé à
   l'utilisateur et le pipeline s'arrête.

\* Il s'agit essentiellement de vérifier que la fonction fait bien partie de
celles fournies à l'agent dans son _system prompt_, et que les inputs de
celle-ci sont corrects (nom et types des arguments de la fonction).

<img src="/assets/boucle-agentique.svg" alt="Boucle agentique" style="max-width: 100%;">

C'est justement sur cette boucle agentique que mes propositions se concentrent.
L'objectif est d'enrichir la réponse envoyée par le serveur à un client MCP
afin que celui-ci utilise ces informations pour modifier la logique interne de
la boucle.

Pourquoi ? Pour contribuer au caractère déterministe et prévisible du pipeline
agentique, car c'est selon moi un élément clé pour garantir la stabilité de ces
systèmes qui reposent initialement sur une brique non déterministe.

# Terminer la boucle

L'idée est la suivante : lorsqu'un _tool_ renvoie une réponse, le serveur peut
inclure, dans les _metadata_, un marqueur signifiant la fin de la boucle.
Lorsque le pipeline agentique détecte ce _flag_, il renvoie la réponse de
l'appel de fonction au LLM, mais omet tous les _tools_ qu'il fournissait
jusqu'à présent pour la prochaine itération de la boucle. Le LLM n'aura alors
aucun _tool_ à sa disposition durant ce "tour" et sera donc contraint (autant
qu'un LLM peut l'être) de générer une réponse finale pour l'utilisateur.

L'intérêt est de redonner au concepteur du serveur MCP, qui connaît la
sémantique réelle de chaque _tool_, la main sur la terminaison de la boucle,
plutôt que de toujours laisser cette décision au LLM.

Par exemple, une fonction qui soumet un formulaire, si elle échoue, peut clore
la boucle afin d'éviter que le LLM ne retente l'action car le contexte n'y est
pas propice (éviter de surcharger l'infra, connaissance a priori qu'un _retry_
sort toujours en échec sur un type d'appel d'API, etc.). Ou inversement, on
peut concevoir un _tool_ qui ne met fin à la boucle que si son exécution se
termine avec succès, pour justement permettre au LLM de corriger et réessayer
en cas d'échec.

Cela évite de recourir à des stratagèmes qui consistent à intégrer, dans le
retour de la fonction, des instructions au LLM lui indiquant de ne pas retenter
l'action par exemple, ou de rendre compte à l'utilisateur immédiatement sans
appeler d'autres fonctions. Pourquoi recourir au LLM lorsqu'on peut l'éviter ?

Aujourd'hui, rien n'empêche un LLM d'enchaîner les appels de fonction "par
sécurité" ou par excès de zèle, ce qui peut se traduire par une latence accrue,
des coûts supplémentaires en tokens, et un risque non nul d'effets de bord
indésirables (un second email, un doublon de ticket, etc.). En déléguant ce
signal au serveur, on remplace un comportement probabiliste par une garantie
déterministe, ce qui est particulièrement précieux pour les opérations
sensibles ou non idempotentes.

# Court-circuiter le LLM

Semblable au précédent, ce marqueur pourrait être émis au retour d'un _tool
call_ et signifier la fin de la boucle, mais avec une nuance importante : le
retour de la fonction doit aller directement à l'utilisateur. Le LLM n'a alors
pas accès à ce résultat.

Prenons l'exemple d'un _tool_ qui exécute une requête SQL de type `SELECT` et
qui retourne un grand nombre de lignes. Si l'objectif de ce _tool_ est de
fournir le résultat exact de la requête à l'utilisateur (par exemple pour un
export ou une consultation directe), alors faire transiter ces lignes par le
LLM n'a aucun intérêt : au mieux il les recopie à l'identique en consommant des
tokens et en ajoutant de la latence, au pire il les tronque ou en altère le
contenu. Le marqueur permet ici de court-circuiter le LLM et de remettre le jeu
de données directement à l'utilisateur, préservant ainsi son intégrité.

Autre exemple : un _tool_ qui retourne des informations qu'on ne souhaite pas
exposer au LLM. Il peut s'agir de données sensibles pour lesquelles on veut
limiter au maximum la surface d'exposition (informations personnelles, secrets,
données soumises à des contraintes réglementaires, etc.), ou simplement de
données volumineuses et peu pertinentes pour l'agent et qui ne feraient que
parasiter sa fenêtre de contexte. Dans les deux cas, le marqueur permet
d'acheminer le résultat vers l'utilisateur sans que le LLM ne le voie jamais
passer.

# Paginer les résultats

Certains _tools_ renvoient une quantité importante de données. Il peut alors
être intéressant, voire nécessaire, de mettre en place un mécanisme de
pagination.

J'ai rencontré ce cas l'année dernière sur un _tool_ qu'on avait développé pour
récupérer les logs d'un serveur sur une plage horaire donnée, utilisé par un
agent pour faire du _troubleshooting_. La fonction pouvait renvoyer plusieurs
milliers de lignes, alors que l'information recherchée pouvait se trouver dans
les premières. Tout charger à chaque appel, c'était payer le coût (en tokens,
latence et saturation de contexte) d'un volume de données dont on exploitait
rarement l'intégralité. Nous avons donc implémenté une pagination sur ce _tool_
et ajouté des instructions contextuelles à destination du LLM dans la réponse
retournée pour l'informer que le résultat obtenu était partiel, et lui indiquer
comment obtenir la prochaine page de données.

Et si la pagination était intégrée à la logique interne de la boucle agentique
? Un _tool_ pourrait indiquer qu'il ne renvoie qu'une partie des données, et le
client MCP en charge d'implémenter la boucle pourrait identifier ce cas de
figure, et fournir au LLM les outils supplémentaires permettant de récupérer,
au besoin, le reste des données.

Notons que la pagination est un mécanisme qui existe déjà dans la spécification
MCP depuis sa première version, mais celle-ci s'applique uniquement aux
opérations de type "list" (lister les _resources_, les _prompts_, les _tools_,
etc.). La proposition consiste donc à étendre le mécanisme aux opérations
d'exécution (j'ai évoqué les _tools_, mais cela pourrait également s'appliquer
aux _resources_ par exemple).

# Points en suspens

Ces propositions restent des idées, avec des points d'attention laissés
volontairement en suspens, pour susciter la discussion. Je ne dis pas
grand-chose sur la forme des _metadata_ à renvoyer, ni ne tranche sur la nature
des marqueurs pour les 2 premières propositions (le client MCP peut-il les
ignorer ?). Je n'aborde pas la façon de combler le "trou" dans l'historique
conversationnel induit par le marqueur de retour immédiat. Et je ne rentre pas
dans le détail du mécanisme de pagination (utilisation d'un curseur ? d'un
offset ?).

Ces propositions méritent encore d'être mûries avant d'être soumises à la
communauté MCP. Ce sera l'objet, peut-être, d'un prochain article.
