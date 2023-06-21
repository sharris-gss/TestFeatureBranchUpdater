releaseBranchName="main"
branchDefiningCommit="cf07f42"
devBranchName="dev"

get_all_related_branches () {
	branches=$( git branch --contains $branchDefiningCommit | tr '* ' ' ' )
	branches=( $branches )
}

checkout_and_update_git_branch () {
	git checkout $1
	git merge origin/$devBranchName -m "Merge $devBranchName into $1"
	statusCode="$?"
}

reset_git_checkout () {
	git reset --hard
	git clean -fxd
}

update_dev_branch () {
	git checkout $devBranchName
	git merge origin/$releaseBranchName -m "Merge $releaseBranchName into $devBranchName"
	git push origin $devBranchName
}

push_branch () {
	git push origin $1
}

update_dev_branch >&-

get_all_related_branches >&-

for i in "${branches[@]}"
do
	if [ "$i" = "$releaseBranchName" ]; then
		echo "$i is the main branch, nothing to update"
	else 
		if [ "$i" = "$devBranchName" ]; then
			echo "$i is the development branch, already updated"
		else
			echo "Updating branch $i with changes from $devBranchName"

			checkout_and_update_git_branch "$i" >&-

			if [ $statusCode -eq 0 ]
			then
				echo "Merge Success"
			else
				echo "Merge Failure"
				
				reset_git_checkout >&-
			fi

			push_branch "$i" >&- 2>&1
		fi
	fi
done
