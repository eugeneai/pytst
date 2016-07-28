.PHONY: swig clean setup develop

clean:
				rmdir -rf build
				python setup.py clean
swig:
				swig -O -I../include -DSCANNER -c++ -python tst.i

setup:
				python setup.py sdist install

develop:
				python setup.py develop
