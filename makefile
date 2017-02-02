# globals
default: all
all: invoices
clean:
	rm -rf bin/*
freshen: clean default

# vars
invoices = \
	bin/invoice-dac-1600061.pdf \
	bin/invoice-mya-1600059.pdf \
	bin/invoice-mynm-1600060.pdf \
	bin/invoice-myny-1600056.pdf \
	bin/invoice-myth-1600057.pdf \
	bin/invoice-myu-1600058.pdf

# defs
invoices: $(invoices)
$(invoices): bin/invoice-%.pdf : data/elliott/%.json \
		data/invoice/template.md.erb \
		data/invoice/template.tex \
		src/gen.rb
	src/gen.rb \
		$< \
		-t data/invoice/ \
		-o $@

# other
test:
	evince bin/*.pdf

ci:
	make-ci all \
		data/elliott/* \
		data/invoice/* \
		src/gen.rb