#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Copyright (C) 2008 - 2014 Computer Architecture Group @ Uni. Heidelberg <http://ra.ziti.uni-heidelberg.de>
#

package provide odfi::git 1.0.0
package require odfi::files

namespace eval odfi::git {

	## @return true if the folder is in a git repository
	proc isGitFolder path {

		odfi::files::inDirectory $path {

			catch {exec -ignorestderr git status > /dev/null 2> /dev/null} res resOptions

		}

		set dir [pwd]
		cd $path 
		
		cd $dir

		#puts "Result for $path: $res"

		## Get Error
		if {[dict exists $resOptions -errorcode]} {
			return false
		}

		return true

	}


	## Just Clone!
	proc clone {url path args} {

		exec mkdir -p $path

		## Git will result 1 here on success, causing error
		catch {
			puts [eval "exec -ignorestderr git clone $url $path"]
		} res resOptions

		## Get Error
		if {[dict exists $resOptions -errorcode]} {
			error "Cloning Failed with error: $res"
		}

		#puts "Clone res: [dict get $resOptions -errorcode]"

	}

	## Just pull
	proc pull {path args} {

		set cdir [pwd]
		cd $path
		catch {
			puts [eval "exec -ignorestderr git pull $args"]
		} res resOptions
		cd $cdir

		## Get Error
		if {[dict exists $resOptions -errorcode]} {
			#puts "Pull Failed: $res"
			error "Pulling Failed with error: $res"
		}
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
		regexp -line {^\s*\*\s*([\w\-\.]+)\s*$} $branchesOutput -> currentBranch

		return $currentBranch

	}

	## @return 1 if not local modifications are present, 0 otherwise
	proc isClean repositoryPath {

		## Get Output
		set cdir [pwd]
		cd $repositoryPath
		set statusOutput [exec git status --porcelain -uno]
		cd $cdir

		## Return
		if {$statusOutput==""} {
			return true
		} else {
			return false
		}

		#puts "is clean output: $statusOutput"

	}


	## Add a remote or set its url
	proc set-remote {repositoryPath name url} {

		set cdir [pwd]
		cd $repositoryPath

		## Delete
		catch {exec git remote set-url --delete $name $url}

		## Add
		catch {exec git remote add $name $url}

		cd $cdir

	}
}
