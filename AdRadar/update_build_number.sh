#!/bin/bash

# Get the current date in YYYYMMDD format
DATE=$(date +%Y%m%d)

# Get the number of commits for today
COMMIT_COUNT=$(git rev-list --count --since="midnight" HEAD)

# Combine date and commit count to create build number
BUILD_NUMBER="${DATE}${COMMIT_COUNT}"

# Update the build number in the project
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "${PROJECT_DIR}/${INFOPLIST_FILE}"

echo "Updated build number to $BUILD_NUMBER" 