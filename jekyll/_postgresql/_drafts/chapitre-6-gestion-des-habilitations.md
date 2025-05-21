Dans PostgreSQL, la gestion des habilitations se fait en créant et en configurant des rôles. Un rôle, c’est un objet qui dispose de droits définissant les actions qui peuvent être réalisées. Pour accéder à une base de données, on doit donc spécifier le rôle qu’on souhaite utiliser. Bien évidemment, selon la configuration en place, on devra fournir un mot de passe où un moyen pour s’authentifier avec ce rôle, mais ça on en parlera dans le prochain chapitre consacré à l’authentification.

Les rôles sont des objets communs à toutes les bases de données d’un cluster.  On peut donc se connecter à plusieurs bdd au sein du même cluster avec le même rôle, pour peu que celui-ci détienne les bons droits.

On notera que chaque objet d’un cluster (les bdd, tables, vues, index, schémas…) dispose d’un propriétaire, qui est un rôle. Un rôle a bien évidemment toujours tous les droits sur les objets dont il est propriétaire (à moins qu’il ait explicitement révoqué ses propres droits).

Pour créer un rôle, on utilise la commande CREATE ROLE, par exemple :
 CREATE ROLE toto;

On dispose également de la commande ALTER ROLE pour modifier un rôle existant, par exemple :
 ALTER ROLE toto RENAME TO titi;

Comme on l’a dit, un rôle détient des droits. Plus précisément, il détient des "privilèges" et des "attributs" :

# Privilèges
Les privilèges d’un rôle, ce sont les droits dont il dispose sur d’autres objets : des tables, des index, des schémas, des bdd etc.. Par exemple, un rôle peut avoir le privilège INSERT sur une table pour y insérer des données ou le privilège SELECT sur une vue pour lire son contenu.

On ne va pas parcourir la liste exhaustive des privilèges qu’un rôle peut avoir, car certains font appel à des notions que nous n’avons pas encore vues. Mais on peut déjà citer les privilèges suivants :

- SELECT : droit de lecture d’une table, d’une vue, d’une colonne ou d’une séquence
- INSERT : droit d’insertion dans une table. Possibilité de spécifier une colonne
- UPDATE : droit de mise à jour d’une table, d’une colonne ou d’une séquence
- DELETE : droit de suppression de données depuis une table
- TRUNCATE : droit de vider une table de son contenu
- REFERENCES : droit de créer une clé étrangère sur une table ou une colonne d’une table
- CREATE : droit de créer des objets dans une base de données, un schéma, ou un tablespace
- CONNECT : droit du rôle de se connecter à une bdd

L’attribution de privilèges pour un rôle passe par la commande GRANT, par exemple :
 GRANT insert, update ON TABLE tbl TO toto ;

Pour retirer des privilèges, on utilise la commande REVOKE, par exemple :
 REVOKE insert, update ON TABLE tbl FROM toto;

À la fin de la commande GRANT, on a la possibilité de spécifier l’option WITH GRANT OPTION, qui indique que le rôle auquel on accorde un privilège pourra, à son tour, le transmettre à un autre rôle (pour peu qu’il ait les bons droits sur ce rôle : on va en parler plus tard).

# Attributs
Les attributs définissent les droits d’un rôle sur le cluster. Par exemple, un rôle peut avoir l’attribut "CREATEDB" qui lui donne le droit de créer des bases de données dans le cluster, ou l’attribut "CREATEROLE" qui lui permet de créer des rôles.

Comme pour les privilèges, on va parler de certains attributs seulement :

 CREATEDB : droit de créer des bases de données
 CREATEROLE : droit de créer d’autres rôles
 SUPERUSER : cet attribut identifie les rôles superuser, qui ont tous les droits sur le cluster et ses objets, sans exception
 LOGIN : seuls les rôles détenant l’attribut "LOGIN" peuvent être utilisés pour se connecter à une base de données. Cela signifie donc qu’il existe des rôles qui ne peuvent pas servir à cela, mais ceux-ci, on le verra plus tard, ont leur utilité.
 PASSWORD : cet attribut sert à définir le mot de passe d’un rôle, qui pourra permettre de s’authentifier. Contrairement aux autres attributs qu’on vient de voir, celui-ci n’est donc pas un booléen (on l’a ou on l’a pas), il est nécessairement associée à une valeur : le mdp
 CONNECTION LIMIT : comme pour PASSWORD, cet attribue est associé à une valeur, et cette valeur permet de définir le nombre de connexions concurrentes autorisées pour un rôle. -1 signifie "pas de limite"

On peut définir les attributs d’un rôle à sa création avec la commande CREATE ROLE, par exemple :
 CREATE ROLE toto WITH createdb createrole
Ou en modifiant un rôle existant avec la commande ALTER ROLE, par exemple :
 ALTER ROLE toto createdb createrole;

Pour retirer un attribut à un rôle ou pour indiquer à sa création qu’on ne veut pas de cet attribut, on utilise la syntaxe suivantes :
 { ALTER | CREATE } ROLE toto WITH no{attribut}

Contrairement aux privilèges, il n’existe pas de commande spécifique pour retirer un attribut à un rôle. A la place, on modifie le rôle en indiquant

Rôle membership
Enfin, un rôle peut être membre d’un autre rôle. On appelle alors ce dernier un groupe. Un rôle qui est membre d’un rôle en hérite tous les privilèges et attributs.

Penser à parler de WITH ADMIN OPTION
Penser à parler de l’attribut INHERIT.

Rôles pré-définis et pseudo-rôle "PUBLIC"
pg_roles catalog table
