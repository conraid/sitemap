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

VERSION=0.5.1

# Exit on error and undeclared variables
set -eu

# THE DEFAULT INITIALIZATIONS - OPTIONALS
DEFAULT_EXT="php,html"
DEFAULT_INDEX="index.php"
DEFAULT_PRIORITY="0.5"
DEFAULT_FREQ="weekly"
DEFAULT_IPV="-4"
DEFAULT_OUTPUT="sitemap.xml"

SORTFILE=$(mktemp) || { echo "Failed to create temp file"; exit 1; }

# Not Root. And not sudo please ;)
if [[ "$EUID" = 0 ]]; then
  err "This script should not be run as root" 1>&2
fi

# Show script description
function info() {
cat << EOF
  This script crawls a web site from a given starting local URL or
  remote URL and generates a Sitemap file in the format that is
  accepted by Google.
  It does not follow links to other web sites or parent directory.
  It also respects robots.txt file.
EOF
help
}

# Print error in STDERR
function err() {
  echo -e "\n  [$(date +'%Y-%m-%d %H:%M:%S %z')]:" "$@" "\n" >&2
  exit 1
}

# Show help usate
function  help() {
cat << EOF

Usage:
  $(basename "$0") [-r|--remote <url>] [-l|--locale <url>] [-p|--priority <number>] [-f|--frequency <string>] [-i|--index <string>] [-d|--docroot <path>] [-a|--accepted <ext>] [-o|--output-file] [-6] [-h|--help] [-v|--version]


Example:
  $(basename "$0") -l https://localhost/foobar/ -r https://example.com -d /home/html/foobar -p 0.8 -f daily

Options:
 -r|--remote <url>           Set the remote URL

 -l|--local <url>            Set the local URL (ex. http://localhost/foobar/ )
                             Not with filename (ex. http://localhost/foo/bar.php)

 -p|--priority <value>       Set the priority. Valid values range from 0.0 to 1.0.
                             Default is "0.5"

 -f|--frequency <value>      Set the frequency. Valid values are:
                             always, hourly, daily, weekly, monthly, yearly, never
                             Default is "weekly"

 -i|--index <filename>       Set the name of index file
                             The default filename is "index.php"

 -d|--docroot <path>         Set dhe "Doc Root"

 -a|--accepted <list>        Comma-separated list of accepted extensions.
                             Default is "php,html"

 -o|--output-file <filename> Set the name of the geneated sitemap file.
                             The default file name is sitemap.xml.

 -6                          Set the inet6-only to wget.
                             Connect only to IPv6 addresses.

 -v|--version                Print version

 -h|--help                   Print this help and exit

EOF
}

# Check priority parameter
function check_priority() {
  if echo "$1" | grep -q "^0.[1-9]$" || [ "$1" == '1.0' ] ; then
    PRIORITY_DEFAULT="$1"
  else
    err "Valid values for 'priority' range from 0.0 to 1.0."
  fi
}

# Check frequency parameter
function check_freq() {
  if [ "$1" == "always" ] || [ "$1" == "hourly" ]  || [ "$1" == "daily" ] || [ "$1" == "weekly" ] || [ "$1" == "monthly" ] || [ "$1" == "yearly" ] || [ "$1" == "never" ]; then
    FREQ_DEFAULT="$1"
  else
    err "Valid values for 'frequency' are always, hourly, daily, weekly, monthly, yearly or never."
  fi
}


# Make <url>
function makeurl() {

  PRIORITY="${PRIORITY_DEFAULT:-$DEFAULT_PRIORITY}"
  FREQ="${FREQ_DEFAULT:-$DEFAULT_FREQ}"

  if [ -n "${DOCROOT:-""}" ]; then
    FILE=$(echo "$1" | sed 's|/$||' | sed "s|${LOCALURL%/}|$DOCROOT|")

    if [ -d "$FILE" ]; then
      FILENAME="${INDEX_FILE:-$DEFAULT_INDEX}"
      FILE="${FILE}"/"$FILENAME"
    else
      FILENAME=$(basename "$FILE")
    fi

    if [ -f "$FILE" ]; then
      LASTMOD=$(date -r "$FILE" +%F)
    else
      # Show a error but not exit.
      echo -e "\n  [$(date +'%Y-%m-%d %H:%M:%S %z')]: FILE $FILE not exists. Check parameters"
    fi
  fi

  if [ -z "${LOCALURL:-""}" ] || [ -z "${REMOTEURL:-""}" ]; then
    REMOTEFILE="$1"
  else
    REMOTEFILE=${1/$URLSCAN/$REMOTEURL/}
  fi

  # This work for me.
  # Begin
  if [[ $1 = */ ]]; then
    PRIORITY="1"
    FREQ=daily
  elif [[ $1 = *legal* ]]; then
    PRIORITY="0.1"
    FREQ=monthly
  elif [[ $1 = *privacy* ]]; then
    PRIORITY="0.1"
    FREQ=monthly
  elif [[ $1 = *cookie* ]]; then
    PRIORITY="0.1"
    FREQ=monthly
  fi
  # End


  echo "Add $REMOTEFILE"
  {
    echo "<url>"
    echo "  <loc>$REMOTEFILE</loc>"
    [[ -z ${DOCROOT:-""} ]] || echo "  <lastmod>$LASTMOD</lastmod>"
    echo "  <changefreq>$FREQ</changefreq>"
    echo "  <priority>$PRIORITY</priority>"
    echo "</url>"
  } >> "$OUTPUT_FILE"
}

# Read parameters
while test $# -gt 0; do
  case "$1" in
    -r|--remote)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || REMOTEURL="${2%/}"
      shift
      ;;
    --remote=*)
      REMOTEURL="${1##--remote=}"
      ;;
    -r*)
      REMOTEURL="${1##-r}"
      ;;
    -l|--local)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || LOCALURL="$2"
      shift
      ;;
    --local=*)
      LOCALURL="${1##--locale=}"
      ;;
    -l*)
      LOCALURL="${1##-l}"
      ;;
    -p|--priority)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || check_priority "$2"
      shift
      ;;
    --priority=*)
      check_priority "${1##--priority=}"
      ;;
    -p*)
      check_priority "${1##-p}"
      ;;
    -f|--frequency)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || check_freq "$2"
      shift
      ;;
    --frequency=*)
      check_freq "${1##--frequency=}"
      ;;
    -f*)
      check_freq "${1##-f}"
      ;;
    -i|--index)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || INDEX_FILE="$2"
      shift
      ;;
    --index=*)
      INDEX_FILE="${1##--index=}"
      ;;
    -i*)
      INDEX_FILE="${1#-i}"
      ;;

    -o|--output-file)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || OUTPUT_FILE="$2"
      shift
      ;;
    --output-file=*)
      OUTPUT_FILE="${1##--output=}"
      ;;
    -o*)
      OUTPUT_FILE="${1#-o}"
      ;;
    -d|--docroot)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || DOCROOT="$2"
      shift
      ;;
    --docroot=*)
      DOCROOT="${1##--docroot=}"
      ;;
    -d*)
      DOCROOT="${1##-d}"
      ;;
    -a|--accepted)
      test $# -lt 2 && err "Missing value for the optional argument '$1'." || ACCEPTED_EXT="$2"
      ACCEPTED_EXT="$2"
      shift
      ;;
    --accepted=*)
      ACCEPTED_EXT="${1##--accepted=}"
      ;;
    -a*)
      ACCEPTED_EXT="${1##-a}"
      ;;
    -6)
      IPV="-6"
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -h*)
      help
      exit 0
      ;;
    -v|--version)
      echo Version: "$VERSION"
      exit 0
      ;;
    -v*)
      echo Version: "$VERSION"
      exit 0
      ;;
    *)
      err "FATAL ERROR: Got an unexpected argument '$1'"
      ;;
  esac
  shift
