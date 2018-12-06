#
# RPM Spec for Python isodate Module
#

%define short	setuptools
Name:		python-%{short}
Version:	40.6.2
Release:	1%{?dist}
Summary:	Python setup tools
BuildArch:	%(uname -m)
License:	MIT
Group:		Development/Libraries

Provides:	%{name} = %{version}-%{release}
Prefix:		%{_prefix}

Vendor:		Python Packaging Authority
Url:		https://github.com/pypa/setuptools

Source:		%{short}-%{version}.tar.gz

Requires:	python

BuildRequires:	python-devel



%description
Python setup tools



# Don't do automagic post-build things.
%global              __os_install_post %{nil}
%global		     debug_package %{nil}

%prep
%setup -q -n %{short}-%{version}


%build
python setup.py build


%install
python setup.py install --root=$RPM_BUILD_ROOT -O1  --record=INSTALLED_FILES

# Some of the files produced have spaces in the names.
sed -i -e 's/^/"/g; s/$/"/g' INSTALLED_FILES 


%clean
rm -rf $RPM_BUILD_ROOT


%files -f INSTALLED_FILES
%defattr(-,root,root)
