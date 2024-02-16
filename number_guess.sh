#!/bin/bash

DB_CONFIG() {
  echo -e "\nSetting database...\n"

  PSQL="sudo -i -u postgres psql salon --tuples-only -c"

  EXISTS_DB=$($PSQL "SELECT 1 FROM pg_database WHERE datname='number_guess';")

  if [[ -z $EXISTS_DB ]]
  then
    echo -e "\nCreating database...\n"
    DB_CREATE=$(sudo -u postgres psql --tuples-only -c "CREATE DATABASE number_guess;")
    $(sudo -u postgres psql number_guess < db/number_guess.sql)
  fi
  echo -e "\nDatabase is ready!\n"
}

HANDLE_USERNAME() {
  echo -e "\nEnter your username:\n"
  read USERNAME

  USER=$($PSQL "SELECT * FROM users WHERE username='$USERNAME';")

  if [[ -z $USER ]]
  then
    REGISTER_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here.\n"
  else
    echo $USER | while read USER_NAME B GAMES_PLAYED B BEST_GAME
    do
      echo -e "\nWelcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.\n"
    done
  fi
}

NUMBER_OF_GUESSES=0
MIN_NUM=0
MAX_NUM=1000
RANDOM_NUM=$(shuf -i $MIN_NUM-$MAX_NUM -n 1)

PLAY_GUESSING() {
  if [[ -z $1 ]]
  then
    echo -e "\nGuess the secret number between 1 and 1000:\n"
  else
    echo -e "\n$1\n"
  fi

  read GUESS

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    PLAY_GUESSING "That is not an integer, guess again:"
  fi

  NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))

  if [[ "$GUESS" -eq "$RANDOM_NUM" ]]
  then
    echo -e "\nYou guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUM. Nice job!\n"
    UPDATE_USER
  elif [[ "$GUESS" -lt "$RANDOM_NUM" ]]
  then
    PLAY_GUESSING "It's higher than that, guess again:"
  elif [[ "$GUESS" -gt "$RANDOM_NUM" ]]
  then
    PLAY_GUESSING "It's lower than that, guess again:"
  fi
}

UPDATE_USER() {
  BEST_GAME=$(echo $USER | rev | cut -d ' ' -f 1 | rev)

  if [[ "$BEST_GAME" -eq "0" || "$NUMBER_OF_GUESSES" -lt "$BEST_GAME" ]]
  then
    UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME';")
  fi

  UPDATE_GAMES=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username = '$USERNAME'")
}

START() {
  DB_CONFIG
  HANDLE_USERNAME
  PLAY_GUESSING
}
START
