#!/usr/bin/env ruby
# encoding: UTF-8

#	File+PictorialAdditions.rb
#	Evadne Wu at Iridia, 2010

require 'SecureRandom'

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




