#!/usr/bin/env ruby
# encoding: UTF-8

#	coding: utf-8

# slicer.rb
# Evadne Wu at Iridia, 2010





# Usage:
# slicer.rb <input> <topOffset> <rightOffset> <bottomOffset> <leftOffset>

# Example: slicer.rb image.png 16 16 16 16
# Will: make image_1.png to image_9.png using the offsets specified.

	require 'chunky_png'
	require 'pp'




	if ARGV[0].nil? || ARGV.length != 5
		
		puts "Usage: slicer.rb <input> <topOffset> <rightOffset> <bottomOffset> <leftOffset>"
		exit 
		
	end
	
	
	
	
	
	image = ChunkyPNG::Image.from_file(ARGV[0])
	offsets = []
	
	for index in 1..4 do
		
		offsets.push ARGV[index].to_i
		
	end
	
	for index in 1..9 do
		
		image.crop(
		
			[image.width - offsetRight, 0, offsetLeft][index % 3],		# Starting X -> 1, 2, 0
			[0, offsetTop, image.height - offsetBottom][(index / 3.0).ceil - 1],		# Starting Y -> 0, 1, 2
			[offsetRight, offsetLeft, image.width - offsetLeft - offsetRight][index % 3],		# Width -> 1, 2, 0
			[offsetTop, image.height - offsetTop - offsetBottom, offsetBottom][(index / 3.0).ceil - 1],		# Height -> 0, 1, 2
			
		).save(imagePath.gsub(/\.png/, "") + "_#{index}.png")
		
	end
	
	


