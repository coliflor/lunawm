#!/bin/bash
# Helper script for sending commands to lunawm, requires socat to be installed

# Define the path to the lunawm_control socket.
SOCKET_PATH="$HOME/Proyectos/lunawm/lunawm/ipc/lunawm_control"

# Check if at least one argument is provided.
if [ $# -eq 0 ]; then
		echo "Usage: $0 <command> [arguments...]"
		exit 1
fi

# Construct the command string from the arguments.
COMMAND="$*"

# Send the command to the lunawm_control socket using socat and capture the output.
OUTPUT=$(echo "$COMMAND" | socat - UNIX-CONNECT:"$SOCKET_PATH")

# Check if the output is "OK".
if [ "$OUTPUT" = "OK" ]; then
		echo "Command sent successfully."
		exit 0
else
		echo "Command failed or returned unexpected output."
		exit 1
fi
