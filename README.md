# Sitemap.sh

Sitemap xml generator

## Description 

This script crawls a web site from a given starting local URL and generates a Sitemap file in the format that is accepted by Google.
It does not follow links to other web sites or parent directory. 

## Usage

  Usage:
  
     $ sitemap.sh -l <url> [-r <url>]"

  Example:
  
     $ sitemap.sh -l https://localhost/foobar/ -r https://example.com -d /home/html/foobar -p 0.8 -f daily 

  Options:
  
    -l <url>    : Local domain (ex. http://localhost/foobar/
                  Not with filename (ex. http://localhost/foo/bar.php)

    -r <url>    : Remote domain

    -d <path>   : Doc Root

    -p <number> : Priority. Valid values range from 0.0 to 1.0.
                  Default is 0.5

    -f <string> : Frequency. Valid values are:
                  always, hourly, daily, weekly, monthly, yearly, never
                  Default is weekly

    -i <string> : Name of index file
                  Default is index.php
    
    -h          : Print this help and exit

## Installation

Simple copy file in $PATH and

    $ chmod +x sitemap.sh
    
## Warnings    
   
**THIS IS ONLY A TESTING SCRIPT** to generate sitemap in my situation.

It was written quickly, so it has errors and *ugliness* of course.

It is here because I need a public place to keep it, but if you need a sitemap generator try one of this:
https://code.google.com/archive/p/sitemap-generators/wikis/SitemapGenerators.wiki

## Note

If you have advice and suggestions to give, you are welcome.

I'm sorry for my bad english
