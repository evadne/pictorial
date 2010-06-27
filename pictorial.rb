#!/usr/bin/env ruby
# encoding: UTF-8

#	coding: utf-8

#	pictorial.rb
#	Evadne Wu at Iridia Productions, 2010

require 'rubygems'
require 'optparse'
require 'pp'

require 'find'
require 'fileutils'
require 'pathname'

gem 'directory_watcher'
require 'directory_watcher'

gem 'ruby-growl'
require 'ruby-growl'


gem 'term-ansicolor'
require 'term/ansicolor'
include Term::ANSIColor

require 'SecureRandom'

require 'tmpdir'










PICTORIAL_PATH = Pathname.new(File.expand_path(File.dirname(__FILE__)))










class File

	def self.uniquePath (originalPath = nil, hashPaddingDigits = 2)
	
		return if originalPath.nil?		
		return originalPath if !(File.exists? originalPath)
		
		destinationPath = originalPath
		originalExtension = File.extname(originalPath).to_s
		
		while File.exists? destinationPath do
		
			if originalExtension.empty?
			
				destinationPath = originalPath + "." + SecureRandom.hex(hashPaddingDigits)
				
			else
			
				destinationPath = originalPath.sub(originalExtension, ".#{SecureRandom.hex(hashPaddingDigits)}#{originalExtension}")
			
			end
							
		end
		
		return destinationPath
						
	end

end










class Pictorial







#	Options & the option parser

	@@options = {
	
		:from_directory => 		File.expand_path(File.dirname(__FILE__)),
		:to_directory => 		nil,
		:strip_chunks => 		[ "gAMA", "sRGB"],
		:renaming_schemata => 		{ :from => /(.+).png/, :to => "\\1-Staged.png" },
		:overwrite_existing_file => 	false,
		:notify_by => 			{ :growl => true, :audible => true },		
		:verbose => 			false,
		:dry_run =>			false
	
	}
	
	
	
	
	
	@@optionParser = OptionParser.new { |options|
		
		options.banner = "Usage: pictorial.rb [options]"
		
		
		
		
		
		options.separator ""
		options.separator "Locating & processing files:"
		options.separator ""
		
		options.on("--from-directory [STRING]", String, "Monitored (Source) directory") { |inFromDirectory|

			self.complain "The source directory does not exist." if (!File.directory? inFromDirectory)
			
			@@options[:from_directory] = Pathname.new(inFromDirectory).realpath
			
		}
		
		options.on("--to-directory [STRING]", String, "Destination directory") { |inToDirectory|

			self.complain("The destination directory does not exist and will be created.", false) if (!File.directory? inToDirectory)
			
			@@options[:to_directory] = Pathname.new(inToDirectory).realpath
			
		}
		
		options.on("--[no-]overwrite-existing-file",
		
			"Overwrite existing file?"
			
		) { |inOverwriteExistingFile|
		
			@@options[:overwrite_existing_file] = inOverwriteExistingFile
		
		}
		
		options.on("--strip sRGB", Array, 
		
			"Chunks to strip.", 
			"Defaults to gAMA & sRGB."
			
		) { |inStripBulks|
		
			@@options[:strip_chunks] = inStripBulks

		}
		
		
		
		
		
		options.separator ""
		options.separator "Renaming files:"
		options.separator ""
		
		options.on("--rename-from [RegExp]", Regexp, 
			
			"Regexp that works with --rename-to.", 
			"Example: \"(.+)(.png)"
			
		) { |inRenameFrom|

			@@options[:renaming_schemata][:from] = inRenameFrom
			
		}
		
		options.on("--rename-to [String]", String, 
		
			"Template string that works with --rename-from.", 
			"Example: \"\\1\\2\""
			
		) { |inRenameTo|

			@@options[:renaming_schemata][:to] = inRenameTo
			
		}
		
		
		
		
		
		options.separator ""
		options.separator "Notification / Logging:"
		options.separator ""
		
		options.on("-d", "--dry-run", "Dry Run") { |input|

			@@options[:dry_run] = true
			
		}
		
		options.on("--notify-by growl, audible", Array, 
		
			"Notify you on completed conversion.", 
			"Defaults to growl, audible."
			
		) { |inNotificationMeans|
		
			@@options[:notify_by].each_key { |notificationType|
			
				@@options[:notify_by][notificationType] = false
			
			}
		
			inNotificationMeans.each { |notificationType|
			
				@@options[:notify_by][notificationType] = true if @@options[:notify_by][notificationType] != nil
			
			}
		
		}
		
		
		
		
		
		options.separator ""
		options.separator "Common options:"
		options.separator ""
		
		options.on("-v", "--[no-]verbose", "Be verbose?") { |inVerbose|
		
			@@options[:verbose] = inVerbose
		
		}

		options.on_tail("-h", "--help", "Shows this message.") {

			puts options
			exit

		}
		
	}