done

# Check if at least one of A and B is present.
# If so, set the URLSCAN variable based on the parameters passed.
if [ -z "${LOCALURL:-""}" ] && [ -z "${REMOTEURL:-""}" ]; then
  err "$(basename "$0") requires -r or -l."
elif [ -z "${LOCALURL:-""}" ]; then
  URLSCAN="$REMOTEURL"
elif [ "${LOCALURL: -1}" != "/" ] ; then
  URLSCAN="${LOCALURL}/"
else
  URLSCAN="${LOCALURL}"
fi

# Check accepted extensions
if [[ -z ${ACCEPTED_EXT:-""} ]]; then
  ACCEPTED_EXT="${ACCEPTED_EXT:-$DEFAULT_EXT}"
elif [ "${ACCEPTED_EXT: -1}" == "," ] ; then
  ACCEPTED_EXT="${ACCEPTED_EXT::-1}"
else
  ACCEPTED_EXT="${ACCEPTED_EXT//[[:space:]]/}"
fi

# Set default value of the variables
OUTPUT_FILE="${OUTPUT_FILE:-$DEFAULT_OUTPUT}"

# Crawler
echo "Scan: $URLSCAN"

wget --spider -r -nd -l inf --no-verbose --no-check-certificate -np -A "$ACCEPTED_EXT" "${IPV:-"$DEFAULT_IPV"}" "${URLSCAN}" 2>&1 \
| grep -i URL | awk -F 'URL:' '{print $2}' | cut -d" " -f1 | sort -u > "$SORTFILE"

if ! [ -s "$SORTFILE" ]; then
  err "Error in wget. Check parameters, network, web server or other."
fi

# Create XML file
cat << EOF > "$OUTPUT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xsi:schemaLocation="
            http://www.sitemaps.org/schemas/sitemap/0.9
            http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
EOF

# Modify ACCEPTED_EXT for case statement
ACC_EXT="*/"
for i in $(echo "$ACCEPTED_EXT" | tr , " "); do
  ACC_EXT="$ACC_EXT |*.$i"
done

# Read SORTFILE and call makeurl
while read -r FILELIST; do
  eval "case \"$FILELIST\" in
          robots.txt )
            ;;
          $ACC_EXT)
            makeurl \"$FILELIST\"
            ;;
          *)
            ;;
        esac"
done < "$SORTFILE"

# Close xml file
echo "</urlset>" >> "$OUTPUT_FILE"

# Compress output file (default sitemap.xml)
gzip -9 -f "$OUTPUT_FILE" -c > "${OUTPUT_FILE}".gz || { err "Failed to zipper sitemap"; }

# Delete temporary files
rm "$SORTFILE" || { err "Failed to remove temporary files"; }
