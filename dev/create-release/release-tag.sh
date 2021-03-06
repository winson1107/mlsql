#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

SELF=$(cd $(dirname $0) && pwd)
. "$SELF/release-util.sh"

function exit_with_usage {
  cat << EOF
usage: tag-release.sh
Tags a Spark release on a particular branch.
Inputs are specified with the following environment variables:
GIT_NAME - Name to use with git
GIT_EMAIL - E-mail address to use with git
GIT_BRANCH - Git branch on which to make release
RELEASE_VERSION - Version used in pom files for release
RELEASE_TAG - Name of release tag
NEXT_VERSION - Development version after release
EOF
  exit 1
}

set -e
set -o pipefail

if [[ $@ == *"help"* ]]; then
  exit_with_usage
fi

for env in RELEASE_VERSION RELEASE_TAG NEXT_VERSION GIT_EMAIL GIT_NAME GIT_BRANCH; do
  if [ -z "${!env}" ]; then
    echo "$env must be set to run this script"
    exit 1
  fi
done

init_java
init_maven_sbt

MLSQL_HTTPS_REPO="https://github.com/allwefantasy/streamingpro.git"
MLSQL_GIT_REPO="git@github.com:allwefantasy/streamingpro.git"

rm -rf streamingpro
git clone "$MLSQL_GIT_REPO" -b $GIT_BRANCH
cd streamingpro

git config user.name "$GIT_NAME"
git config user.email $GIT_EMAIL

# Create release version
$MVN versions:set -DnewVersion=$RELEASE_VERSION | grep -v "no value" # silence logs

git commit -a -m "Preparing MLSQL release $RELEASE_TAG"
echo "Creating tag $RELEASE_TAG at the head of $GIT_BRANCH"
git tag $RELEASE_TAG

# Create next version
$MVN versions:set -DnewVersion=$NEXT_VERSION | grep -v "no value" # silence logs

git commit -a -m "Preparing development version $NEXT_VERSION"

if ! is_dry_run; then
  # Push changes
  git push origin $RELEASE_TAG
  git push origin HEAD:$GIT_BRANCH

  cd ..
  rm -rf streamingpro
else
  cd ..
  mv streamingpro streamingpro.tag
  echo "Clone with version changes and tag available as streamingpro.tag in the output directory."
fi