#!/bin/bash

#-------------------------------------------------#
#   Log Archive Cli tool                          #
#                                                 #
# Usage:                                          #
#   ./log-archive.sh <log_directory_to_archive>   #
#                                                 #
#-------------------------------------------------#

# Check if directory name is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: ./log-archive.sh <log_directory_to_archive>"
    exit 1
fi

# Check if the provided input log directory exists
if [ ! -d "$1" ]; then
    echo "Error: Log directory $1 does not exist."
    exit 1
fi

LOG_DIRECTORY="$1"

# Create target log archive directory if it doesn't exist
ARCHIVE_DIRECTORY="$LOG_DIRECTORY/archive"
mkdir -p "$ARCHIVE_DIRECTORY"

# Archive file timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Archive filename
ARCHIVE_FILE="logs_archive_${TIMESTAMP}.tar.gz"

# Create archive
if command -v tar &> /dev/null; then
    tar -czf "${ARCHIVE_DIRECTORY}/${ARCHIVE_FILE}" -C "$LOG_DIR" . --exclude="archive"
else
    echo "Command 'tar' not available."
fi

# Log the action
LOG_FILE="${ARCHIVE_DIRECTORY}/archive_history.log"
echo "Archived at $(date +"%Y-%m-%d %H:%M:%S") → ${ARCHIVE_FILE}" >> "$LOG_FILE"

echo "Logs archived successfully:"
echo "  → ${ARCHIVE_DIRECTORY}/${ARCHIVE_FILE}"
echo "Log entry added to:"
echo "  → ${LOG_FILE}"
