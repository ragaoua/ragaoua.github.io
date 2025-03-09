---
layout: post
title: Introduction
---

En 2024 et pour la deuxième année consécutive, PostgreSQL a été nommé SGBD préféré des développeurs selon le _Stack Overflow developer survey_.
Cette année, la popularité du SGBD à l’éléphant a même augmenté par rapport à 2023.

A côté de ça, on note que les providers de cloud majeurs proposent tous, sans exception, un service de stockage de données relationnelles basé sur PostgreSQL, et même des solutions NoSQL développées à partir de PostgreSQL.

On aurait donc de bonnes raisons de penser que PostgreSQL est un SGBD qui en vaut le détour.

Dans cet esprit, nous commençons ici une nouvelle série d'articles traitant des bases nécessaires pour savoir installer, configurer, administrer et dépanner PostgreSQL.
On parlera d’installation, de configuration, de gestion des backups, de réplication, d’upgrade et bien d’autres choses encore.
Ce "cours" renverra très souvent le lecteur à la [documentation officielle de PostgreSQL](https://www.postgresql.org) car celle-ci est très bien écrite et articulée.

Ça ne sera pas un cours d’algèbre relationnelle ou de SQL.
Nous partirons du principe que ces bases sont acquises.
Autrement dit, vous devriez savoir ce qu’est une table, comment sont organisées les données dans une base de données relationnelle et comment requêter ces données.
Ça ne sera pas non plus un cours sur l'optimisation de performance, même s’il en sera un peu question notamment lorsqu'on parlera de configuration et d’indexage.

Ces articles s’adressent à toute personne souhaitant monter en compétence sur PostgreSQL, que vous soyez étudiant, développeur, administrateur système ou autres.
Je précise enfin qu’on ne va parler que d'environnement Linux dans ces articles (PostgreSQL sous Windows, ça fonctionne, mais ce n’est pas ce que je recommande ni ce que je connais le mieux, pour être tout à fait honnête).

Les bases sont posées. Rendez-vous donc au premier chapitre qui traitera de l'installation de PostgreSQL.
