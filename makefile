# globals
default: all
all: invoices
clean:
	rm -rf bin/*
freshen: clean default

# vars
invoices = \
	bin/invoice-myny-1700091.pdf \
	bin/invoice-myth-1700092.pdf \
	bin/invoice-myu-1700093.pdf \

# defs
invoices: $(invoices)
$(invoices): bin/invoice-%.pdf : data/elliott/%.json \
		data/invoice/template.md.erb \
		data/invoice/template.tex \
		src/gen.rb
	bundle exec src/gen.rb \
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
