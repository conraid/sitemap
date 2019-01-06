#!/bin/bash
#
# Copyright 2019 Corrado Franco (http://conraid.net)
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version, with the following exception:
# the text of the GPL license may be omitted.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of
# merchantability or fitness for a particular purpose. Compiling,
# interpreting, executing or merely reading the text of the program
# may result in lapses of consciousness and/or very being, up to and
# including the end of all existence and the Universe as we know it.
# See the GNU General Public License for more details.
#
# You may have received a copy of the GNU General Public License along
# with this program (most likely, a file named COPYING).  If not, see
# <http://www.gnu.org/licenses/>.

# Thanks to barkeep for idea
# http://www.lostsaloon.com/technology/how-to-create-an-xml-sitemap-using-wget-and-shell-script/

# N.B.
# THIS IS ONLY A TESTING SCRIPT to generate sitemap in my situation.
#
# If you need a generic and/or better sitemap generator try one of this
# https://code.google.com/archive/p/sitemap-generators/wikis/SitemapGenerators.wiki

# Version 0.1

# Exit on error and undeclared variables
set -eu

# Set default parameters
DEFAULT_EXT="php,html"
DEFAULT_INDEX="index.php"
DEFAULT_PRIORITY="0.5"
DEFAULT_FREQ="weekly"

LISTFILE=$(mktemp) || { echo "Failed to create temp file"; exit 1; }
SORTFILE=$(mktemp) || { echo "Failed to create temp file"; exit 1; }

# Not Root. And not sudo please ;)
if [[ $EUID = 0 ]]; then
  echo "This script should not be run as root" 1>&2
  exit 1
fi

function info() {
# Show script description
cat << EOF
  This script crawls a web site from a given starting local URL or
  remote URL and generates a Sitemap file in the format that is 
  accepted by Google.
  It does not follow links to other web sites or parent directory.
  It also respects robots.txt file.
EOF
help
}

function  help() {
# Show help usate
cat << EOF

  Usage:
  $(basename $0) [OPTIONS]
  
  Example:
  $(basename $0) -l https://localhost/foobar/ -r https://example.com -d /home/html/foobar -p 0.8 -f daily 

  Options:
    -r <url>    : Remote domain
        
    -l <url>    : Local domain (ex. http://localhost/foobar/
		  Not with filename (ex. http://localhost/foo/bar.php)

    -p <number> : Priority. Valid values range from 0.0 to 1.0.
		  Default is "0.5"

    -f <string> : Frequency. Valid values are:
                  always, hourly, daily, weekly, monthly, yearly, never
                  Default is "weekly"

    -i <string> : Name of index file
		  Default is "index.php"
		  
    -d <path>   : Doc Root
		  
    -a <ext>	: Comma-separated list of accepted extensions.
		  Default is "php,html"
    
    -h          : Print this help and exit

EOF
}

# Command line parameter processing:
while getopts ":l:r:d:p:f:i:a:e:h" Option
do
  case $Option in
    h )
        info
        exit 0
        ;;
    r )
        REMOTEURL="${OPTARG%/}"
        ;;
    l )
        LOCALURL="${OPTARG}"
        ;;
    d )
	DOCROOT="${OPTARG}"
	;;
    p )
	PRIORITY_DEFAULT="${OPTARG}"
	;;
    f )
	FREQ_DEFAULT="${OPTARG}"
	;;
    a)  
	ACCEPTED_EXT="${OPTARG}"
	;;
    \?)
	echo ""
        echo "  Invalid option: -$OPTARG"
        help
        exit 1
        ;;
     :)
	echo ""
        echo "  Option -$OPTARG requires an argument."
        help
        exit 1
        ;;
  esac
done
# End of option parsing.
shift $(($OPTIND - 1))

# Check accepted extensions
if [[ -z ${ACCEPTED_EXT:-""} ]]; then
  ACCEPTED_EXT=${ACCEPTED_EXT:-$DEFAULT_EXT}
elif [ "${ACCEPTED_EXT: -1}" == "," ] ; then
  ACCEPTED_EXT="${ACCEPTED_EXT::-1}"
