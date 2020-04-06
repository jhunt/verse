default: test

docker:
	docker build -t huntprod/verse .

verse:
	rm -f verse-*
	./pack $(VERSION) && cp verse-* $@

release:
	@echo "Checking that VERSION was defined in the calling environment"
	@test -n "$(VERSION)"
	@echo "OK.  VERSION=$(VERSION)"
	make verse
	make docker
	docker tag huntprod/verse huntprod/verse:$(VERSION)
	docker push huntprod/verse:latest
	docker push huntprod/verse:$(VERSION)

test:
	docker build -t huntprod/verse-test -f t/Dockerfile .
	docker run --rm -v $(PWD):/app -u $(shell id -u) huntprod/verse-test

clean:
	rm -f verse-* verse

.PHONY: default docker release test
