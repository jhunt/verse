default: test

docker:
	docker build -t huntprod/verse .
	docker run huntprod/verse help

verse:
	rm -f verse-*
	./pack $(VERSION) && cp verse-* $@

release:
	@echo "Checking that VERSION was defined in the calling environment"
	@test -n "$(VERSION)"
	@echo "OK.  VERSION=$(VERSION)"
	docker build -t huntprod/verse:latest --build-arg VERSION=$(VERSION) .
	docker tag huntprod/verse:latest huntprod/verse:$(VERSION)
	docker push huntprod/verse:latest
	docker push huntprod/verse:$(VERSION)

test:
	docker build -t huntprod/verse-test -f t/Dockerfile .
	docker run --rm -v $(PWD):/app -u $(shell id -u) huntprod/verse-test

clean:
	rm -f verse-* verse

.PHONY: default docker release test
