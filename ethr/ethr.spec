#
# RPM Spec for Ethr
#

Name:		ethr
Version:	0.2.1
Release:	1%{?dist}
Summary:	A tool for network performance measurement
BuildArch:	%(uname -m)
License:	MIT
Group:		Applications/System

Provides:	%{name} = %{version}-%{release}
Prefix:		%{_prefix}

Vendor:		Microsoft
Url:		https://github.com/microsoft/ethr

Source:		%{name}-%{version}.tar.gz

Requires:	glibc

BuildRequires:  golang >= 1.11
BuildRequires:  golang-github-mattn-go-runewidth-devel



%description
Ethr is a cross-platform network performance measurement tool written
in golang. Goal of this project is to provide a native tool for
network performance measurements of bandwidth, connections/s,
packets/s, latency, loss & jitter, across multiple protocols such as
TCP, UDP, HTTP, HTTPS, and across multiple platforms such as Windows,
Linux and other Unix systems.


%global debug_package %{nil}


%prep
%setup -q -n %{name}-%{version}
mkdir GOPATH

%build
GO_PATH_REL=gopath
mkdir -p "${GO_PATH_REL}"
export GOPATH=$(cd "${GO_PATH_REL}" && pwd -P)
export GOBIN=$(pwd -P)

go get ./...
go build -o "%{name}" .


%install
mkdir -p "%{buildroot}/%{_bindir}"
install -m 555 "%{name}" "%{buildroot}/%{_bindir}"


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root)
%{_bindir}/*
%license LICENSE
