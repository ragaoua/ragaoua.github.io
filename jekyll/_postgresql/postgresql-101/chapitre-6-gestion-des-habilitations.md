---
layout: post
title: Chapitre 6 - Gestion des habilitations
date: 2025-
---

# La notion de rôle

La gestion des habilitations dans PostgreSQL est portée par la notion de "rôles".

Un rôle est un objet disposant de droits relatifs à un cluster PostgreSQL. Chaque connexion à une instance PostgreSQL est associée à un rôle, de sorte à définir les permissions et actions autorisées par cette connexion.

De plus, chaque objet d’un cluster (les tables, vues, index, schémas, bases de données etc) dispose d’un propriétaire, qui est un rôle. Le propriétaire d'un objet détient tous les droits sur celui-ci, à moins que ceux-ci n'aient été révoqués explicitement.

La commande `CREATE ROLE` est utilisée pour créer un rôle. Par exemple :

~~~sql
CREATE ROLE toto;
~~~

Il existe également une commande `ALTER ROLE` permettant de modifier un rôle existant. Par exemple :

~~~sql
ALTER ROLE toto RENAME TO titi;
~~~

Comme mentionné plus haut, un rôle détient des droits sur un cluster. Plus précisément, il détient un ensemble de **privilèges** et d'**attributs**.

# Les privilèges

Un **privilège** est un droit qu'un rôle détient sur un autre objet. Les privilèges qu'un rôle peut détenir sur un objet dépendent du type d'objet.

Nous ne détaillerons pas la liste exhaustive des privilèges dans cette article, mais nous citerons quelques privilèges de base :

- `SELECT` : droit de lecture d’une table, d’une vue, d’une colonne ou d’une séquence
- `INSERT` : droit d’insertion dans une table
- `UPDATE` : droit de mise à jour d’une table, d’une colonne ou d’une séquence
- `DELETE` : droit de suppression des données d'une table
- `TRUNCATE` : droit de vider une table de son contenu (l'ensemble des données)
- `REFERENCES` : droit de créer une clé étrangère sur une table
- `CREATE` : droit de créer des objets dans une base de données, un schéma, ou un tablespace
- `CONNECT` : droit de se connecter à une base de données

L’attribution de privilèges est permise par la commande `GRANT`. Par exemple :

~~~sql
GRANT insert, update ON TABLE tbl TO toto ;
~~~

Pour retirer des privilèges à un rôle, on utilise la commande `REVOKE`. Par exemple :

~~~sql
REVOKE insert, update ON TABLE tbl FROM toto;
~~~

À la fin de la commande `GRANT`, il est possible d'ajouter la mention `WITH GRANT OPTION`, qui permet au rôle de transmettre le(s) privilège(s) à un autre rôle.

# Les attributs

Un **attribut** définit les droits d’un rôle sur le cluster. Comme pour les privilèges, citons quelques attributs essentiels :

- `CREATEDB` : droit de créer des bases de données
- `CREATEROLE` : droit de créer d’autres rôles
- `LOGIN` : droit de se connecter à l'instance. Il existe des rôles ne disposant pas de cet attribut, et nous verrons dans la suite comment tirer partie de ces rôles
- `PASSWORD` : cet attribut sert à définir le mot de passe d’un rôle, qui pourra permettre de s’authentifier. Contrairement aux attributs précédents, celui-ci n’est donc pas un booléen : il est nécessairement associé à une valeur, le mot de passe du rôle
- `CONNECTION LIMIT` : à l'instar de `PASSWORD`, cet attribue est associé à une valeur. Il permet alors de définir le nombre maximal de connexions concurrentes autorisées avec le même rôle
- `SUPERUSER` : cet attribut identifie les rôles **superutilisateur**. Un superutilisateur détient tous les droits (attributs et privilèges) sur le cluster et ses objets.

Les attributs peuvent être octroyés à un rôle à sa création (`CREATE ROLE`) ou à posteriori avec `ALTER ROLE`. Par exemple :

~~~sql
CREATE ROLE toto WITH createdb createrole
~~~

Ou encore :

~~~sql
ALTER ROLE toto createdb createrole;
~~~

Par défaut, un nouveau rôle détient l'attribut `INHERIT`, et les valeurs de `PASSWORD` et `CONNECTION LIMIT` sont respectivement `null` (aucun mot de passe) et "-1" (aucune limite de connexion).

Contrairement aux privilèges, il n’existe pas de commande spécifique pour retirer un attribut booléen à un rôle. Pour ce faire, la syntaxe suivante est utilisée : `{ ALTER | CREATE } ROLE toto WITH [ no{attribut} [...] ]`. Par exemple :

~~~sql
ALTER ROLE toto WITH noinherit nocreatedb
~~~

# Rôle membership

Enfin, un rôle peut être membre d’un autre rôle. On appelle alors ce dernier un groupe. Un rôle qui est membre d’un rôle en hérite tous les privilèges et attributs.

Penser à parler de WITH ADMIN OPTION
Penser à parler de l’attribut INHERIT.

# Rôles pré-définis et pseudo-rôle "PUBLIC"

pg_roles catalog table

# Ressources

[CREATE ROLE](https://www.postgresql.org/docs/current/sql-createrole.html)  
[ALTER ROLE](https://www.postgresql.org/docs/current/sql-alterrole.html)  
[Privilèges](https://www.postgresql.org/docs/current/ddl-priv.html)  
[Rôles pré-définis](https://www.postgresql.org/docs/17/predefined-roles.html)