else
  ACCEPTED_EXT="${ACCEPTED_EXT//[[:space:]]/}"
fi

# Check if at least one of A and B is present.
# If so, set the URLSCAN variable based on the parameters passed.
if [ -z ${LOCALURL:-""} ] && [ -z ${REMOTEURL:-""} ]; then
  echo ""
  echo " $(basename $0) requires -r or -l."
  help
  exit 1
elif [ -z ${LOCALURL:-""} ]; then
  URLSCAN=$REMOTEURL
elif [ "${LOCALURL: -1}" != "/" ] ; then
  URLSCAN="${LOCALURL}/"
else
  URLSCAN="${LOCALURL}"
fi

# Set default value of the variables
indexfile=${INDEX_FILE:-$DEFAULT_INDEX}  

# Make <url> 
function makeurl() {

  priority=${PRIORITY_DEFAULT:-$DEFAULT_PRIORITY}
  freq=${FREQ_DEFAULT:-$DEFAULT_FREQ}

  if ! [ -z ${DOCROOT:-""} ]; then
    FILE=$(echo $1 | sed 's|/$||' | sed "s|${LOCALURL%/}|$DOCROOT|")
    FILENAME=$(basename $FILE)

    if [ -d $FILE ]; then
      FILENAME=$indexfile
      FILE=${FILE}/$FILENAME
    fi
    if [ -f $FILE ]; then
    lastmod=$(date -r $FILE +%F)
    else 
	echo "FILE $FILE not exists"
	exit
    fi
  fi

  if [ -z ${LOCALURL:-""} ] || [ -z ${REMOTEURL:-""} ]; then
    remotefile=$1
  else
    remotefile=${1/$URLSCAN/$REMOTEURL/}
  fi

  # This work for me.
  # Begin
  if [[ $1 = */ ]]; then
    priority="1"
    freq=daily
  elif [[ $1 = *legal* ]]; then
    priority="0.1"
    freq=monthly
  elif [[ $1 = *privacy* ]]; then
    priority="0.1"
    freq=monthly
  elif [[ $1 = *cookie* ]]; then
    priority="0.1"
    freq=monthly
  fi
  # End

  echo "Add $remotefile"
  echo "<url>" >> sitemap.xml
  echo "  <loc>$remotefile</loc>" >> sitemap.xml
  [[ -z ${DOCROOT:-""} ]] || echo "  <lastmod>$lastmod</lastmod>" >> sitemap.xml
  echo "  <changefreq>$freq</changefreq>" >> sitemap.xml
  echo "  <priority>$priority</priority>" >> sitemap.xml
  echo "</url>" >> sitemap.xml
}

# Crawler
echo "Scan $URLSCAN"
wget --spider -r -nd -l inf --no-verbose --no-check-certificate --output-file=$LISTFILE -np -A $ACCEPTED_EXT $URLSCAN
grep -i URL $LISTFILE | awk -F 'URL:' '{print $2}' | cut -d" " -f1 | sort -u > $SORTFILE

# Create XML file
cat << EOF > sitemap.xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xsi:schemaLocation="
            http://www.sitemaps.org/schemas/sitemap/0.9
            http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
EOF

# Modify XZZ for case statement
ACC_EXT="*/"

for i in $(echo $ACCEPTED_EXT | tr , " "); do
  ACC_EXT="$ACC_EXT |*.$i"
done

# Read SORTFILE and call makeurl
while read filelist; do
  eval "case \"$filelist\" in
    robots.txt )
	;;
    $ACC_EXT)
	makeurl \"$filelist\"
	;;
    *)
	;;
  esac"
done < $SORTFILE

# Close xml file
echo "</urlset>" >> sitemap.xml

# Compress sitemap.xml
gzip -9 -f sitemap.xml -c > sitemap.xml.gz || { echo "Failed to zipper sitemap"; exit 1; }

# Delete temporary files
rm $LISTFILE $SORTFILE || { echo "Failed to remove temporary files"; exit 1; }
