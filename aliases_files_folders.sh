# http://www.bigsoft.co.uk/blog/2,008/04/11/configuring-ls_colors
#di is regular directory, ow is a writeable for others
export LS_COLORS='*.csv=01;35:*.json=01;36:*.user=00;90:*.sln=00;90:*.vcxproj=00;90:*.filters=00;90:*.hint=00;90:*.lock=00;90:*.ppt=01:*.odt=01:no=00:fi=00:di=01;33:ow=01;33:ln=01;36:pi=40;33:so=01;35:bd=44;32;01:cd=44;33;01:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.tar=36:*.tgz=36:*.rpm=36:*.deb=36:*.arj=36:*.taz=36:*.lzh=36:*.zip=36:*.z=36:*.Z=36:*.gz=36:*.rar=36:*.JPG=01;35:*.jpg=01;35:*.ppm=01;35:*.pgm=01;35:*.png=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.tiff=01;35:*.tif=01;35:*.mp3=35:*.ogg=35:*.wav=35:*.au=35:*.mid=35:*.voc=35:*.mod=35:*.aiff=35:*.txt=01:*.html=01:*.htm=01:*.doc=01:*.ps=01:*.eps=01:*.pdf=01:*.lyx=01:*.py=91:*.c=91:*.cc=91:*.icc=91:*.cpp=91:*.cxx=91:*.hh=91:*.h=91:*.hpp=91:*.hxx=91:*.m=91:*.java=91:*.sh=32:*.csh=32:*.o=32:*.a=32:*.so=32:*.obj=32:*.class=32:*dockerfile=01;34:*Makefile=01;34:*README=01:*.md=01'
export LS_OPTIONS='--color=always -F -b -X'
function ls()
{
  command ls $LS_OPTIONS "$@"
}

function l()
{
  ls -lhSrXt "$@"
}

function LS()
{
  ls "$@"
}

function duls()
{
  du -h --max-depth=1 "$@"
}

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

function rmAll()
{
  rm -R * -f "$@"
}

function clean()
{
  rm -rf *~ .*~  *.o *.class *.dvi *.log *.aux java.log* matlab_crash*
}

function cleantex()
{
  rm -rf *~ *.o *.class *.dvi *.log *.aux java.log* matlab_crash* *.ps *.bbl *.blg *.aux *.brf *.dvi *.log *.bcf *.nav *.out *.snm *.toc *.vrb *.xml
}

function rm_zero_sized_files()
{
  find -size 0c -type f -exec rm -f {} \;
}

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
    _require_nargs "$#" "filename <number of digits after decimal point>" 1 2 || return
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
# locate SumatraPDF and open the given PDF (no file locking).
pdf_view() 
{
    local pdf_file="$1"

    # If SumatraPDF is on PATH, just use it.
    if command -v SumatraPDF >/dev/null 2>&1; then
        SumatraPDF -reuse-instance "$pdf_file" &
        return 0
    fi

    local candidates=(
        "$LOCALAPPDATA/SumatraPDF/SumatraPDF.exe"
        "/c/Program Files/SumatraPDF/SumatraPDF.exe"
        "/c/Program Files (x86)/SumatraPDF/SumatraPDF.exe"
        "$LOCALAPPDATA/Microsoft/WinGet/Links/SumatraPDF.exe"
    )

    local exe
    for exe in "${candidates[@]}"; do
        if [[ -x "$exe" ]]; then
            "$exe" -reuse-instance "$pdf_file" &
            return 0
        fi
    done

    echo "WARNING: SumatraPDF not found; falling back to the default PDF handler." >&2
    if command -v start >/dev/null 2>&1; then
        start "" "$pdf_file"
    else
        cmd.exe /c start "" "$pdf_file"
    fi
}

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
  _require_nargs "$#" "folder_name" 1 || return
  tc ./$(basename $1).tgz "$1"
}

# uncompress, like unzip
function te()
{
  tar -zxvf "$@"
}
######################################################################
