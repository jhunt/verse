default: test

docker:
	cd docker && make

release: docker
	ci/release

test:
	prove -l t/*.t
check: test

Build: Build.PL
	perl ./Build.PL
manifest: Build
	./Build manifest

.PHONY: default docker release test check manifest
