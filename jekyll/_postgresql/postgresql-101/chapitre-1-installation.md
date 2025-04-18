---
layout: post
title: Chapitre 1 - Installation
date: 2025-03-17
---

Pour ce premier article, nous allons tout naturellement parler de l’installation de PostgreSQL.

# Installation de paquets prêts à l'emploi

La méthode d’installation recommandée par la [documentation officielle](https://www.postgresql.org/download/) est d’utiliser un gestionnaire de paquet pour installer des paquets prêts à l’emploi.

La plupart des OS Linux intègrent PostgreSQL par défaut dans leurs dépôts.
Malheureusement, la plupart du temps, seul un nombre limité de versions de PostgreSQL sont disponibles, comme pour AlmaLinux 8 où on ne retrouve pas les versions 14 ni 17.
De plus, ces dépôts ne fournissent qu'une partie des outils et extensions de l'écosystème PostgreSQL (nous aurons l'occasion de discuter de la richesse de cet écosystème plus tard dans cette série d'articles).

Pour palier ces défauts, le projet PostgreSQL met donc à disposition un ensemble de dépôts s'intégrant avec les distributions Linux les plus communes (Debian, RedHat, SUSE, Ubuntu) et fournissant des paquets d'installation pour toutes les versions supportées, ainsi qu'un large choix de solutions appartenant à l'environnement PostgreSQL.

La documentation fournit une procédure détaillée pour utiliser ces dépôts.
A titre d'exemple, déroulons la procédure pour les distributions RedHat 9 :

~~~bash
# Installer les dépôts du projet
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Désactiver le module PostgreSQL natif (pour éviter d'éventuels conflits)
sudo dnf -qy module disable postgresql

# Installer la version de PostgreSQL désirée, ici la dernière version mineure de PostgreSQL 17
sudo dnf install -y postgresql17-server
~~~

Le paquet `postgresql17-server` installe les binaires et bibliothèques permettant de créer et administrer un serveur PostgreSQL en version 17.
Les binaires qui vont le plus nous intéresser se situent sous `/usr/pgsql-17/bin`.

En plus de ce paquet, nous allons en considérer 2 autres :
- `postgresql17-contrib` : ce paquet installe des composants supplémentaires, principalement des extensions, intégrables au moteur de base.
  Voir [l'annexe F de la documentation](https://www.postgresql.org/docs/current/contrib.html)
- `postgresql17-llvmjit` : ce paquet permet d'activer la compilation "à la volée" (_Just-in-Time_, ou JIT) basée sur llvm.
  Cette fonctionnalité permet d'améliorer les performances en compilant dynamiquement certaines opérations vers du code machine.


# Installer PostgreSQL à partir des sources

PostgreSQl étant Open Source, il est également possible de compiler soi-même le code source afin de générer les binaires.
Après quoi, il est tout de même recommandé de construire des paquets afin de simplifier le processus d'installation, mais également de mise à jour et de maintenance des binaires.

Cette méthode présente plusieurs avantages :
- Elle offre l'opportunité de modifier le code avant compilation pour intégrer des fonctionnalités supplémentaires ou modifier des comportements existants.
- Elle permet de choisir les bibliothèques, et les versions de celles-ci, dont dépenderont les binaires une fois compilés.
- Les binaires peuvent être compilés avec un grand nombre d'options pour supporter différents langages et fonctionnalités ou pour modifier certains comportements.
- Il est possible d'auditer le code source pour se conformer à diverses contraintes de sécurité.

Néanmoins et malgré ces avantages, compiler soi-même le code source n'est pas toujours judicieux.
Cela nécessite de se doter d'un environnement adéquat et de maintenir celui-ci, d'autant que les possibilités d'options offertes à la compilation augmentent la complexité de mise en oeuvre.

Pour cette raison, nous ne détaillerons pas le procédé de compilation dans cet article mais vous trouverez en bas de celui-ci les ressources nécessaires pour aller plus loin.


# Et la conteneurisation alors ?

A l'heure où cet article est publié (début 2025), il serait dommage de ne pas parler de conteneurisation, qui semble bien devenir le standard en terme de gestion de déploiement applicatif.

Il est en effet possible de faire tourner PostgreSQL en tant qu'application conteneurisée.
"L'installation", dans ce cadre, correspondrait alors simplement à disposer d'une image pouvant ensuite permettre de faire tourner un conteneur exécutant PostgreSQL.
Cette image pourrait être récupérée depuis n'importe quel _registry_, ou construite manuellement.

Le sujet "PostgreSQL sous conteneur" mériterait une série d'article à part.
Je ne vais donc pas m'y attarder davantage, d'autant que la conteneurisation s'accompagne d'un degré d'abtraction qui, je pense, nuit à notre objectif premier, qui est de comprendre les concepts de base de PostgreSQL.


# Pour aller plus loin...

[Politique de versions](https://www.postgresql.org/support/versioning/)  
[Documentation d'installation à partir des sources](https://www.postgresql.org/docs/17/installation.html)
