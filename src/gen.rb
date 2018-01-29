#!/bin/ruby

require 'erubis'
require 'icalendar'
require 'icalendar/recurrence'
require 'net/http'
require 'oj'
require 'pandoc-ruby'


class InvoiceGen
	attr_accessor :data

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
		r0 = Date.parse( @data["date_range"][0])
		r1 = Date.parse( @data["date_range"][1])

		prep = {}
		for event in ical.first.events
			summary = event.summary
			uid = event.uid
			last_mod = event.last_modified
			exdate = event.exdate.map{ |x| x.to_time}
			# @elliott: edit the lines below
			new_events = event.occurrences_between( r0, r1)
				.select{ |x| ! exdate.include?( x.start_time - 5*3600)}
				#.select{ |x| ! exdate.include?( x.start_time)}
				#.select{ |x| ! exdate.include?( x.start_time - 4*3600)}

			for occ in new_events
				dt = ( occ.start_time - 5*3600).to_datetime +
					Rational( @data["time_buffer"], 24*60)
				dt = dt.to_time.strftime( "%F %R")

				key = uid + dt
				val = [ last_mod, [ summary, dt]]
				if prep[key].nil?
					prep[key] = val
				elsif last_mod > prep[key][0].to_datetime
					prep[key] = val
				end
			end
		end

		@data["items"] += prep.values.map{ |x| x[1]}
		@data["items"].sort_by!{ |x| x[1]}
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
			{ V: "geometry:left=3.5cm,right=3.5cm,top=3.0cm,bottom=3.0cm"},
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
