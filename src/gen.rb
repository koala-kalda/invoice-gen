#!/bin/ruby

require 'erubis'
require 'icalendar'
require 'icalendar/recurrence'
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
		range = []
		for x in @data["date_range"]
			range << Date.parse( x)
		end

		events = []
		for event in ical.first.events
			summary = event.summary
			events += event.occurrences_between( range[0], range[1])
				.map{ |x| x.start_time}
				.select{ |x| ! event.exdate.include?( x)}
				.map{ |x| x.to_datetime + Rational( @data["time_buffer"], 24*60)}
				.map{ |x| [ summary, x.to_time.strftime( "%F %R")]}
		end
		events.sort_by! { |x| x[1]}

		if false
			dt = event.dtstart
			event_date = dt.to_date
			if ! ( range[0] <= event_date && event_date <= range[1])
				puts "something removed!"
			end
			dt = dt.to_time.strftime( "%F %R")

			@data["items"] << [ event.summary, dt]
		end

		@data["items"] += events
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
			{ V: "geometry:margin=3cm"},
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

	while ! argv.empty?
		arg = argv.shift
		case arg
		when "-d"
			args[:source] = argv.shift
		when "-t"
			args[:template] = argv.shift
		when "-o"
			args[:output] = argv.shift
		else
			args[:source] = arg
		end
	end

	return args
end

# main method
if __FILE__ == $0
	gen = InvoiceGen.new( parse_args( ARGV))
	gen.load()
	gen.generate()
	gen.save()
end
