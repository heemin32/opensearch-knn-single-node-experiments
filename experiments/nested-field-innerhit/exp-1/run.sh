#!/bin/bash

set -xe

# Simple wrapper script
#
# Usage:
# **Note - this needs to be run from the root of the project for now...**
#
# bash experiments/nested-field-innerhit/run.sh <branch> <engine>
#
#
# Params:
#   branch: knn branch
#   engine: faiss or lucene
BRANCH=$1
ENGINE=$2

# Constants
EXPERIMENT_PATH="experiments/nested-field-innerhit/exp-1"
BASE_ENV_PATH="${EXPERIMENT_PATH}/env/${BRANCH}"
INDEX_ENV_PATH="${BASE_ENV_PATH}/index-build.env"
SEARCH_ENV_PATH="${BASE_ENV_PATH}/search.env"
OSB_PARAMS_PATH="osb/custom/params"
PARAMS_PATH="${EXPERIMENT_PATH}/osb-params"
TMP_ENV_DIR="${EXPERIMENT_PATH}/tmp"
TMP_ENV_NAME="test.env"
TMP_ENV_PATH="${EXPERIMENT_PATH}/${TMP_ENV_NAME}"

source ${EXPERIMENT_PATH}/functions.sh
OSB_INDEX_PROCEDURE="no-train-test-index-with-merge"

# Copy params to OSB folder
cp ${PARAMS_PATH}/${ENGINE}.json ${OSB_PARAMS_PATH}/

# Initialize shared data folder for containers
mkdir -m 777 /tmp/share-data

setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "index-build-${ENGINE}-${BRANCH}" ${ENGINE}.json ${OSB_INDEX_PROCEDURE} false
docker compose --env-file ${INDEX_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d

wait_for_container_stop osb
setup_environment ${TMP_ENV_DIR} ${TMP_ENV_NAME} "search-${ENGINE}-${BRANCH}" ${ENGINE}.json "search-only" true
docker compose --env-file ${SEARCH_ENV_PATH} --env-file ${TMP_ENV_PATH} -f compose.yaml up -d
clear_cache

# Add at the end to ensure container finishes
wait_for_container_stop osb

echo "Finished all runs"
