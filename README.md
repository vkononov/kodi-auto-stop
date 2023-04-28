
# Kodi Auto Stop

This CRON script stops the Kodi player if left paused for an extended time to save energy and extend equipment life.

## Rationale

When using Kodi 19 or later, leaving a video paused can interfere with other functions, such as the screen saver and CEC commands that turn off the TV when there is no activity detected. As a result, a paused video can keep the TV on indefinitely. To prevent this, this script can detect and stop any paused video that has been inactive for an extended period, enabling other Kodi features to operate correctly.

## How It Works

The script is intended to be run every 60 seconds as a CRON job. On each run, it checks whether a Kodi video player is paused and tracks the duration of the pause time in a local file. If the pause time exceeds a set threshold, the script sends a command to Kodi to stop the player, effectively preventing it from keeping the TV on indefinitely.

## Limitations

It's worth noting that if someone were to repeatedly pause and resume the video in such a way that the video is always paused at the 00 seconds mark, the script may incorrectly calculate the accumulated amount of paused duration. However, this scenario is relatively unlikely unless you have a child or other individual who enjoys repeatedly clicking the pause button on the remote control.

## Prerequisites

This script was originally written for LibreELEC, which runs on a Raspberry Pi. Other operating systems and hardware have not been tested.

* Allow Remote Control via HTTP is enabled
* Remote Control authentication is turned off
* SSH access to local machine to update CRON

## Usage

1. Download the `kodi-auto-stop.sh` script somewhere onto your local machine.

2. Modify the variables within the script to suit your needs. Current defaults are:

   ```bash
   # Set the Kodi host and port
   KODI_HOST="localhost"
   KODI_PORT="8080"

   # Set the path to the file that will store the duration of the paused video
   PAUSED_FILE="/tmp/kodi-minutes-paused.txt"

   # Set the duration threshold in minutes
   DURATION_THRESHOLD=30
   ```

3. Install the script as a CRON job to run every minute.

   ```bash
   * * * * * sh $HOME/.kodi-auto-stop.sh
   ```
