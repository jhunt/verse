default: test

release:
	ci/release

test:
	prove -l t/*.t
check: test

Build: Build.PL
	perl ./Build.PL
manifest: Build
	./Build manifest

.PHONY: default release test check manifest
