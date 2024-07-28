#!/bin/bash

################# Colors in Bash #################
Color_Off='\033[0m' # Text Reset

# Bold
BRed='\033[1;31m'    # Red
BGreen='\033[1;32m'  # Green
BYellow='\033[1;33m' # Yellow
BBlue='\033[1;34m'   # Blue

# Background
On_Black='\033[40m'  # Black
On_Red='\033[41m'    # Red
On_Green='\033[42m'  # Green
On_Yellow='\033[43m' # Yellow
On_Blue='\033[44m'   # Blue
On_Purple='\033[45m' # Purple
On_Cyan='\033[46m'   # Cyan
On_White='\033[47m'  # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'  # Black
On_IRed='\033[0;101m'    # Red
On_IGreen='\033[0;102m'  # Green
On_IYellow='\033[0;103m' # Yellow
On_IBlue='\033[0;104m'   # Blue
On_IPurple='\033[0;105m' # Purple
On_ICyan='\033[0;106m'   # Cyan
On_IWhite='\033[0;107m'  # White

# Change Directory to DBMS Directory or Create it if it does not exist
cd ~ || exit
if [ -d "DBMS" ]; then
  cd DBMS || exit
else
  mkdir DBMS
  cd DBMS || exit
fi

# Database and Table Name Pattern
name_pattern="^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$"
schema_format="^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]:(int|string)(,[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]:(int|string))*$"
values_format="^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]:[0-9]+(,[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]:[0-9]+)*$"

# Try again function
function try_again {
  echo -e "${BRed}press enter to try again${Color_Off}"
  read -r
  clear
}

################# Main Menu Functions #################
function create_database {
  read -r -p "Enter database name: " db_name
  if [[ ! $db_name =~ $name_pattern ]]; then
    echo -e "${BRed}Invalid database name!, Database name must start with a letter and can contain only letters, numbers and underscores.${Color_Off}"
    return
  fi
  if [ ! -d "$db_name" ]; then
    mkdir "$db_name"
    echo -e "${BGreen}Database created successfully!${Color_Off}"
  else
    echo -e "${BYellow}Database already exists!${Color_Off}"
  fi
}

# List Databases
function list_databases {
  if [ "$(ls -A)" ]; then
    echo -e "${BBlue}Databases:${Color_Off}"
    echo -e " ${BGreen}$(ls -l | grep ^d | awk '{print $9}')${Color_Off}"
  else
    echo -e "${BYellow}No databases found!${Color_Off}"
  fi
}

## Drop Database
function drop_database {
  read -p "Enter database name: " db_name
  if [ -d "$db_name" ]; then
    rm -r "$db_name"
    echo -e "${BGreen}Database dropped successfully!${Color_Off}"
  else
    echo -e "${BRed}Database does not exist!${Color_Off}"
  fi
}

################# Table Functions #################
function create_table {
  read -p "Enter table name: " table_name
  if [[ ! $table_name =~ $name_pattern ]]; then
    echo -e "${BRed}Invalid table name!, Table name must start with a letter and can contain only letters, numbers and underscores.${Color_Off}"
    return
  fi

  if [ ! -f "$table_name" ]; then
    touch "$table_name"
    echo -e "${BGreen}Table created successfully!${Color_Off}"
    define_table_schema "$table_name"
  else
    echo -e "${BYellow}Table already exists!${Color_Off}"
  fi
}

# Define Table Schema
function define_table_schema {
  while true; do
    echo -e "${BBlue}Define Table Schema:${Color_Off}"
    echo -e "${BYellow}Column Types: int, strings${Color_Off}"
    echo -e "${BYellow}Enter Primary Key Column as 'column_name:column_type, or enter q to exit'${Color_Off}"
    read primary_key
    if [ "$primary_key" == "q" ]; then
      clear
      break
    fi
    if [[ ! $primary_key =~ $schema_format ]]; then
      echo -e "${BRed}Invalid Primary key format!!1${Color_Off}"
      try_again
      continue
    fi
    echo -e "${BYellow}Schema format: column_name:column_type,column_name:column_type,...${Color_Off}"
    read -r -p "Enter table schema: " schema
    if [[ ! $schema =~ $schema_format ]]; then
      echo -e "${BRed}Invalid schema format!, Schema format: column_name:column_type,column_name:column_type,...${Color_Off}"
      try_again
      continue
    fi
    table_schema="$primary_key","$schema"
    echo "$table_schema" >"$1"
    echo -e "${BGreen}Table schema defined successfully!${Color_Off}"
    echo -e "${BYellow}Press q to exit: ${Color_Off}"
    read -r exit
    if [ "$exit" == "q" ]; then
      clear
      break
    fi
  done
}

