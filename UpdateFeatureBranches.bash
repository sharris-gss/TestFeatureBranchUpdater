#!/bin/bash

repositoryUrl="https://github.com/sharris-gss/TestFeatureBranchUpdater.git"
repository_name="TestFeatureBranchUpdater"
releaseBranchName="main"
branchDefiningCommit="cf07f42"
releaseVersion="2023.1"
webhook=""

get_all_related_branches () {
	branches=$( git branch --contains $branchDefiningCommit | tr '* ' ' ' )
	branches=( $branches )
}

get_all_in_testing_relevant_issues () {
	# get list of all issues
	local raw_issues=$(gh issue list --label "In Testing" --label "$releaseVersion")

	# split issues by line and take first element
	local oldIFS=$IFS
	IFS=$'\n' issueArray=( $raw_issues )
	IFS=$oldIFS

	# rip the issue # from the output and concatenate that to the return string
	local retIssue=""
	for issue in "${issueArray[@]}"
	do
		local currIssue=( $issue )
		retIssue+="${currIssue[0]} "
	done

	echo $retIssue
}

get_all_branches_to_update_from_issues () {
	# get all relevant issues
	local issues=$( get_all_in_testing_relevant_issues )
	# convert string into array
	local issueArray=( $issues )
	# for each issue in the array, get associated branches & concatenate to a string

	local retBranches=""

	for issue in "${issueArray[@]}"
	do
		retBranches+="$(gh issue develop --list $issue) "
	done

	echo $retBranches
}

# checkout_and_update_git_branch (branch_name)
checkout_and_update_git_branch () {
	git checkout $1
	git merge origin/$releaseBranchName -m "Merge $releaseBranchName into $1"
	statusCode="$?"
}

reset_git_checkout () {
	git reset --hard
	git clean -fxd
}

# push_branch (branch_name)
push_branch () {
	git push origin $1
}

# get_gss_email_from_github_name (github_username)
get_gss_email_from_github_name () {
	echo "${1%-gss}@gssmail.com"
}

# email_user (email_address, email_subject, email_message)
email_user () {
	echo "Email Address: $1"
	echo "Subject: $2"
	echo "Body: $3"
}

# email_gss_user_to_resolve_conflicts (github_user, branch_name)
email_gss_user_to_resolve_conflicts () {
	echo ""
	local gss_email=$( get_gss_email_from_github_name "$1" )
	local email_subject="Automatic Update Failed on branch $2"
	local email_message="Automatic update of branch $2 in the $repository_name repository failed. Resolve any conflicts and then update this branch manually from $devBranchName"

	email_user "$gss_email" "$email_subject" "$email_message"
	echo ""
}

# teams_post_backend (webhook_url, title, color, text)
teams_post_backend () {
	# Webhook or Token.
	local WEBHOOK_URL=$1
	if [[ "${WEBHOOK_URL}" == "" ]]
	then
	echo "No webhook_url specified."
	return 1
	fi
	shift

	# Title .
	local TITLE=$1
	if [[ "${TITLE}" == "" ]]
	then
	echo "No title specified."
	return 1
	fi
	shift

	# Color.
	local COLOR=$1
	if [[ "${COLOR}" == "" ]]
	then
	echo "No status specified."
	return 1
	fi
	shift

	# Text.
	local TEXT=$*
	if [[ "${TEXT}" == "" ]]
	then
	echo "No text specified."
	return 1
	fi

	# Convert formating.
	MESSAGE=$( echo ${TEXT} | sed 's/"/\"/g' | sed "s/'/\'/g" )
	JSON="{\"title\": \"$TITLE\", \"themeColor\": \"$COLOR\", \"text\": \"$MESSAGE\" }"

	# Post to Microsoft Teams.
	curl -X POST -H "Content-Type: application/json" -d "${JSON}" "${WEBHOOK_URL}"
}

# make_teams_post (branch_name)
make_teams_post () {	
	teams_post_backend "$webhook" "Automatic Update Failed on branch $1" "0" "Automatic update of branch $1 in the $repository_name repository failed. Resolve any conflicts and then update this branch manually from $releaseBranchName"
}

load_webhook_url () {
	# TODO: This is windows exclusive, figure out what to do for linux
	# webhook=$(cat "$(dirname $(readlink -f $0))/hidden_values.file")
	webhook=$(cat "C:/Temp/hidden_values.file")
	
}

# -----------------------------------------------------------------------------------------------------------------------
# Begin Script
# -----------------------------------------------------------------------------------------------------------------------

if [ $# -lt 5 ]; then
	# TODO: Add a more descriptive message and potentially a help page
	echo "Incorrect # of Arguments"
	exit 1
fi

if [ $# -ge 5 ]; then
	repository_name=$1
	releaseBranchName=$2
	branchDefiningCommit=$3
	releaseVersion=$4
	repositoryUrl=$5
fi

# TODO: decide if a fallback teams webhook is something desirable/is a teams webhook required
if [ $# -ge 6 ]; then
	webhook=$6
fi

echo "Repo Name: $repository_name"
echo "Release Branch: $releaseBranchName"
echo "Branch Defining Commit: $branchDefiningCommit"
echo "Release Version: $releaseVersion"
echo "Repository URL: $repositoryUrl"
echo "Webhook: $webhook"

# Determine if a directory exists for the current repo and release version
checkoutDirectory="./$repository_name-$releaseVersion"

if [ -d $checkoutDirectory ]; then
	# TODO: update this message
	echo "checkout directory exists, attempt to delete"
	rm -r -f "./$checkoutDirectory"
fi

mkdir "./$checkoutDirectory"
cd "./$checkoutDirectory"

echo $(pwd)

# Setup the local files for the git repo
git clone $repositoryUrl

echo $(pwd)
echo $(ls)

cd "$repository_name"

echo "Fetching latest Git changes"
git fetch

echo "Getting all related branches"
branches=$(get_all_branches_to_update_from_issues)

echo $branches

branches=( $branches )

for i in "${branches[@]}"
do
	echo ""

	if [ "$i" = "$releaseBranchName" ]; then
		echo "$i is the main branch, nothing to update"
	else 
		echo "Updating branch $i with changes from $releaseBranchName"
		checkout_and_update_git_branch "$i" > /dev/null 2>&1

		if [ $statusCode -eq 0 ]
		then
			echo "Merge Success"
			push_branch "$i" > /dev/null 2>&1
		else
			echo "Merge Failure"
			reset_git_checkout > /dev/null 2>&1
			
			make_teams_post "$i"
		fi
	fi
done

read -rsn1
