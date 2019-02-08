# Sitemap-generator.sh

Sitemap xml generator in posix shell.

## Description

This script crawls a web site from a given starting local URL and generates a Sitemap file in the format that is accepted by Google.
It does not follow links to other web sites or parent directory.

## Usage

  Usage:

     $ sitemap-generator.sh [-r|--remote <url>] [-l|--locale <url>] [-p|--priority <number>] [-f|--frequency <string>] [-i|--index <string>] [-d|--docroot <path>] [-A|--accept <list>] [-R|-reject <list>] [-o|--output-file] [-6] [-h|--help] [-v|--version] [-vv|--verbose|--debug]

  Example:

     $ sitemap-generator.sh -l https://localhost/foobar/ -r https://example.com -d /home/html/foobar -p 0.8 -f daily

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

    -vv|--verbose               Print details when crawling with wget.

    --debug                     Set bash to debug mode (-x)

    -v|--version                Print version.

    -h|--help                   Print this help and exit.


## Installation

Simple copy file in $PATH and

    $ chmod +x sitemap.sh

## Requirement

This script requires this command: wget, sed, awk, grep, cut and sort.
Optional: tee (for verbose mode), id or whoami (for root user check).

## Warnings

**THIS IS ONLY A TESTING SCRIPT** to generate sitemap in my situation.

It was written quickly, so it has errors and *ugliness* of course.

It is here because I need a public place to keep it, but if you need a sitemap generator try one of this:
https://code.google.com/archive/p/sitemap-generators/wikis/SitemapGenerators.wiki

## Note

If you have advice and suggestions to give, you are welcome.

I'm sorry for my bad english
