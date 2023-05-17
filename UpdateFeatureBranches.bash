releaseBranchName="main"
branchDefiningCommit=""

devBranchName="dev"

$(git checkout $devBranchName)
$(git merge origin/$releaseBranchName)
$(git push origin $devBranchName)

branches=$(git branch --contains $branchDefiningCommit | tr '* ' ' ')
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
			$(git checkout $i)
			$(git merge origin/$devBranchName)
			$(git push origin $i)
		fi
	fi
done
