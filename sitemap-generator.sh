#!/bin/sh
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

# Exit on error and undeclared variables
set -eu

### VARIABLES ###

# Set script version
VERSION=1.3

# THE DEFAULT INITIALIZATIONS - OPTIONALS
DEFAULT_INDEX="index.php"
DEFAULT_PRIORITY="0.5"
DEFAULT_FREQ="weekly"
DEFAULT_OUTPUT="sitemap.xml"

# Set the bin utility program
MKTEMP="/usr/bin/mktemp" # Path of mktemp, or another temporary file creator (ex. tempfile).

# Set the default wget options
WGET_OPTIONS="--spider -r -nd -l inf --no-verbose --no-check-certificate -np"

# Color variables
RED_BEGIN="\\033[1;31m"
RED_END="\\033[0;39m"
GREEN_BEGIN="\\033[1;32m"
GREEN_END="\\033[0;39m"

### FUNCTIONS ###

# Print error in STDERR
err() {
  printf "\n [$(date +'%Y-%m-%d %H:%M:%S %z')]: %b %s %b \n\n" "$RED_BEGIN" "$*" "$RED_END" >&2
  exit 1
}

# Check root user
check_root() {
if [ -x "$(command -v id)" ]; then
  if test "$(id -u)" = "0"; then
    err "This script should not be run as root"
  fi
elif [ -x "$(command -v whoami)" ]; then
  if test "$(whoami)" = "whoami"; then
    err "This script should not be run as root"
  fi
else
  echo "Unable to determine if the script is run with the root user, consider whether to continue or not."
  sleep 10
fi
}

# Show script description
info() {
cat << EOF
  This script crawls a web site from a given starting local URL or
  remote URL and generates a Sitemap file in the format that is
  accepted by Google.
  It does not follow links to other web sites or parent directory.
  It also respects robots.txt file.
EOF
help
}

check_program() {
  if ! [ -x "$(command -v "$1")" ]; then
      err "'$(basename "$1")' it's not present in path"
  fi
}

# Show help usate
 help() {
cat << EOF

Usage:
  $(basename "$0") [-r|--remote <url>] [-l|--locale <url>] [-p|--priority <number>] [-f|--frequency <string>] [-i|--index <string>] [-d|--docroot <path>] [-A|--accept <list>] [-R|-reject <list>] [-o|--output-file] [-6] [-ssl|--check-ssl] [-h|--help] [-V|--version] [-vv|--verbose] [--debug]


Example:
  $(basename "$0") -l https://localhost/foobar/ -r https://example.com -d /home/html/foobar -p 0.8 -f daily

Options:
 -r|--remote <url>           Set the remote URL.

 -l|--local <url>            Set the local URL (ex. http://localhost/foobar/ )
                             Not with filename (ex. http://localhost/foo/bar.php)

 -p|--priority <value>       Set the priority. Valid values range from 0.0 to 1.0.
                             Default is "0.5".

 -f|--frequency <value>      Set the frequency. Valid values are:
                             always, hourly, daily, weekly, monthly, yearly, never
                             Default is "weekly".

 -i|--index <filename>       Set the name of index file.
                             The default filename is "index.php".

 -d|--docroot <path>         Set dhe "Doc Root".

 -A|--accept <list>          Comma-separated list of accepted extensions.
                             Default is all.

 -R|--reject <list>          Comma-separated list of rejected extensions.
                             Default is nothing.

 -o|--output-file <filename> Set the name of the geneated sitemap file.
                             The default file name is sitemap.xml.

 -6                          Set the inet6-only to wget.
                             Connect only to IPv6 addresses.

 -ssl|--check-ssl            Check if there are duplicate URLs with http and https.
                             Useful when there is a redirect "http to https" in .htaccess for example.

 -vv|--verbose               Print details when crawling with wget.

 --debug                     Set bash to debug mode (-x)

 -v|--version                Print version.

 -h|--help                   Print this help and exit.

EOF
}

# Check priority parameter
check_priority() {
  if echo "$1" | grep -q "^0.[1-9]$" || [ "$1" = '1.0' ] ; then
    PRIORITY_DEFAULT="$1"
  else
    err "Valid values for 'priority' range from 0.0 to 1.0."
  fi
}

# Check frequency parameter
check_freq() {
  if [ "$1" = "always" ] || [ "$1" = "hourly" ]  || [ "$1" = "daily" ] || [ "$1" = "weekly" ] || [ "$1" = "monthly" ] || [ "$1" = "yearly" ] || [ "$1" = "never" ]; then
    FREQ_DEFAULT="$1"
  else
    err "Valid values for 'frequency' are always, hourly, daily, weekly, monthly, yearly or never."
  fi
}


# Make <url>
makeurl() {

  # Remove protocol is present check_ssl option.
  if [ "${CHECK_SSL:-""}" = '1' ]; then
    URL=$(echo "$1" | sed 's|.*://||')
  else
    URL="$1"
  fi

  # Check if $URL it's present in sitemap xml file.
  if ! grep -Fq "$URL</loc>" "$OUTPUT_FILE"; then

    PRIORITY="${PRIORITY_DEFAULT:-$DEFAULT_PRIORITY}"
    FREQ="${FREQ_DEFAULT:-$DEFAULT_FREQ}"

    if [ -n "${DOCROOT:-""}" ]; then
      if [ "$(echo "$DOCROOT" | awk '{print substr($0,length,1)}')" != "/" ] ; then
	      DOCROOT="${DOCROOT}/"
      fi
      FILE=$(echo "$1" | sed "s|${LOCALURL}|$DOCROOT|")

      if [ -d "$FILE" ]; then
	      FILE="${FILE}"/"${INDEX_FILE:-$DEFAULT_INDEX}"
      fi

      if [ -f "$FILE" ]; then
	      LASTMOD=$(date -r "$FILE" +%F)
      else
	      # Show a error but not exit.
	      LASTMOD=""
	      printf "\n %b FILE %s not exists %b Check parameters. \n\n" "$RED_BEGIN" "$FILE" "$RED_END"
      fi
    fi

    if [ -z "${LOCALURL:-""}" ] || [ -z "${REMOTEURL:-""}" ]; then
      REMOTEFILE="$1"
    else
      REMOTEFILE=$(echo "$1" | sed "s|$URLSCAN|$REMOTEURL/|")
    fi

    # This works for me.
    # If you don't need this feature and you want to leave only the default values, comment this part.
    # Begin
    case "$1" in
      */ )
	      PRIORITY="1"
	      FREQ=daily
	      ;;
      *legal*|*privacy*|*cookie* )
	      PRIORITY="0.2"
	      FREQ=monthly
	      ;;
    esac
    # End


    printf "\n %b Add %s %b \n\n" "$GREEN_BEGIN" "$REMOTEFILE" "$GREEN_END"
    {
      echo "<url>"
      echo "  <loc>$REMOTEFILE</loc>"
      if [ "${LASTMOD:-""}" ]; then echo "  <lastmod>$LASTMOD</lastmod>"; fi
      echo "  <changefreq>$FREQ</changefreq>"
      echo "  <priority>$PRIORITY</priority>"
      echo "</url>"
    } >> "$OUTPUT_FILE"

  fi
}

