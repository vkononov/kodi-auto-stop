#!/bin/bash

# Set the Kodi host and port
KODI_HOST="localhost"
KODI_PORT="8080"

# Set the path to the file that will store the duration of the paused video
PAUSED_FILE="/tmp/kodi-minutes-paused.txt"

# Set the duration threshold in minutes
DURATION_THRESHOLD=30

# get the player ID
RESPONSE=$(curl -s -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 1}' http://$KODI_HOST:$KODI_PORT/jsonrpc)
PLAYER_ID=$(echo "$RESPONSE" | grep -o '"playerid":[0-9]*' | cut -d: -f2)

# if player ID is empty, the video is stopped
if [ "$PLAYER_ID" = "" ]; then
  if [ -f "$PAUSED_FILE" ]; then
    echo "0" > "$PAUSED_FILE"
  fi

  exit 0
fi

# Call the Player.GetProperties method to get the current player state
RESPONSE=$(curl -s -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "Player.GetProperties", "params": {"playerid": '"$PLAYER_ID"', "properties": ["speed", "time"]}, "id": 1}' http://$KODI_HOST:$KODI_PORT/jsonrpc)

# Parse the response to check if the video is paused or not playing
SPEED=$(echo "$RESPONSE" | grep -o '"speed":[0-9]*' | cut -d: -f2)

# extract the values of hours, milliseconds, minutes and seconds using grep and awk
HOURS=$(echo "$RESPONSE" | grep -o '"hours":[0-9]*' | awk -F: '{print $2}')
MILLISECONDS=$(echo "$RESPONSE" | grep -o '"milliseconds":[0-9]*' | awk -F: '{print $2}')
MINUTES=$(echo "$RESPONSE" | grep -o '"minutes":[0-9]*' | awk -F: '{print $2}')
SECONDS=$(echo "$RESPONSE" | grep -o '"seconds":[0-9]*' | awk -F: '{print $2}')

# calculate the sum of the values
VIDEO_DURATION=$((HOURS + MILLISECONDS + MINUTES + SECONDS))

if [ "$SPEED" -eq 0 ] && [ $VIDEO_DURATION -gt 0 ]; then
  # Video is paused, increment the paused duration in the file
  if [ -f "$PAUSED_FILE" ]; then
    # The paused file exists, read the current duration and increment it
    PAUSED_DURATION=$(cat "$PAUSED_FILE")
    PAUSED_DURATION=$((PAUSED_DURATION + 1))

    # Check if the paused duration has exceeded the duration threshold
    if [ "$PAUSED_DURATION" -ge "$DURATION_THRESHOLD" ]; then
      # Send a stop command to Kodi
      curl -s -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "Player.Stop", "params": {"playerid": '"$PLAYER_ID"'}, "id": 1}' http://$KODI_HOST:$KODI_PORT/jsonrpc > /dev/null 2>&1

      # Reset the paused duration to 0
      echo "0" > "$PAUSED_FILE"
      exit
    fi
  else
    # The paused file doesn't exist, create it and set the duration to 1
    touch "$PAUSED_FILE"
    PAUSED_DURATION=1
  fi

  # Write the updated duration to the paused file
  echo "$PAUSED_DURATION" > "$PAUSED_FILE"
else
  # Video is not paused, reset the paused duration to 0 if the file exists
  if [ -f "$PAUSED_FILE" ]; then
    echo "0" > "$PAUSED_FILE"
  fi
fi