# TODO: Insert into Table
function insert_into_table {
  while true; do
    echo -e "${BBlue}Insert into Table: (enter q to exit)${Color_Off}"
    read -r -p "Enter table name: " table_name
    if [ "$table_name" == "q" ]; then
      clear
      break
    fi
    if [ -f "$table_name" ]; then
      echo -e "${BGreen}Table exists!${Color_Off}"
      echo -e "${BYellow}Table Schema:${Color_Off}"
      echo -e "${BGreen}$(head -1 "$table_name")${Color_Off}"
      echo -e "${BYellow}Enter values in the format: column_name:value,column_name:value,...${Color_Off}"
      read -r values
      if [[ ! $values =~ $values_format ]]; then
        echo -e "${BRed}Invalid values format!${Color_Off}"
        try_again
        continue
      fi
      # Check if primary key exists
      primary_key=$(head -1 "$table_name" | cut -d "," -f 1)
      primary_key_column=$(echo "$values" | cut -d "," -f 1)
      if grep -q "$primary_key_column" "$table_name"; then
        echo -e "${BRed}Primary key already exists!${Color_Off}"
        try_again
        continue
      fi

      # Check values data types
      table_schema=$(head -1 "$table_name")
      IFS=',' read -r -a schema <<<"$table_schema"
      IFS=',' read -r -a values_array <<<"$values"
      for i in "${!schema[@]}"; do
        column_name=$(echo "${schema[$i]}" | cut -d ":" -f 1)
        column_type=$(echo "${schema[$i]}" | cut -d ":" -f 2)
        value=$(echo "${values_array[$i]}" | cut -d ":" -f 2)
        if [ "$column_type" == "int" ] && ! [[ "$value" =~ ^[0-9]+$ ]]; then
          echo -e "${BRed}Invalid value for column $column_name, expected int!${Color_Off}"
          try_again
          continue
        elif [ "$column_type" == "string" ] && [[ "$value" =~ ^[0-9]+$ ]]; then
          echo -e "${BRed}Invalid value for column $column_name, expected string!${Color_Off}"
          try_again
          continue
        fi
      done
      # Append values to table
      echo "$values" >>"$table_name" # Append values to table
      echo -e "${BGreen}Values inserted successfully!${Color_Off}"

      echo -e "${BYellow}Press q to exit: ${Color_Off}"
      read -r exit
      if [ "$exit" == "q" ]; then
        clear
        break
      fi
    else
      echo -e "${BRed}Table does not exist!${Color_Off}"
      try_again
      continue
    fi
  done
}

# TODO: Select from Table
function select_from_table {
  while true; do
    echo -e "${BBlue}Select From Table:${Color_Off}"
    read -r -p "Enter table name: " table_name
    if [ -f "$table_name" ]; then
      echo -e "${BGreen}Table exists!${Color_Off}"
      echo -e "${BYellow}Table Schema:${Color_Off}"
      cat "$table_name"
      echo -e "${BYellow}Press q to exit: ${Color_Off}"
      read -r exit
      if [ "$exit" == "q" ]; then
        clear
        break
      fi
    else
      echo -e "${BRed}Table does not exist!${Color_Off}"
      try_again
      continue
    fi
  done
}

# List Tables in Database
function list_tables {
  if [ "$(ls -A)" ]; then
    echo -e "${BBlue}Tables:${Color_Off}"
    echo -e " ${BGreen}$(ls -l | grep ^- | awk '{print $9}')${Color_Off}"
  else
    echo -e "${BYellow}No tables found!${Color_Off}"
  fi
}

# Drop Table from Database
function drop_table {
  read -r -p "Enter table name: " table_name
  if [ -f "$table_name" ]; then
    rm "$table_name"
    echo -e "${BGreen}Table dropped successfully!${Color_Off}"
  else
    echo -e "${BRed}Table does not exist!${Color_Off}"
  fi
}

# TODO: Delete from Table
function delete_from_table {
  echo ""
}

# TODO: Update Table
function update_table {
  echo ""
}

# Connect to Database, and all table operations
function connect_to_database {
  read -r -p "Enter database name: " db_name

  if [ -d "$db_name" ]; then
    PS3="Database Menu ($db_name):"
    cd "$db_name" || exit

    select choice in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Back to Main Menu"; do
      case $REPLY in
      1) create_table ;;
      2) list_tables ;;
      3) drop_table ;;
      4) insert_into_table ;;
      5) select_from_table ;;
      6) delete_from_table ;;
      7) update_table ;;
      8)
        cd ..
        PS3="Main Menu: "
        break
        ;;
      *) echo "Invalid choice!" ;;
      esac
    done
  else
    echo "${BRed}Database does not exist!${Color_Off}"
  fi
}

# Main Menu Function to display the main menu and handle user choices
function main_menu {
  PS3="Main Menu: "
  select choice in "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit"; do
    case $REPLY in
    1) create_database ;;
    2) list_databases ;;
    3) connect_to_database ;;
    4) drop_database ;;
    5) exit 0 ;;
    *) echo "Invalid choice!" ;;
    esac
  done

}

main_menu
