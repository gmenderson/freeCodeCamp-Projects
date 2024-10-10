#!/bin/bash

# Database name
DB_NAME="number_guess"
PSQL="psql --username=freecodecamp --dbname=$DB_NAME -t --no-align -c"

# Function to get user data
get_user_data() {
    local username="$1"
    # Check if user exists
    user_data=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$username'")
    echo "$user_data"
}

# Function to insert new user
insert_user() {
    local username="$1"
    $PSQL "INSERT INTO users(username) VALUES('$username')" > /dev/null  # Suppress output
}

# Function to update user stats
update_user_stats() {
    local username="$1"
    local guesses="$2"
    # Update user stats
    $PSQL "UPDATE users SET games_played = games_played + 1, best_game = COALESCE(LEAST(best_game, $guesses), $guesses) WHERE username = '$username'" > /dev/null  # Suppress output
}

# Function to insert game stats
insert_game_stats() {
    local username="$1"
    local guesses="$2"
    local user_id=$($PSQL "SELECT user_id FROM users WHERE username = '$username'")
    $PSQL "INSERT INTO games(user_id, guesses) VALUES($user_id, $guesses)" > /dev/null  # Suppress output
}

# Generate a random number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Ask for username
echo "Enter your username:"
read username

# Get user data
user_data=$(get_user_data "$username")

# Check if user exists
if [[ -z "$user_data" ]]; then
    echo "Welcome, $username! It looks like this is your first time here."
    insert_user "$username"
else
    IFS='|' read games_played best_game <<< "$user_data"
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

# Start guessing game
echo "Guess the secret number between 1 and 1000:"
number_of_guesses=0

while true; do
    read guess
    number_of_guesses=$((number_of_guesses + 1))

    if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
        echo "That is not an integer, guess again:"
        continue
    fi

    if [[ "$guess" -lt "$SECRET_NUMBER" ]]; then
        echo "It's higher than that, guess again:"
    elif [[ "$guess" -gt "$SECRET_NUMBER" ]]; then
        echo "It's lower than that, guess again:"
    else
        echo "You guessed it in $number_of_guesses tries. The secret number was $SECRET_NUMBER. Nice job!"
        insert_game_stats "$username" "$number_of_guesses"
        update_user_stats "$username" "$number_of_guesses"
        break
    fi
done
