default: gen
clean:
	rm -rf bin/*
freshen: clean default

gen: bin/invoice.pdf
bin/invoice.pdf: \
		data.json \
		data/invoice/template.md.erb \
		data/invoice/template.tex \
		src/gen.rb
	src/gen.rb \
		-d data.json \
		-t data/invoice \
		-o bin/invoice.pdf

test:
	evince bin/invoice.pdf

ci:
	make-ci gen \
		data.json \
		data/invoice/* \
		src/gen.rb