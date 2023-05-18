releaseBranchName="main"
branchDefiningCommit="cf07f42"

devBranchName="dev"

output=$( git checkout $devBranchName )
output+=$( git merge origin/$releaseBranchName -m "Merge $releaseBranchName into $devBranchName" )
output+=$( git push origin $devBranchName )

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
			output+=$( git checkout $i )
			output+=$( git merge origin/$devBranchName -m "Merge $devBranchName into $i" )
			if [ $? -eq 0 ]; then
				echo "Merge Success"
			else
				echo "Merge Failure"
				output+=$( git reset --hard )
				output+=$( git clean -fxd )	
			fi

			output+=$( git push origin $i )
		fi
	fi
done

echo $output
