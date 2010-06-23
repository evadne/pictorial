#	`pictorial.rb`

Pictorial is your tiny image factory.  It monitors a particular directory for new `.png` files, runs them through `pngcrush`, strips the gamma information and the color profile optionally, renames them optionally, and places them in another directory before showing a Growl notification.





##	Dependncy

You’ll need to have PNGCrush installed.





##	Usage (multi-lined)

	$ pictorial                                                     \
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

*	If `--confirm-overwrite` is not specified, then conflicts will cause the old files to be renamed `fileName.old.<HASH>`.  Otherwise, conflicts will cause the old files to be overwritten.  Other parameters are self-documentary.

*	Specifying `--dry-run` will cause Pictorial not to modify any file.

*	`--strip` wants an array of chunks that PNGCrush understands.

*	`--notify-by nil` silences the beep and suppresses the Growl notification.




