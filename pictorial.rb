#!/usr/bin/env ruby

#	pictorial.rb
#	Evadne Wu at Iridia Productions, 2010

require 'rubygems'
require 'optparse'
require 'pp'

require 'find'
require 'ftools'
require 'pathname'

require 'directory_watcher'

gem 'visionmedia-growl'
require "growl"
include Growl

gem 'term-ansicolor'
require 'term/ansicolor'
include Term::ANSIColor

require 'active_support/secure_random'

require 'tmpdir'










PICTORIAL_PATH = Pathname.new(File.expand_path(File.dirname(__FILE__)))










class PictorialWatcher

	@@changeHandler = nil
	
	def initialize (monitorDirectory)
	
		@@changeHandler = DirectoryWatcher.new monitorDirectory, :pre_load => true

		@@changeHandler.interval = 1.0
		@@changeHandler.stable = 2.0
		
		@@changeHandler.glob = "*"
		@@changeHandler.add_observer self
		
		@@changeHandler.start

		begin

			gets
		
		end until false
	
	end
	
	def update( *events )

		ary = events.find_all { |event|
		
			event.type == :stable
		
		}
		
		return if ary.empty?
		
		ary.each { |evt|
			
			Pictorial.processFile evt.path
		
		}
		
		if Pictorial::options[:notify_by][:growl]
		
			notify_info "Updated #{ary.length} #{(ary.length > 1) ? "images" : "image"}", :title => "Pictorial", :icon => :jpeg
		
		end
		
		if Pictorial::options[:notify_by][:audible]
		
			puts 7.chr
		
		end

		sleep 0.5
		
	end	

end





class Pictorial





#	Options & the option parser

	@@options = {
	
		:from_directory => File.expand_path(File.dirname(__FILE__)),
		:to_directory => nil,
		
		:strip_chunks => [
		
			"gAMA", "sRGB"
		
		],
		
		:renaming_schemata => {
		
			:from => Regexp.new("(.+).png"),
			:to => "\\1-Staged.png"
		
		},
		
		:confirm_overwrite => false,
		
		:notify_by => {
		
			:growl => true,
			:audible => true
		
		},
		
		:verbose => false,
		:dry_run => false
	
	}
	
	def self.options
	
		@@options
	
	end
	
	
	
	
	
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
		
		options.on("--rename-to [String]", String, 
		
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

			@@options[:dry_run] = true
			
		}
		
		options.on("--notify-by growl, audible", Array, "Notify you on completed conversion.", "Defaults to growl, audible.") { |inNotificationMeans|
		
			@@options[:notify_by].each_key { |notifyType|
			
				@@options[:notify_by][notifyType] = false
			
			}
		
			inNotificationMeans.each { |notificationType|
			
				@@options[:notify_by] = true if @@options[:notify_by] != nil
			
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





#	The change handler

	@@changeHandler = nil





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
		
		
		
		
		
		@@options[:to_directory] = @@options[:from_directory].to_s if (@@options[:to_directory] == nil)
		
		if (@@options[:to_directory].to_s == @@options[:from_directory].to_s)
		
			self.say "A seperate directory named Pictorial will be created within the original directory."
		
			@@options[:to_directory] = @@options[:to_directory] + "/Pictorial"
		
		end
		
		File.mkpath @@options[:to_directory]
		
		puts "Monitoring:	#{@@options[:from_directory]}"
		puts "Destination:	#{@@options[:to_directory]}"
		puts "\n"
		
		@@changeHandler = PictorialWatcher.new @@options[:from_directory]
				
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
		plausibleDestinationPath = thePath.sub(@@options[:renaming_schemata][:from], @@options[:renaming_schemata][:to]).sub(@@options[:from_directory], @@options[:to_directory])
		
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
		
		if @@options[:dry_run]
		
			self.logWithTime "Dry Run: #{fromPathRef} -> #{toPathRef}"
			return
			
		else
		
			self.logWithTime "#{fromPathRef} -> #{toPathRef}"
		
		end

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




