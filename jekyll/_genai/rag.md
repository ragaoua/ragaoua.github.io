---
layout: post
title: Vous n'avez pas besoin de base vectorielle pour votre RAG
date: 2026-06-05
---

Lorsqu'on parle de RAG (_Retrieval-Augmented Generation_), on finit très vite
par parler d'IA générative, de découpage en _chunks_, de bases vectorielles et
de vectorisation.

Mais concevoir un "système RAG" (on reviendra sur ce terme) revient davantage à
développer un moteur de recherche qu'une solution d'IA à proprement parler.
Partant de là, est-il nécessaire d'utiliser une base vectorielle et un
pipeline complexe de _chunking_ pour rechercher des mots clés dans un
SharePoint ?

# Revenir à la base

Avant d'entrer dans le vif du sujet, il est important de faire un rappel : le
RAG, qu'est ce que c'est ? C'est une stratégie employée dans le cadre de la
conception d'un chatbot, qui consiste à intercepter une requête exprimée en
langage naturel, rechercher dans un corpus documentaire les éléments de réponse
potentiels, et fournir le tout (la requête initiale + les résultats de la
recherche) à un LLM afin qu'il réponde à la demande en se basant sur des
éléments contextuels.

C'est l'une des techniques employées pour pallier 2 des plus grandes
limitations des systèmes d'IA générative : les hallucinations et l'horizon des
connaissances (le _cutoff_).

Le RAG n'est donc pas une typologie de bases de données comme on peut parfois le
lire ou l'entendre avec des expressions comme "base RAG". Le terme décrit
simplement une solution technique conceptuelle à une famille de problèmes. On
peut néanmoins parler de "système RAG" pour décrire une solution qui implémente
ce concept.

# Le plus important dans _RAG_, ce n'est pas la génération

Un système RAG est un pipeline qui se compose alors de 2 parties :

- Une partie amont, qui consiste à préparer la base de connaissances (à
  commencer par stocker celles-ci) afin qu'elle permette la recherche à venir
  ;
- Et une partie aval, qui est la recherche dans ce corpus d'éléments de réponse
  à une requête utilisateur.
  C'est alors que les données sont fournies à un LLM pour demander à générer
  une réponse.

Présenté ainsi, il paraît clair que le challenge consiste avant-tout à
concevoir un système optimisé pour la recherche d'information, ce qu'on appelle
alors **un moteur de recherche**. C'est donc sur le **R** de RAG (_Retrieval_)
que l'effort doit se concentrer.

Toutefois, le **G** de RAG (_Generation_) ne doit pas être délaissé. Il est
tout de même pertinent de choisir un LLM adapté au cas d'usage ou de travailler
le _system prompt_ du LLM utilisé par exemple. Mais ces choix auront un impact
moins important sur la qualité du résultat que ceux portant sur l'architecture
du moteur de recherche. Comme me l'a dit un ingénieur d'un fameux éditeur
français de LLM : _"Il vaut mieux disposer d'un LLM moyen avec un système de
retrieving performant, qu'un LLM à l'état de l'art avec un retriever
sous-optimal"_ (je paraphrase).

# Là où je veux en venir

J'ai eu des discussions avec des ingénieurs qui me soutenaient qu'on ne pouvait
pas parler de RAG sans base vectorielle, ou que l'intérêt d'un tel système
était diminué, ou encore que le RAG nécessitait qu'un LLM retravaille la
requête avant d'être envoyée au _retriever_. Et bien que je ne nie pas l'intérêt
de ces stratégies, je pense qu'il est contre-productif d'affirmer qu'elles sont
nécessaires et indissociables de la notion même de RAG.

Je pense qu'un système RAG performant est un système dont la partie _retriever_
renvoie des données d'une pertinence jugée élevée, et ce peu importe la méthode
utilisée, base vectorielle ou non.

J'ai moi-même travaillé l'année dernière sur un chatbot avec une composante
RAG qui présentait de meilleurs résultats une fois que nous avons associé
recherche sémantique (dans une base vectorielle donc) et _full-text search_
(recherche "plein texte", ce que Google fait depuis des années, bien que ce
soit avec un tout autre niveau de sophistication). Sur certains types de
recherche, la recherche sémantique réduisait même la qualité des réponses. Pour
les autres, la recherche hybride renvoyait systématiquement de meilleurs
résultats.

Plus récemment, j'ai été intégré à une discussion pour concevoir une solution
permettant de "faire du RAG" sur des documents stockés dans SharePoint. La
conversation s'est rapidement orientée vers un système basé sur la réplication
des données SharePoint dans une base vectorielle, avec un pipeline de
_chunking_, un _refresh_ quotidien, et une rustine permettant de tirer les
_metadata_ de chaque document afin de déterminer si l'utilisateur derrière la
requête disposait des droits nécessaires pour accéder au document. Pour ma
part, je ne suis pas un expert SharePoint, mais j'ai défendu l'idée selon
laquelle Microsoft Search, le moteur de recherche intégré aux solutions
Microsoft (Teams, Office, SharePoint, etc.), ferait l'affaire, du moins pour
une première version du cas d'usage. Une solution sans base vectorielle mais
qui ne nécessite pas de mettre en place une structure complexe à concevoir et à
maintenir.

Dans le même registre, on voit également apparaître les bases graphes dans la
conversation, notamment via l'approche _GraphRAG_, qui consiste à modéliser
les relations entre entités du corpus pour enrichir la recherche. La piste est
intéressante, mais elle ajoute une couche de complexité non négligeable :
extraction des entités, construction et maintenance du graphe, choix d'un
schéma. Tout cela pour un bénéfice qui dépend fortement de la nature du corpus
et du type de questions posées. Là encore, ce n'est ni une condition
nécessaire pour parler de RAG, ni une garantie de meilleurs résultats.

# Le mot de la fin

Les moteurs de vectorisation issus des dernières avancées en Deep Learning
sont des outils remarquables. La possibilité de stocker les représentations
vectorielles de textes dans des bases de données spécialisées a ouvert la voie
à de nouvelles architectures de recherche d'information. La recherche
sémantique a des avantages indéniables sur les autres techniques de recherche
(prise en compte native des synonymes et termes proches, traitement plus
holistique du texte, performances accrues dans certains cas, etc.). Il en va
de même pour les bases de données graphes.

Mais ces avantages ne doivent pas nous faire oublier qu'il existe souvent plus
d'une solution à une problématique technique, et que certaines de ces solutions
ont des implications importantes qui peuvent réduire voire effacer leur
intérêt.

Alors il est essentiel de faire preuve d'esprit critique et de rigueur :
interroger les définitions toutes faites, peser leurs implications, revenir au
besoin initial et oser proposer des solutions plus simples, plus abordables.
C'est d'autant plus vrai dans un domaine comme l'IA générative, où
l'effervescence technologique pousse à adopter chaque nouvel outil comme s'il
était la réponse absolue et universelle.

_(Et puis, vous avez vu le prix des licences ?)_
