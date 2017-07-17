# sketchup-tools

Scripts for creating cutlists and other model analyses in Sketchup.

## cutlist.rb

This script looks through the active model looking for dimensional lumber (N. American
sizes). Any group with a bounding box that matches the standard dimensions of lumber is 
coloured by size. This means that the script recognizes pieces with holes, tenons,
shaping, etc... It loops through all depths of groups, so pieces can be nested and still
identified.