### MAIN PROGRAM ###

# Not Root. And not sudo please ;)
check_root

# Check id exists utility programs
check_program sed
check_program awk
check_program wget
check_program grep
check_program cut
check_program sort
check_program $MKTEMP

# Read parameters
while test $# -gt 0; do
  case "$1" in
    -r|--remote)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      REMOTEURL="${2%/}"
      shift
      ;;
    --remote=*)
      REMOTEURL="${1##--remote=}"
      ;;
    -r*)
      REMOTEURL="${1##-r}"
      ;;
    -l|--local)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      LOCALURL="$2"
      shift
      ;;
    --local=*)
      LOCALURL="${1##--local=}"
      ;;
    -l*)
      LOCALURL="${1##-l}"
      ;;
    -p|--priority)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      check_priority "$2"
      shift
      ;;
    --priority=*)
      check_priority "${1##--priority=}"
      ;;
    -p*)
      check_priority "${1##-p}"
      ;;
    -f|--frequency)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      check_freq "$2"
      shift
      ;;
    --frequency=*)
      check_freq "${1##--frequency=}"
      ;;
    -f*)
      check_freq "${1##-f}"
      ;;
    -i|--index)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      INDEX_FILE="$2"
      shift
      ;;
    --index=*)
      INDEX_FILE="${1##--index=}"
      ;;
    -i*)
      INDEX_FILE="${1#-i}"
      ;;
    -o|--output-file)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      OUTPUT_FILE="$2"
      shift
      ;;
    --output-file=*)
      OUTPUT_FILE="${1##--output=}"
      ;;
    -o*)
      OUTPUT_FILE="${1#-o}"
      ;;
    -d|--docroot)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      DOCROOT="$2"
      shift
      ;;
    --docroot=*)
      DOCROOT="${1##--docroot=}"
      ;;
    -d*)
      DOCROOT="${1##-d}"
      ;;
    -A|--accept)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      ACCEPT_EXT="$2"
      shift
      ;;
    --accept=*)
      ACCEPT_EXT="${1##--accept=}"
      ;;
    -A*)
      ACCEPT_EXT="${1##-a}"
      ;;
    -R|--reject)
      test $# -lt 2 && err "Missing value for the optional argument '$1'."
      REJECT_EXT="$2"
      shift
      ;;
    --reject=*)
      REJECT_EXT="${1##--reject=}"
      ;;
    -R*)
      REJECT_EXT="${1##-e}"
      ;;
    -6)
      WGET_OPTIONS="$WGET_OPTIONS -6"
      ;;
    -ssl|--check-ssl)
      CHECK_SSL=1
      ;;
    -h|--help)
      help
      exit 0
      ;;
    -h*)
      help
      exit 0
      ;;
    -V|--version)
      echo Version: "$VERSION"
      exit 0
      ;;
    -vv|--verbose)
      VERBOSE=1
      ;;
    --debug)
      set -x
      DEBUG=1
      ;;
    *)
      err "FATAL ERROR: Got an unexpected argument '$1'. Use -h for help."
      ;;
  esac
  shift
