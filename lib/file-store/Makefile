DEFAULT_REPORTER = nyan
MOCHA_OPTS = \
	--check-leaks \
	--compilers coffee:coffee-script/register \
	--colors
STANDARD_TEST_CMD = \
	@NODE_ENV=test \
	NODE_PATH=../ \
	./node_modules/.bin/mocha \
	${MOCHA_OPTS}


test:
	${STANDARD_TEST_CMD} --reporter ${DEFAULT_REPORTER}


test-w:
	${STANDARD_TEST_CMD} --reporter min --watch


# Non-interactive test format
test-n:
	${STANDARD_TEST_CMD} --reporter tap


.PHONY: test
