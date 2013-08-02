#!/bin/bash

[ -z $1 ] && echo "$0 [list|remove|add|move|flush]" && exit 1

function list {
  for adsl in $(grep adsl /etc/iproute2/rt_tables | sed -e "s/.* //");
  do
    for RULE in $(ip rule list | grep $adsl | sed -e "s/.*from //" -e "s/ lookup//" -e "s/ /:/" | sort -n);
    do
      NETWORK=$(echo $RULE | cut -d ":" -f 1);
      PROVIDER=$(echo $RULE | cut -d ":" -f 2);
      grep -qs $NETWORK listing 2>/dev/null
      [ $? -eq 0 ] && TEAM=$(grep $NETWORK listing | sed -e "s/[[:space:]]/:/g" | cut -d':' -f2) && echo -e "$TEAM -> $PROVIDER"
    done
  done
}

function remove {
  # on recupere le reseau de la team
  NETWORK=$(grep -w $1 listing | sed -e "s/[[:space:]]/:/g" | cut -d':' -f3);
  [ -z "$NETWORK" ] && echo "La team $1 n'existe pas dans le listing" && exit 1

  # une fois qu'on a le reseau, on récupère le provider
  PROVIDER=$(ip rule list | grep $NETWORK | sed -e "s/.*lookup //")
  
  # on verifie que la règle à effacer est bien dans la liste
  ip rule del from $NETWORK table $PROVIDER
  echo "Remove $1 from $PROVIDER"
  list
}

function add {
  # on verifie que le provider saisie existe
  grep -qsw $2 /etc/iproute2/rt_tables
  [ $? -eq 1 ] && echo "La table de routage $2 n'existe pas." && exit 1

  # on recupere le reseau de la team
  NETWORK=$(grep -w $1 listing | sed -e "s/[[:space:]]/:/g" | cut -d':' -f3);
  [ -z "$NETWORK" ] && echo "La team $1 n'existe pas dans le listing" && exit 1

  # une fois qu'on a le reseau, on regarde s'il n'est pas déjà affecté à un provider
  PROVIDER=$(ip rule list | grep $NETWORK | sed -e "s/.*lookup //")
  [ ! -z $PROVIDER ] && echo "La team $1 est déjà affecté à $PROVIDER" && exit 1
  PROVIDER=$2

  # on verifie que la règle à effacer est bien dans la liste
  ip rule add from $NETWORK table $PROVIDER
  echo "Adding $1 to $PROVIDER"
  list
}

function move {
  # on verifie que le provider saisie existe
  grep -qsw $2 /etc/iproute2/rt_tables
  [ $? -eq 1 ] && echo "La table de routage $2 n'existe pas." && exit 1

  # on recupere le reseau de la team
  NETWORK=$(grep -w $1 listing | sed -e "s/[[:space:]]/:/g" | cut -d':' -f3);
  [ -z "$NETWORK" ] && echo "La team $1 n'existe pas dans le listing" && exit 1

  # une fois qu'on a le reseau, on récupère le provider
  PROVIDER=$(ip rule list | grep $NETWORK | sed -e "s/.*lookup //")

  # si le provider saisie est le même que la règle qui existe, on sort directement
  [ $PROVIDER == $2 ] && echo "$1 est déjà affecté sur $2." && list && exit 1

  # on verifie que la règle à effacer est bien dans la liste
  ip rule del from $NETWORK table $PROVIDER
  echo "Remove $1 from $PROVIDER"

  # on recupere le reseau de la team
  NETWORK=$(grep -w $1 listing | sed -e "s/[[:space:]]/:/g" | cut -d':' -f3);
  [ -z "$NETWORK" ] && echo "La team $1 n'existe pas dans le listing" && exit 1

  # une fois qu'on a le reseau, on regarde s'il n'est pas déjà affecté à un provider
  PROVIDER=$(ip rule list | grep $NETWORK | sed -e "s/.*lookup //")
  [ ! -z $PROVIDER ] && echo "La team $1 est déjà affecté à $PROVIDER" && exit 1
  PROVIDER=$2

  # on verifie que la règle à effacer est bien dans la liste
  ip rule add from $NETWORK table $PROVIDER
  echo "Adding $1 to $PROVIDER"
  list
}

function flush {
  echo "Open for all"
}