done

# Check if at least one of A and B is present.
# If so, set the URLSCAN variable based on the parameters passed.
if [ -z "${LOCALURL:-""}" ] && [ -z "${REMOTEURL:-""}" ]; then
  err "$(basename "$0") requires -r or -l. Use -h for help"
elif [ -z "${LOCALURL:-""}" ]; then
  URLSCAN="$REMOTEURL"
elif [ "$(echo "$LOCALURL" | awk '{print substr($0,length,1)}')" != "/" ] ; then
  LOCALURL="${LOCALURL}/"
  URLSCAN="${LOCALURL}"
else
  URLSCAN="${LOCALURL}"
fi

# Check accepted extensions
if [ -n "${ACCEPT_EXT:-""}" ]; then
  if [ "$(echo "$ACCEPT_EXT" | awk '{print substr($0,length,1)}')" = "," ] ; then
    WGET_OPTIONS="$WGET_OPTIONS -A $(echo "$ACCEPT_EXT" | sed 's/,$//')"
  else
    WGET_OPTIONS="$WGET_OPTIONS -A $(echo "$ACCEPT_EXT" | tr -d " ")"
  fi
fi


# Check rejected extensions
if [ -n "${REJECT_EXT:-""}" ]; then
  if [ "$(echo "$REJECT_EXT" | awk '{print substr($0,length,1)}')" = "," ] ; then
    WGET_OPTIONS="$WGET_OPTIONS -R $(echo "$REJECT_EXT" | sed 's/,$//')"
  else
    WGET_OPTIONS="$WGET_OPTIONS -R $(echo "$REJECT_EXT" | tr -d " ")"
  fi
fi

# Set files
OUTPUT_FILE="${OUTPUT_FILE:-$DEFAULT_OUTPUT}"
LISTFILE=$($MKTEMP --suffix=-list) || { err "Failed to create LIST temp file. $MKTEMP exists and/or /tmp is writable?"; }
SORTFILE=$($MKTEMP --suffix=-sort) || { err "Failed to create SORT temp file. $MKTEMP exists and/or /tmp is writable?"; }

# Crawler
printf "\n Scan: %b %s %b \n\n" "$GREEN_BEGIN" "$URLSCAN" "$GREEN_END"

if [ ${VERBOSE:-""} = '1' ]; then
  if ! [ -x "$(command -v tee)" ]; then
    err "Verbose mode is possible only with command 'tee' in path"
  fi
  # shellcheck disable=SC2086
  wget $WGET_OPTIONS "$URLSCAN" 2>&1 | tee "$LISTFILE"
else
  # shellcheck disable=SC2086
  wget $WGET_OPTIONS "$URLSCAN" -o "$LISTFILE" || true
fi

# Check if wget creates listfile
if ! [ -s "$LISTFILE" ]; then
  err "Error in wget. Check parameters, network, web server or other."
fi

# Select only URL line
grep -i URL "$LISTFILE" | sed 's/URL: /URL:/' | awk -F 'URL:' '{print $2}' | cut -d" " -f1 | sed '/^$/d' | sort -u > "$SORTFILE"

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

# Read SORTFILE and call makeurl
while read -r FILELIST; do
  case "$FILELIST" in
    *robots*|*\.txt )
      ;;
    *privacy*|*cookie*)
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *\.jpg|*\.gif|*\.jpeg|*\.ico|*\.png|*\.svg|*\.webp )
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *\.jpg\?*|*\.gif\?*|*\.jpeg\?*|*\.ico\?*|*\.png\?*|*\.svg\?*|*\.webp\?* )
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *\.eot|*\.ttf|*\.woff|*\.woff2|*\.otf )
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *\.eot\?*|*\.ttf\?*|*\.woff\?*|*\.woff2\?*|*\.otf\?* )
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *\.js|*\.css)
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *\.js\?*|*\.css\?*)
      #makeurl "$FILELIST" # This works for me, if you need to insert this type of file too, uncomment the line.
      ;;
    *)
      makeurl "$FILELIST"
      ;;
  esac
done < "$SORTFILE"



# Close xml file
echo "</urlset>" >> "$OUTPUT_FILE"

# Compress output file (default sitemap.xml)
gzip -9 -f "$OUTPUT_FILE" -c > "${OUTPUT_FILE}".gz || { err "Failed to zipper sitemap"; }

# Delete temporary files
if [ -z ${DEBUG:-""} ]; then
  rm "$SORTFILE" "$LISTFILE" || { err "Failed to remove temporary files"; }
fi
