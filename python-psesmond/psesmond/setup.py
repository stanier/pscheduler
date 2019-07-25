#!/usr/bin/python

from setuptools import setup

setup(
    name='psesmond',
    version='0.1.1',
    description='Esmond utisilites for pScheduler',
    url='http://www.perfsonar.net',
    author='The perfSONAR Development Team',
    author_email='perfsonar-developer@perfsonar.net',
    license='Apache 2.0',
    packages=[
        'psesmond'
    ],
    install_requires=[
        'pscheduler'
    ],
    include_package_data=True,

    tests_require=['nose'],
    test_suite='nose.collector',
)
