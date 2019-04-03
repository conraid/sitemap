= Changelog

== 1.2 ==

- Added fonts to exclusion list
- Added privacy and cookie page to exclusion list

== 1.1 ==

- Added check of duplicate entries. Although in theory it was already present thanks to the "sort -u" command.
- Added check-ssl option to consider duplicate files with the same filename but http or https protocol.

== 1.0 ==

- Ported to posix shells.
  Checked with shellcheck and tested with bash, zsh, csh, ksh, tcsh, dash.
- Added variable for mktemp (you can choose to use tempfile for example).

== 0.6 ==

- Added verbose ouput option
- Added rejected extensions option
- Added debug option

== 0.5.1 ==

- Fixed error in xml tag introduced in the previous version. I'm sorry.

== 0.5 ==

- Set ipv4 as default.
  Then removed the relative option and left only the one for ipv6.
- Added sitemap filename option
- Some cosmetic changes

== 0.4 ==

- Changed name in sitemap-generator
- Added ipv4 and ipv6 parameter
- Combined wget and output parsing, because in some circumstances wget exit without giving error
- Added check for wget and parsing ouput

== 0.3 ==

- Removed getops to also use long options
- Added check frequency parameter
- Added check priority parameter
- Added version parameter
- Fixed double quote to prevent globbing and word splitting in according with shellcheck

== 0.2 ==

- Added -r to read in according with shellcheck.
- Removed -e from getops.
  IT needed for the "rejected" in wget, but then I decided not to use it
- Readded -i parameters in case statement.
  I had temporarily removed in development stage. I'm sorry.
- Some aesthetic improvement.
- Added err function, as recommended in https://google.github.io/styleguide/shell.xml


== 0.1 ==

- Initial project
