#
# RPM Spec for Python pScheduler Esmond Utilities
#

%define perfsonar_auto_version 4.2.0
%define perfsonar_auto_relnum 0.1.b1

%define short	psesmond
Name:		python-%{short}
Version:	%{perfsonar_auto_version}
Release:	%{perfsonar_auto_relnum}%{?dist}
Summary:	Esmond utility functions for pScheduler
BuildArch:	noarch
License:        ASL 2.0	
Group:		Development/Libraries

Provides:	%{name} = %{version}-%{release}
Prefix:		%{_prefix}

Vendor:		perfSONAR
Url:		http://www.perfsonar.net

Source0:	%{short}-%{version}.tar.gz

# NOTE: The runtime Python module requirements must be duplicated in
# BuildRequires because they're required to run the tests.

Requires:	python-pscheduler

%description
Esmond utilities for pScheduler


# Don't do automagic post-build things.
%global              __os_install_post %{nil}


%prep
%setup -q -n %{short}-%{version}


%build
make


%install
python setup.py install --root=$RPM_BUILD_ROOT -O1  --record=INSTALLED_FILES



%clean
rm -rf $RPM_BUILD_ROOT

%files -f INSTALLED_FILES
%defattr(-,root,root)
%license LICENSE
