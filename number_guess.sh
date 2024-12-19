#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read NAME
NAME=$(echo "$NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
SEARCH_NAME_RESULT=$($PSQL "SELECT games_played, best_game FROM guess_info WHERE username = '$NAME';")
IFS='|' read -r games_played best_game <<< "$SEARCH_NAME_RESULT"
if [[ -z $SEARCH_NAME_RESULT ]]
then
  echo "Welcome, $NAME! It looks like this is your first time here."
  INSERT_NEW_USER_RESULT=$($PSQL "INSERT INTO guess_info (username) VALUES ('$NAME');")
else
  RESULT="Welcome back, $NAME! You have played $games_played games, and your best game took $best_game guesses."
  echo "$games_played $best_game"
  echo $RESULT
fi

SECRET_NUMBER=$((RANDOM % 1000 + 1))
GUESS_TRIES=0
echo $SECRET_NUMBER

CHECK_INT() {
  read GUESS_NUMBER
  until [[ $GUESS_NUMBER =~ ^[0-9]+$ ]]
  do
    echo "That is not an integer, guess again:"
    read GUESS_NUMBER
  done
  ((GUESS_TRIES++))
}

echo "Guess the secret number between 1 and 1000:"
CHECK_INT

until [[ $SECRET_NUMBER -eq $GUESS_NUMBER ]]
do
  if [[ $SECRET_NUMBER -gt $GUESS_NUMBER ]]; then
    echo "It's higher than that, guess again:"
    CHECK_INT
  elif [[ $SECRET_NUMBER -lt $GUESS_NUMBER ]]; then
    echo "It's lower than that, guess again:"
    CHECK_INT
  fi
done

echo "You guessed it in $GUESS_TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
((games_played++))

if [[ -z $best_game ]]; then
  UPDATE_GAME_PLAYED=$($PSQL "UPDATE guess_info SET best_game = $GUESS_TRIES WHERE username='$NAME';")
fi
if [[ -z $games_played ]]; then
  UPDATE_GAME_PLAYED=$($PSQL "UPDATE guess_info SET best_game = $games_played WHERE username='$NAME';")
fi
if [[ $best_game -gt $GUESS_TRIES ]]; then
  UPDATE_GAME_PLAYED=$($PSQL "UPDATE guess_info SET games_played = $games_played, best_game = $GUESS_TRIES WHERE username='$NAME';")
else
  UPDATE_GAME_PLAYED=$($PSQL "UPDATE guess_info SET games_played = $games_played WHERE username='$NAME';")
fi