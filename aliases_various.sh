function cd() {
  command cd "$@"
  code_here_if_git
  git_pull_if_git
  title_window_basename_pwd
}

function cda() {
  command cd "$@"
  code_add_here_if_git
  git_pull_if_git
  title_window_basename_pwd
}

function install_tools()
{
  uv tool install ruff@latest
  uv tool install ty@latest
  uv tool install ssort@latest
}

# calculator use [] instead of ()
function c() 
{ 
  local in="$(echo " $*" | sed -e 's/\[/(/g' -e 's/\]/)/g')";
  gawk -M -v PREC=201 -M 'BEGIN {printf("%.60g\n",'"${in-0}"')}' < /dev/null
  #calc "$@"
}

function cl()
{
  clear
}

function sa()
{
  source ~/.bashrc
}

function vscode_extension_list_create()
{
    code --list-extensions 2>&1 | tee .vscode/extensions_list.txt > /dev/null && echo "Created .vscode/extensions_list.txt with $(wc -l < .vscode/extensions_list.txt) extensions"
}

function vscode_extension_list_update()
{
    code --list-extensions | xargs -n 1 code --uninstall-extension
    cat .vscode/extensions_list.txt | xargs -n 1 code --install-extension
}

function code_here_if_git()
{
  if [ -d .git ]; then
    code -r .
  fi
}

function code_add_here_if_git()
{
  if [ -d .git ]; then
    code -a .
  fi
}

function fixshell()
{
  echo -ne "\\017" "$@"
}

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

function diskinfo()
{
  lsblk -o MODEL,SIZE,NAME -d "$@"
}

function nvidiagpuinfo()
{
  nvidia-smi -L "$@"
}

function _is_linux()
{
    [[ "$(uname -s)" == "Linux" ]]
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
  # No whitespace before\after =
  # MY_EMAIL='@'
	eval $(echo "echo \"\" | mailx -s \""$@"\" -r $MY_EMAIL $(op_echo_attach_files $@) $MY_EMAIL")
}
#################################################################


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

