# No whitespace before\after =
MY_EMAIL='@'

# bash_utils
# various
# git docker mail 
# files/folders media pdf zip

###################################################################
function update_bash_utils() 
{
  cd ~ 
  rm bash_utils/ -rf 
  git clone https://github.com/ofirpele/bash_utils.git
  dos2unix bash_utils/* 
  mv -f ~/.bashrc ~/.bashrc_old
  echo source $PWD/bash_utils/bashrc.sh > ~/.bashrc 
  echo source $PWD/bash_utils/aliases.sh >> ~/.bashrc  
  cd -
  bash
}
###################################################################


###################################################################
# various
###################################################################
# calculator use [] instead of ()
function c() 
{ 
  local in="$(echo " $*" | sed -e 's/\[/(/g' -e 's/\]/)/g')";
  gawk -M -v PREC=201 -M 'BEGIN {printf("%.60g\n",'"${in-0}"')}' < /dev/null
  #calc "$@"
}

alias cl='clear'

alias fixshell='echo -ne "\\017"'

function computersleep() 
{
 xset dpms force off
}

function g++d() 
{
  g++ -Wall -Wvla -Werror -g -D_GLIBCXX_DEBUG -std=c++2a "$@" 
}

function g++o() 
{
  g++ -O -DNDEBUG -std=c++2a "$@" 
}

function do_x_times()
{
    for (( c=1; c<=$1; c++ ))
    do 
        "${@:2}"
    done
}

#alias suspendall='stop %1 %2 %3 %4 %5 %6 %7 %8 %9 %10 %11 %12'

#alias continueall='bg %1 %2 %3 %4 %5 %6 %7 %8 %9 %10 %11 %12'

alias diskinfo='lsblk -o MODEL,SIZE,NAME -d'

alias nvidiagpuinfo='nvidia-smi -L'
###################################################################


###################################################################
# git
###################################################################

#####################################
# git: starting a project
#####################################
function git_clone_project()
{
  if [[ ($# -ne 1 && $# -ne 2) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} URL <branch>" >&2
    return 2
  fi
  if [[ ($# -eq 1) ]]; then
    git clone --recurse-submodules -j8 "${1}"
  else
    git clone -b "${2}" --recurse-submodules -j8 "${1}"
  fi
  cd "$(basename "${1}" .git)"
  git submodule update --remote
  git submodule foreach --recursive git checkout main
  git submodule foreach --recursive git pull origin main
}

# function git_create_new_python_project()
# {
#   if [ -d "$1" ]; then
#     echo "$1 folder exists, please rm it before running this command or give another folder name" >&2
#     return 2
#   fi
#   local full_new_path="$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
#   git config --global --add safe.directory "$full_new_path"
#   if [[ ($# -ne 2) && ($# -ne 3) ]]; then
#     echo "Illegal number of parameters" >&2
#     echo "usage:" >&2
#     echo "${FUNCNAME[0]} folder_name URL <no_ofirpele_utils/anything_else>" >&2
#     return 2
#   fi
#   git clone TODO/python_example.git "$1"
#   cd "$1"
#   rm ofirpele_utils/ -rf
#   rm .git/ -rf
#   git init
#   git add --all
#   echo $#
#   if [[ ($# -ne 3) || "$3" != "no_ofirpele_utils" ]]; then
#     git__submodule_add main TODO/ofirpele_utils.git
#   fi
#   git remote add origin "$2"
#   git commit -m "Initial Commit"
#   git push -u origin main
# }
#####################################

#####################################
# git: regular workflow
#####################################
function git_add_all_commit_pull_and_push()
{
   if (( $# < 1 )); then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} comment" >&2
    echo "" >&2
    echo "comment can contain several words" >&2
    return 2
  fi
  echo "Adding all:"
  git add --all
  echo ""
  echo "Committing:"
  git commit -m"$(echo -e "$*")"
  echo ""
  echo "Pulling:"
  git_pull
  echo ""
  echo "Fixing conflicts if any:"
  git mergetool
  git add --all
  git commit -m"$(echo -e "Merge\n$*")"
  echo ""
  echo "Pushing:"
  git push
}

function git_pull()
{
  if [[ ($# -ne 0) ]]; then
    echo "No parameters should be given" >&2
    return 2
  fi
  git submodule foreach --recursive git pull
  git pull
}

function git_status()
{
  if [[ ($# -ne 0) ]]; then
    echo "No parameters should be given" >&2
    return 2
  fi
  git submodule foreach --recursive git status
  git status
}

function git_checkout()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} tag_name/branch_name" >&2
    return 2
  fi
  git checkout "$@"
}

function git_merge_remote_branch_to_this_remote_branch()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} branch_name" >&2
    return 2
  fi
  echo "Pulling to this branch:"
  git_pull
  this_branch=$(parse_git_branch)
  echo ""
  echo "Pulling to "$1" branch:"
  git checkout "$1"
  git_pull
  git checkout "$this_branch"
  echo ""
  echo "Merging:"
  git merge "$1" --no-edit
  echo "Fixing conflicts if any:"
  git mergetool
  git add --all
  git commit -m"$(echo -e "Merge\n$*")"
  echo ""
  echo "Pushing:"
  git push
}

function git_cd_top_level()
{
  local gitdir
  gitdir="$(git rev-parse --git-dir)"
  if [ "$gitdir" == "." ]; then
    # assuming top level is just above the git dir (.git)
    cd ..
  else
    cd "$(git rev-parse --show-toplevel)"
  fi
}

function git_diff_local_commit_to_remote()
{
  if [[ ($# -ne 0) ]]; then
    echo "No parameters should be given" >&2
    return 2
  fi

  this_branch=$(parse_git_branch)
  git fetch origin "$this_branch" &>/dev/null

  git difftool "$this_branch" origin/"$this_branch" --dir-diff
}

function git_diff_workspace_to_remote_same_commit()
{
  if [[ ($# -ne 0) ]]; then
    echo "No parameters should be given" >&2
    return 2
  fi

  git_status_output=$(git status | grep behind)
  if [[ -n "$git_status_output" ]]; then
    echo "$git_status_output"
    echo "Suggesting to run git_pull before this command"
    echo "Or\and git_diff_local_commit_to_remote to review changes"
    echo ""
  fi

  this_branch=$(parse_git_branch)
  git fetch origin "$this_branch" &>/dev/null

  echo "-------------------------------------------------------------------"
  echo "New files and non-empty directories:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  '??' | cut -d\  -f2-)
  do
    echo "$file"
  done
  echo "-------------------------------------------------------------------"

  echo ""

  echo "-------------------------------------------------------------------"
  echo "Deleted:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  'D' | cut -d\  -f3-)
  do
    echo "$file"
  done
  echo "-------------------------------------------------------------------"

  echo ""

  echo "-------------------------------------------------------------------"
  echo "New files and non-empty directories:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  'R' | cut -d\  -f3-)
  do
    echo "$file"
  done
  for file in $(git status --short| grep  'T' | cut -d\  -f3-)
  do
    echo "$file"
  done
  echo "-------------------------------------------------------------------"

  echo ""

  echo "-------------------------------------------------------------------"
  echo "Modified files:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  'M' | cut -d\  -f3-)
  do
    echo "$file"
    git difftool FETCH_HEAD "$file"
  done
  echo "-------------------------------------------------------------------"
}

function git_diff_commit_or_branch_to_this_branch()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} commit/branch" >&2
    return 2
  fi
  this_branch=$(parse_git_branch)
  git difftool "$1" origin/"$this_branch" --dir-diff
}

function git_tag_ls()
{
  if [[ ($# -ne 0) ]]; then
    echo "No parameters should be given" >&2
    return 2
  fi
  git tag -l --format='%(creatordate:short) %(refname:short)' --sort=creatordate
}

function git_tag()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} tag_name" >&2
    return 2
  fi
  git tag "$@"
  git push --tags
}

function git_tag_delete()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} tag_name" >&2
    return 2
  fi
  git tag -d "$@"
  git push --delete origin "$@"
  git remote prune origin
}

#####################################
# git: not regular workflow
#####################################
function git__submodule_add()
{
  if [[ ($# -ne 2) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} branch URL" >&2
    return 2
  fi
  git submodule add -b "$1" "$2"
}

function git__pull_hard()
{
    if [[ ($# -ne 1) || "$1" != "verify" ]]; then
      echo "Usage: ${FUNCNAME[0]} verify   will get you back to the last remote commit" >&2
      return 2
    fi
    git reset --hard
    #git submodule foreach --recursive git reset --hard
    git_pull
}

function git__push_revert_back_to_commit()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} commit_id" >&2
    return 2
  fi
  git checkout -f "$1" -- .
  git commit -a -m "reverting back to commit "$1""
  git push
}

function git__change_last_commit_message()
{
  if [[ ($# -lt 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} commit message" >&2
    return 2
  fi
  git commit --amend -m"$(echo -e "$*")"
  git push --progress origin --force
}

function git__project_name()
{
  if [[ ($# -ne 1) ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} URL" >&2
    return 2
  fi
  local foldername=${1%.git}
  local foldername=$(basename "${foldername}")
  echo "${foldername}"
}

function git__howto_windows_change_github_user_credentials()
{
  echo "
Search for Control panel and open it
- Search for Credential Manager and open it
- Click on Windows Credentials (logo of screen near safe)
- Under Generic Credentials (the long list) click on git:https://githubn.com
- Click on Remove and then confirm by clicking Yes button
- Now start pushing the code and you will get GitHub popup to login again
"
}
#####################################

##############################################################


###################################################################
# docker
###################################################################

function op_docker_run_common_flags() 
{
	local ret="\
		-e RUNS_ON_DOCKER=true \
		--rm \
		--privileged=true \
		-v $PWD/../output/:/output/ \
		-v $PWD/../data/:/data/ \
		-v $PWD/../config/:/config/ \
		-v /:/top/ \
		--net=host \
		"
	echo "$ret"
}

function docker_out() 
{
    echo "=============================================="
    cat output/stdout_stderr_local_filenames.txt
    echo "=============================================="
    cat output/stdout_stderr_local_filenames.txt | xargs cat
    echo "=============================================="
}

# usage: 
# docker_run params_to_script
# The image name is the basename of current pwd converted to lowercase
function docker_run() 
{
	docker_run_name	$(basename_pwd_lower_case) $@
}

# usage:
# see docker_run
function docker_run_foreground() 
{
	docker_run_foreground_name $(basename_pwd_lower_case) $@
}

# usage:
# docker_run_name image_name params_to_script
function docker_run_name() 
{
  rm -f output/stdout_stderr_local_filenames.txt
	sudo docker run -d -e REDIRECT_OUTPUT=true $(op_docker_run_common_flags) $@
	sleep 3
	echo
    if test -f output/stdout_stderr_local_filenames.txt; then
        docker_out
    else
        echo "output was not created"
        echo "Check that you have ofirpele_utils.py and default_imports.py"
        echo "Check that the first line of your python run script is from default_imports import *"
        echo "Running docker_run_foreground_name $@"
        echo
        docker_run_foreground_name $@
    fi
}

# usage:
# see docker_run_name
function docker_run_foreground_name() 
{
	sudo docker run $(op_docker_run_common_flags) $@
}

# usage: docker_build
# The image name is the basename of current pwd converted to lowercase
function docker_build() 
{
	sudo docker build -t $(basename_pwd_lower_case) . 
}

# usage: docker_build_run
# The image name is the basename of current pwd converted to lowercase
function docker_build_run() 
{
	docker_build
	echo
	docker_run $@
}

# usage: docker_build image_name
function docker_build_name() 
{
	sudo docker build -t $@ . 
}

function docker_ps() 
{
	sudo docker ps
}

function docker_kill() 
{
	sudo docker container kill "$@"
}

function docker_killall() 
{		 
	sudo docker container kill $(sudo docker ps -q)
}

function docker_stop() 
{
	sudo docker container stop "$@"
}

function docker_stop_all() 
{
	sudo docker container stop $(sudo docker ps -q)
}

function docker_clean() 
{
	sudo docker container rm $(sudo docker container ls -aq)
	sudo docker image prune
}

function docker_image_ls() 
{
	sudo docker images
}

function docker_image_rm() 
{
	sudo docker image rm "$@"
}

function docker_killall_cleanall() 
{
	sudo docker container stop $(sudo docker ps -q)
	sudo docker container rm $(sudo docker container ls -aq)
	sudo docker image rm $(sudo docker images -aq)
}
###################################################################


#################################################################
#mail
#################################################################
function op_echo_attach_files() 
{
	for var in "$@"
	do
		echo -n "-a $var "
	done
}

# Usage: 
# mail_files filename1 filename2 ...
function mail_files() 
{
	eval $(echo "echo \"\" | mailx -s \""$@"\" -r $MY_EMAIL $(op_echo_attach_files $@) $MY_EMAIL")
}
#################################################################


#################################################################
# files and folder stuff
#################################################################
# http://www.bigsoft.co.uk/blog/2,008/04/11/configuring-ls_colors
#di is regular directory, ow is a writeable for others
export LS_COLORS='*.csv=01;35:*.json=01;36:*.user=00;90:*.sln=00;90:*.vcxproj=00;90:*.filters=00;90:*.hint=00;90:*.lock=00;90:*.ppt=01:*.odt=01:no=00:fi=00:di=01;33:ow=01;33:ln=01;36:pi=40;33:so=01;35:bd=44;32;01:cd=44;33;01:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.tar=36:*.tgz=36:*.rpm=36:*.deb=36:*.arj=36:*.taz=36:*.lzh=36:*.zip=36:*.z=36:*.Z=36:*.gz=36:*.rar=36:*.JPG=01;35:*.jpg=01;35:*.ppm=01;35:*.pgm=01;35:*.png=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.tiff=01;35:*.tif=01;35:*.mp3=35:*.ogg=35:*.wav=35:*.au=35:*.mid=35:*.voc=35:*.mod=35:*.aiff=35:*.txt=01:*.html=01:*.htm=01:*.doc=01:*.ps=01:*.eps=01:*.pdf=01:*.lyx=01:*.py=91:*.c=91:*.cc=91:*.icc=91:*.cpp=91:*.cxx=91:*.hh=91:*.h=91:*.hpp=91:*.hxx=91:*.m=91:*.java=91:*.sh=32:*.csh=32:*.o=32:*.a=32:*.so=32:*.obj=32:*.class=32:*dockerfile=01;34:*Makefile=01;34:*README=01:*.md=01'
export LS_OPTIONS='--color=always -F -b -X'
alias ls='ls $LS_OPTIONS' 
alias l='ls  -lhSrXt'
alias LS='ls'
alias duls='du -h --max-depth=1'

#alias lsa='ls -lhaSrX'
#alias la='ls -lhaSrX'
#alias lh='ls --color=always -F -b -X | less -R'
#alias lsn='ls -lhSrXt \!* | cat -n'
#alias lsnmat='ls -lhSrXt *.mat | cat -n'
#alias lsnmatd='ls -lhSrXt \!*/*.mat | cat -n'
#alias ltex='ls  -lhSrXt *.tex'

# list only filenames and directory names in rows
function lslist() 
{
 ls | grep '.'
}

# list only filenames in rows
function lslistfiles() 
{
 find $@ -maxdepth 1 -type f -printf "%f\n"
}

# -H for filename
# -nr for line number
function gsenstive() 
{
 grep -nr -H --color=always $@
}

function g() 
{
 grep -nr -H -i --color=always $@
}

function gnoreg() 
{
 grep -nr -H -i --color=always -F -- $@
}

alias rmAll='rm -R * -f'

alias clean='rm -rf *~ .*~ #* *.o *.class *.dvi *.log *.aux java.log* matlab_crash*'

alias cleantex='rm -rf *~ *.o *.class *.dvi *.log *.aux java.log* matlab_crash* *.ps *.bbl *.blg *.aux *.brf *.dvi *.log *.bcf *.nav *.out *.snm *.toc *.vrb *.xml'

alias rm_zero_sized_files='find -size 0c -type f -exec rm -f {} \;'

# fixing the problem with less that runs on a shell that was run another shell. See here:
# https://www.unix.com/unix-for-dummies-questions-and-answers/114295-problems-using-less.html
function new_less() 
{
  if [[ $# -eq 2 && -f $2 ]]; then
    cat "$2" | $(which less) -R
    return
  fi
  if [[ $# -eq 1 ]]; then
    $(which less) -R
    return
  fi
  echo "${FUNCNAME[0]} works currently only with 0 arguments or 1 argument which is a file"
}

function cat_file_with_single_number_as_scientific()
{
    if [[ ($# -ne 1 && $# -ne 2) ]]; then
        echo "Illegal number of parameters" >&2
        echo "usage:" >&2
        echo "${FUNCNAME[0]} filename <number of digits after decimal point>" >&2
        return 2
    fi
    local private_digits_num=1
    if [[ ($# -eq 2) ]]; then
        local private_digits_num="$2"
    fi
    
    cat $1 | { read message; printf "%.${private_digits_num}e\n" "$message"; }
}

function chxsh() 
{
	chmod a+x *.sh
}

function convert_py_files_tabs_to_spaces() 
{
	find . -name '*.py' ! -type d -exec bash -c 'expand -t 4 "$0" > /tmp/e && mv /tmp/e "$0"' {} \;
}

function convert_file_to_ascii() 
{
		 iconv -f iso-8859-1 -t US-ASCII//TRANSLIT "$@" > "new_$@"
		 rm "$@" -f
		 mv "new_$@" "$@"
		 cat -n "$@" | perl -ne 'print if /[^[:ascii:]]/'
}

function find_lines_of_non_ascii() 
{
		 cat -n "$@" | perl -ne 'print if /[^[:ascii:]]/'
}

function find_lines_of_ascii() 
{
		 cat -n "$@" | perl -ne 'print if /[[:ascii:]]/'
}

# # add , to numbers >=1000
# function filethousands 
# {
# 		 cat $@ | op_thousands > $@.tmp
# 		 mv -f $@.tmp $@
# 		 grep [0-9] -nr -H -i --color=always $@ | grep --color=always ,
# }

# # used in filethousands
# function op_thousands 
# {
#     sed -re ' :restart ; s/([0-9])([0-9]{3})($|[^0-9])/\1,\2\3/ ; t restart '
# }
######################################################################


######################################################################
# media files
######################################################################

# cutvideo 00:01:00 00:02:00 in_file out_file
function cutvideo() 
{
  ffmpeg -ss "$1" -to "$2" -i "$3" -c copy "$4"
}
  
function reduce_mp4_quality_this_dir() 
{
  find ./ -type f -name "*.mp4" -exec /usr/bin/ffmpeg -i '{}' -c:v libx264 -preset slow -crf 40 -c:a copy '{}.small.mp4' \;
}

#function convert_ape_to_flac_this_dir() {
#		 find ./ -type f -name "*.ape"  -exec FILL_PATH/avconv -i '{}' '{}.flac' \;
#		 find ./ -type f -name "*.ape.flac" -exec rename 's/\.ape\.flac$/\.flac/' {} \;
#}

# function flacinthisdircuesplit()
# {
#   cp ~/utils/flaccuesplit ./
#   source flaccuesplit
#   rm flaccuesplit -f
# }

# function idtagalbumfix()
# {
#     # use this and then idtag to remove unwanted fields
# 	sudo mid3v2 --delete-frames=APIC *.mp3
# 	sudo mid3v2 --delete-frames=MCDI *.mp3
# 	sudo mid3v2 --delete-frames=TOAL *.mp3
# 	sudo mid3v2 --delete-frames=TRCK *.mp3
# 	sudo mid3v2 --delete-frames=TSOA *.mp3
# 	sudo mid3v2 --delete-frames=TPE2 *.mp3	
# }

# function idtag()
# {
#   # idtag -A "Sopranos" '*.mp3'
#   # idtag -p "1.jpg" '*.mp3'
#   sudo mid3v2 $@
# }
######################################################################

######################################################################
# pdf 
######################################################################
# Usage:
# pdfpages firstpage lastpage inputfile
# output: "inputfile_firstpage-lastpage.pdf"
function pdfpages()
{
    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
       -dFirstPage=${1} \
       -dLastPage=${2} \
       -sOutputFile=${3%.pdf}_p${1}-p${2}.pdf \
       ${3}
}

function pdfjoinallfilestoalldotpdf()
{
	pdfunite *.pdf all.pdf
}

function pdfmergea4() 
{
 convert -resize 1240x1750 -background black -compose Copy -gravity center -extent 1240x1750 -units PixelsPerInch -density 150 $@
}

function pdfwordcount() 
{
 pdftotext $@ - | tr -d '.' | wc -w
}

# creates unencrypted.pdf
function pdfunlock() 
{
 gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=unencrypted.pdf -c .setpdfwrite -f $@
}

function pdftoepspage() 
{
 pdftops -f $2 -l $2 -eps $1 $2.eps
}
######################################################################

######################################################################
# zip and friends
######################################################################
# unzip unrar ... for all formats and rm the zip/rar file
function u() 
{
 dtrx -r -n -q $@
 rm -f $@ 
}

# zip a directory to the same name
function zipr() 
{
 zip -r ${@%/}.zip ${@%/}/
}

function zipre() 
{
 zip -r -e $@.zip $@/
}

# compress, like zip
function tc() 
{
  tar -zcvf "$@"
}

# compress a folder a/b/c/ or c/ into ./c.tgz
function tcf()
{
  if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[0]} folder_name" >&2
    return 2
  fi
  tc ./$(basename $1).tgz "$1"
}

# uncompress, like unzip
function te()
{
  tar -zxvf "$@"
}
######################################################################


###################################################################
# helper functions
#
# Usage of 'func' that returns value:
#
# local var=$(func)
#
# Note: important not to have whitespace!
###################################################################
function basename_pwd()
{
    local ret=$(basename $(pwd))
    echo "$ret"
}

function basename_pwd_lower_case()
{
    local ret=$(basename_pwd)
	  local ret=${ret,,}
    echo "$ret"
}
###################################################################


######################################################################
# to sort
######################################################################
#TEMPERATURE=$(sensors | grep "Core 0" | cut -d + -f 2 | cut -d . -f1)
#
##if [ $TEMPERATURE -ge 30 ]; then
#echo "$TEMPERATURE" >> temps.txt
##fi# 

#alias code_see='a2ps -o tmp.ps --columns 1 --font-size=11 --line-numbers 1 \!*; gv tmp.ps &'

# uses .ispell_american
#alias spelltex	 'ispell -d american -t \!*'
#alias addBorder 'convert \!* -bordercolor black -border 1x1 \!*'

#alias ogg2mp3 'oggdec *.ogg; bladeenc -320 *.wav; rm *.wav -f; rm *.ogg -f'
#alias ogg2mp3 '~/utils/ogg2mp3'
#alias mq	'du -h>&! /tmp/duTmpFile; cat /tmp/duTmpFile | egrep "[0-9]M" | grep -v 'cannot' ; rm /tmp/duTmpFile -f'

# img2mov %08d.png -vcodec libx264 output.mov
# works nicely.  EXCEPT it doesn't work if the image dimensions aren't divisble by two.
#alias img2mov '/zain/projects/ffmpeg+x264/bin/ffmpeg -i \!*'

# wget -r -A png,pdf http://www.website-name.com
#alias gdbt='gdb --eval-command=run --eval-command=bt \!*'

# When starting a new project in VS: configure the compiler and linker to your g++ (e.g. the one above)
#function install_armadillo() {
#  sudo yum install cmake
#  sudo yum install openblas-devel
#  sudo yum install lapack-devel
#  sudo yum install arpack-devel
#  sudo yum install SuperLU-devel
#  ./configure
#  make
#  sudo make install
#}
######################################################################