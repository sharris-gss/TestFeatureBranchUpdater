releaseBranchName="main"
branchDefiningCommit="cf07f42"

devBranchName="dev"

statusCode=0

checkout_and_update_git_branch () {
	git checkout $1 | cat
	git merge origin/$devBranchName -m "Merge $devBranchName into $1" | cat
	statusCode="$?"
}

reset_git_checkout () {
	git reset --hard | cat
	git clean -fxd | cat
}

update_dev_branch () {
	git checkout $devBranchName | cat
	git merge origin/$releaseBranchName -m "Merge $releaseBranchName into $devBranchName" | cat
	git push origin $devBranchName | cat
}

update_dev_branch >&2

branches=$( git branch --contains $branchDefiningCommit | tr '* ' ' ' )
branches=( $branches )

for i in "${branches[@]}"
do
	if [ "$i" = "$releaseBranchName" ]; then
		echo "$i is the main branch, nothing to update"
	else 
		if [ "$i" = "$devBranchName" ]; then
			echo "$i is the development branch, already updated"
		else
			echo "Updating branch $i with changes from $devBranchName"

			checkout_and_update_git_branch "$i" >&2

			if [ $statusCode -eq 0 ]
			then
				echo "Merge Success"
			else
				echo "Merge Failure"
				
				reset_git_checkout >&2
			fi

			output+=$( git push origin $i )
		fi
	fi
done

echo $output
