# globals
default: all
all: invoices
clean:
	rm -rf bin/*
freshen: clean default

# vars
invoices = \
	bin/invoice-myny-1600035.pdf \
	bin/invoice-myth-1600036.pdf \
	bin/invoice-myu-1600037.pdf

# defs
gen: bin/invoice-myny-1600035.pdf

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
	evince bin/invoice-myny-1600035.pdf
test2:
	evince bin/invoice-myth-1600036.pdf
test3:
	evince bin/invoice-myu-1600037.pdf

ci:
	make-ci all \
		data/elliott/* \
		data/invoice/* \
		src/gen.rb