releaseBranchName="main"
branchDefiningCommit="cf07f42"

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
			
			if $(git merge origin/$devBranchName); then
				echo "Merge Success"
			else
				echo "Merge Failure"
				$( git reset --hard )
				$( git clean -fxd )	
			fi

			$(git push origin $i)
		fi
	fi
done
