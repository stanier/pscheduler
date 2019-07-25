#
# Makefile for python-pscheduler module
#

default: build


test:
	nosetests

test-coverage:
	nosetests --with-coverage


build: test
	python setup.py build
TO_CLEAN += *.egg-info

clean:
	make -C tests $@
	find . -name "*.pyc" | xargs rm -f
	rm -rf $(TO_CLEAN) *~
