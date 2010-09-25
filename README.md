#	Pictorial

Pictorial is your tiny image factory.  It monitors a particular directory for new `.png` files matching a particular regular expression, runs them through `PNGCrush`, strips chunks (like, the gamma information or the color profile) optionally, renames them, and places them in another directory before showing a Growl notification or an audible alert.





##	Dependncy / Limits

You’ll need to have `PNGCrush`, obtainable thru MacPorts.  This script relies on OS X’s `fsevents` too.





##	Usage (multi-lined)

	$ ./pictorial.rb                                                \
	                                                                \
	        --from-directory "."                                    \
	        --to-directory "../frontend/ui"                         \
	                                                                \
	        --confirm-overwrite                                     \
	                                                                \
	        --strip sRGB, gAMA                                      \
	                                                                \
	        --rename-from "okogreen.scaffold_(.+).png"              \
	        --rename-to "\1.png"                                    \
	                                                                \
	        --notify-by growl, audible                              \
	                                                                \
	        --dry-run





##	Notes

*	`--from-directory` and `--to-directory` both asks for path references and defaults to the current directory.

*	If `--confirm-overwrite` is not specified, then conflicts will cause the old files to be renamed `fileName.<HASH>(.extension)`.  Otherwise, conflicts will cause the old files to be overwritten.  Other parameters are self-documentary.

*	Specifying `--dry-run` will cause Pictorial not to modify any file.

*	`--strip` wants an array of chunks that PNGCrush understands.

*	`--notify-by nil` silences the beep and suppresses the Growl notification.





##	Contact

Evadne Wu at Iridia Productions, 2010 — `ev@iridia.tw`.