#	Bail, hashing and logging helpers
	
	def self.complain (message = "", exits = true)
	
		puts "Error: #{message} \n"
		exit if exits
	
	end
	
	def self.say (message = "")
	
		puts message if @@options[:verbose]
	
	end
	
	def self.logWithTime (message = "")
	
		timeString = Time.now.strftime("%H:%M:%S")
		puts "[#{timeString}] #{message}"
	
	end
	
	def self.warn (message = "", info = "")
	
		print red(message)
		puts "\n"
		puts info
		puts "\n"
	
	end





#	The change handler

	@@changeHandler = nil





#	Main Routine

	def self.initialize
	
		begin
	
			@@optionParser.parse!
			
		rescue Exception => exceptionMessage
		
			if (exceptionMessage.to_s != "exit")
		
				puts "Oops: #{exceptionMessage}"
				puts "\n"
				puts @@optionParser.help
				puts "\n"
			
			end
		
		end
		
		
		
		
		
		pp @@options if @@options[:verbose]
		
		
		
		
		
		@@options[:to_directory] = @@options[:from_directory].to_s if (@@options[:to_directory] == nil)
		
		if (@@options[:to_directory].to_s == @@options[:from_directory].to_s)
		
			self.say "A seperate directory named Pictorial will be created within the original directory."
		
			@@options[:to_directory] = @@options[:to_directory] + "/Pictorial"
		
		end
		
		
		
		
		
		FileUtils.mkpath @@options[:to_directory]
		
		puts "Monitoring:	#{@@options[:from_directory]}"
		puts "Destination:	#{@@options[:to_directory]}"
		puts "\n"
		
		
		
		
		
		@@changeHandler = DirectoryWatcher.new @@options[:from_directory], :pre_load => true

		@@changeHandler.interval = 1.0
		@@changeHandler.stable = 2.0
		
		@@changeHandler.glob = "*"
		@@changeHandler.add_observer { | *events | 
		
			stableFileEvents = events.find_all { |event| event.type == :stable }
			return if stableFileEvents.empty?
			
			eligibleFileEvents = stableFileEvents.find_all { |event| Pictorial.isEligibleFile(event.path) }
			return if eligibleFileEvents.empty?
			
			self.processFiles eligibleFileEvents.map { |event| event.path }
		
		}
		
		@@changeHandler.start

		begin

			gets
		
		end until false
				
	end





#	Introspection

	def self.isEligibleFile (thePath)
	
		return (@@options[:renaming_schemata][:from].match thePath) != nil
	
	end





#	Workers

	def self.processFiles (files)
	
		files.each { |filePath| self.processFile(filePath) }

		self.notifyGrowl "Updated #{files.length} image#{(files.length > 1) ? "s" : ""}}" if @@options[:notify_by][:growl]
		
		self.notifyAudible if @@options[:notify_by][:audible]
	
	end
	
	
	
	
	
	def self.processFile(thePath)
	
		return self.say "#{thePath} is not an eligible file, ignoring." if !self.isEligibleFile(thePath)
		
		sourcePath = thePath
		
		destinationPath = thePath.sub(@@options[:renaming_schemata][:from], @@options[:renaming_schemata][:to]).sub(@@options[:from_directory].to_s, @@options[:to_directory].to_s)
				
		self.say "#{destinationPath} already exists.  We’ll append a hash to the filename.  Use --confirm-overwrite to suppress this behavior and overwrite the file." if ((File.exists? destinationPath) && !(@@options[:overwrite_existing_file]))
		
		destinationPath = File.uniquePath(destinationPath) if !(@@options[:overwrite_existing_file])
		
		self.crushPNG(sourcePath, destinationPath)
	
	end
	
	
	
	
	
	def self.crushPNG(fromPath = nil, toPath = nil)
	
		self.logWithTime "#{fromPath} -> #{toPath}"
		
		return if @@options[:dry_run]
		
		fork { exec(
		
			"pngcrush
			
				#{@@options[:strip_chunks].empty? ? "" : (" -rem " + @@options[:strip_chunks].join(" -rem "))}
				\"#{Pathname.new(fromPath).relative_path_from(PICTORIAL_PATH)}\"
				\"#{Pathname.new(toPath).relative_path_from(PICTORIAL_PATH)}\"
				#{@@options[:verbose] ? "" : " > /dev/null"}
			
			".gsub("\t", " ").gsub("\n", " ")
			
		)}
		
		Process.wait
		self.say "PNGCrush exited with status #{$?.exitstatus}"
			
	end
	
	
	
	
	
#	Notifications

	@@notificationRepresentativeGrowl = Growl.new "localhost", "pictorial", ["Pictorial"]

	def self.notifyGrowl (message = "", title = "Pictorial")
	
		@@notificationRepresentativeGrowl.notify "Pictorial", title, message
	
	end
	
	def self.notifyAudible
	
		puts 7.chr
		
	end

end









Pictorial.initialize




