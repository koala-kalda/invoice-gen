#!/bin/ruby

require 'erubis'
require 'icalendar'
require 'net/http'
require 'oj'
require 'pandoc-ruby'


class InvoiceGen
	def initialize( args)
		self.config( args)
	end

	def config( args)
		@source = args[ :source]
		@template = args[ :template]
		@output = args[ :output]
		@result = nil

		@template_erb = @template + "template.md.erb"
		@template_tex = @template + "template.tex"
	end

	def load()
		# load data from file
		@data = Oj.load_file( @source)

		# load items from calendar source
		ical_data = Net::HTTP.get( URI( @data["cal_source"]))
		ical = Icalendar::Calendar.parse( ical_data)
		load_items( ical)

		# autocomplete item data
		complete()

		# load erb from template
		@erb = Erubis::FastEruby.new( File.read( @template_erb))
	end

	def load_items( ical)
		for event in ical.first.events
			puts event.dtstart
			@data["items"] << [ event.summary, event.dtstart]
			break
		end
	end

	def complete()
		base = @data["base_rate"]
		subtotal = 0

		for item in @data["items"]
			if item.size <= 2
				item << base
			end
			subtotal += item[2]
		end

		@data["subtotal"] = subtotal
		@data["sub_tax"] = subtotal * @data["tax"]["rate"]
		@data["total"] = subtotal + @data["sub_tax"]
	end

	def generate( data = @data)
		# generate markdown
		markdown = @erb.evaluate( data)

		# generate pdf
		PandocRuby.convert(
			markdown,
			{ f: :markdown, to: :latex},
			{ template: @template_tex},
			{ o: @output})
	end

	def save( filename = nil)
		# save result to file
		output = filename.nil? ? @output : filename

	end
end

DEFAULT_ARGS = {
	source: "data.json",
	template: "data/invoice/",
	output: "bin/invoice.pdf"
}

def parse_args( argv)
	args = DEFAULT_ARGS.dup

	return args
end

# main method
if __FILE__ == $0
	gen = InvoiceGen.new( parse_args( ARGV))
	gen.load()
	gen.generate()
	gen.save()
end
