# globals
default: all
all: invoices
clean:
	rm -rf bin/*
freshen: clean default

# vars
invoices = \
	bin/invoice-dac-1600073.pdf \
	bin/invoice-dac-1600079.pdf \
	bin/invoice-mya-1600071.pdf \
	bin/invoice-mya-1600077.pdf \
	bin/invoice-mynm-1600072.pdf \
	bin/invoice-mynm-1600078.pdf \
	bin/invoice-myny-1600068.pdf \
	bin/invoice-myny-1600074.pdf \
	bin/invoice-myth-1600069.pdf \
	bin/invoice-myth-1600075.pdf \
	bin/invoice-myu-1600070.pdf \
	bin/invoice-myu-1600076.pdf

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

asdf.pdf: asdf.md
	pandoc asdf.md -o asdf.pdf
test-asdf: asdf.pdf
	evince asdf.pdf


ci:
	make-ci all \
		data/elliott/* \
		data/invoice/* \
		src/gen.rb