= Changelog

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