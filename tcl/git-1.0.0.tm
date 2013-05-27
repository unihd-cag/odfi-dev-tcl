package provide odfi::git 1.0.0


namespace eval odfi::git {


	## Just Clone!
	proc clone {url path args} {

		## Git will result 1 here on success, causing error
		catch {
			puts [exec git clone $url $path ]
		} res resOptions

		#puts "Clone res: [dict get $resOptions -errorcode]"

	}

	## Just pull
	proc pull {path args} {

		set cdir [pwd]
		cd $path
		puts [exec git pull $args]
		cd $cdir
	}

	## Return the list of branches of remotes
	## @return a list lik: {remote {branch branch} remote {branch branch}}
	proc list-remote-branches repositoryPath {

		## Get branches
		set cdir [pwd]
		cd $repositoryPath
		set branchesOutput [exec git branch -a]
		cd $cdir

		## Keep all the 'remotes/remoteName/branchName' lines
		set branches [regexp -inline -all -line {^\s*remotes/([\w]+)/([\w]+)\s*$} $branchesOutput]
		set branchesResult {}
		foreach {match remoteName branchName} $branches {

			set branchesResult [odfi::list::arrayConcat $branchesResult $remoteName $branchName]

		}

		return $branchesResult

	}

	## Return the name of the current checked out branch of repository
	proc current-branch repositoryPath {

		## Get branches
		set cdir [pwd]
		cd $repositoryPath
		set branchesOutput [exec git branch]
		cd $cdir

		## Keep only the one with * at lin begining
		regexp -line {^\s*\*\s*([\w\.]+)\s*$} $branchesOutput -> currentBranch

		return $currentBranch

	}
}
