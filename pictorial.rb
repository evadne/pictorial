#!/usr/bin/env ruby

#	pictorial.rb
#	Evadne Wu at Iridia Productions, 2010

require 'rubygems'
require 'optparse'
require 'pp'

require 'find'
require 'ftools'
require 'pathname'

gem 'ruby-fsevent'
require 'fsevent'

gem 'visionmedia-growl'

gem 'term-ansicolor'
require 'term/ansicolor'
include Term::ANSIColor

require 'active_support/secure_random'

require 'tmpdir'










PICTORIAL_PATH = Pathname.new(File.expand_path(File.dirname(__FILE__)))

class PictorialFileChangeHandler < FSEvent

	@@lastCalled = Time.now

	def on_change(directories)

		puts "on change"

		changedFiles = []

		directories.each { |theDirectory|
		
			next if !File.directory? theDirectory
		
			Find.find(theDirectory) { |thePath|
			
				next if File.atime(thePath) < @@lastCalled
				puts "file is accessed after script is first called"
				
				next if File.directory? thePath
				changedFiles.push(thePath)
				
			}
			
		}
		
		@@lastCalled = Time.now
		
		Pictorial.handleChange(changedFiles) if changedFiles.length != 0
		
	end
  
end










class Pictorial





#	Options & the option parser

	@@options = {
	
		:from_directory => File.expand_path(File.dirname(__FILE__)),
		:to_directory => File.expand_path(File.dirname(__FILE__)),
		
		:strip_chunks => [
		
			"gAMA", "sRGB"
		
		],
		
		:renaming_schemata => {
		
			:from => Regexp.new("(.+).png"),
			:to => "\\1-Staged.png"
		
		},
		
		:confirm_overwrite => false,
		
		:notify_by => [
		
			"growl", "audible"
		
		],
		
		:verbose => false,
		:dryRun => false
	
	}
	
	
	
	
	
	@@optionParser = OptionParser.new { |options|
		
		options.banner = "Usage: pictorial.rb [options]"
		
		
		
		
		
		options.separator ""
		options.separator "Locating & processing files:"
		options.separator ""
		
		options.on("--from-directory", String, "Monitored (Source) directory") { |inFromDirectory|

			self.complain "The source directory does not exist." if (!File.directory? inFromDirectory)
			
			@@options[:from_directory] = inFromDirectory
			
		}
		
		options.on("--to-directory", String, "Destination directory") { |inToDirectory|

			self.complain("The destination directory does not exist and will be created.", false) if (!File.directory? inToDirectory)
			
			if (inToDirectory == @@options[:from_directory])
			
				self.complain("A seperate directory named Pictorial will be created within the original directory.", false)
			
				inToDirectory = inToDirectory + "/Pictorial"
			
			end
			
			File.mkpath inToDirectory

			@@options[:to_directory] = inToDirectory
			
		}
		
		options.on("--confirm-overwrite", "Confirm overwrite") {
		
			@@options[:confirm_overwrite] = true
		
		}
		
		options.on("--strip sRGB", Array, "Chunks to strip.", "Defaults to gAMA & sRGB.") { |inStripBulks|
		
			@@options[:strip_chunks] = inStripBulks

		}
		
		
		
		
		
		options.separator ""
		options.separator "Renaming files:"
		options.separator ""
		
		options.on("--rename-from [RegExp]", Regexp, 
			
			"Process files matching this regular expression literal.", 
			"Example: \"(.+)(.png)", 
			"Works with --rename-to."
			
		) { |inRenameFrom|

			@@options[:renaming_schemata][:from] = inRenameFrom
			
		}
		
		options.on("--rename-to [String]", Regexp, 
		
			"When replacing captured groups during file rename, use this string as the template.", 
			"Example: \"\\1\\2\"", 
			"Works with --rename-from."
			
		) { |inRenameTo|

			@@options[:renaming_schemata][:to] = inRenameTo
			
		}
		
		
		
		
		
		options.separator ""
		options.separator "Notification / Logging:"
		options.separator ""
		
		options.on("-d", "--dry-run", "Dry Run") { |input|

			@@options[:dryRun] = true
			
		}
		
		options.on("--notify-by growl, audible", Array, "Notify you on completed conversion.", "Defaults to growl, audible.") { |inNotificationMeans|
		
			@@options[:notify_by] = inNotificationMeans
		
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





#	The change handler

	@@changeHandler = PictorialFileChangeHandler.new





#	Bail, hashing and logging helpers
	
	def self.complain (message = "", exits = true)
	
		puts "Error: #{message}"
		puts "\n"
		
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
	
	def self.describeOptions
	
		puts "Options:"
		puts "\n"
		pp @@options
		puts "\n"
	
	end
	
	def self.randomHash
	
		ActiveSupport::SecureRandom.hex(2)
	
	end





#	Main Routine

	def self.initialize
	
		puts "\n"
	
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
		
		self.describeOptions if @@options[:verbose]
		
		self.say "Monitoring:	#{@@options[:from_directory]}"
		self.say "Destination:	#{@@options[:to_directory]}"
		
		
		@@changeHandler.watch_directories @@options[:from_directory]
		@@changeHandler.latency = 2
		@@changeHandler.start
		
	end





#	Introspection

	def self.isEligibleFile (thePath)
	
		return (@@options[:renaming_schemata][:from].match thePath) != nil
	
	end





#	Workers

	def self.handleChange(changedFiles)
	
		@@changeHandler.stop
	
		self.say "\n"
		self.say "Got changed files:"
		self.say changedFiles
		
		changedFiles.each { |thePath|
		
			self.processFile(thePath)
		
		}
		
		self.say "\n"
		
		@@changeHandler.start
		
	end
	
	def self.processFile(thePath)
	
		return self.say "#{thePath} is not an eligible file, ignoring." if !self.isEligibleFile(thePath)
		
		sourcePath = thePath
		plausibleDestinationPath = thePath.sub(@@options[:renaming_schemata][:from], @@options[:renaming_schemata][:to])
		
		destinationPath = plausibleDestinationPath
		
		if ((File.exists? destinationPath) && (!@@options[:confirm_overwrite]))
		
			self.say "#{destinationPath} already exists.  We’ll append a hash to the filename.  Use --confirm-overwrite to suppress this behavior and overwrite the file."
			
			extensionName = File.extname(destinationPath)
			
			destinationPath = plausibleDestinationPath
			
			begin
			
				destinationPath = plausibleDestinationPath.sub(extensionName, "#{extensionName.empty? ? '' : '.'}#{self.randomHash}#{extensionName}")
							
			end until !(File.exists? destinationPath)
		
		end
		
		self.crushPNG(sourcePath, destinationPath)
	
	end
	
	def self.crushPNG(fromPath = nil, toPath = nil)
	
		fromPathRef = Pathname.new(fromPath).relative_path_from(PICTORIAL_PATH)
		toPathRef = Pathname.new(toPath).relative_path_from(PICTORIAL_PATH)
		
		self.logWithTime "#{fromPathRef} -> #{toPathRef}"

		argumentRemovingChunks = ""

		@@options[:strip_chunks].each { |chunkName|
		
			argumentRemovingChunks = argumentRemovingChunks + " -rem #{chunkName}"
		
		}
		
		self.say "pngcrush #{argumentRemovingChunks} \"#{fromPath}\" \"#{toPath}\""
		
		commandReturn = `pngcrush #{argumentRemovingChunks} \"#{fromPath}\" \"#{toPath}\"`
		
		self.say commandReturn
	
	end
	

end









Pictorial.initialize




