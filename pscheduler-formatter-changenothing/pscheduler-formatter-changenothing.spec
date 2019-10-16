#
# RPM Spec for a pScheduler formatter
#

%define short	changenothing
%define perfsonar_auto_version 4.2.2
%define perfsonar_auto_relnum 0.a0.0

Name:		pscheduler-formatter-%{short}
Version:	%{perfsonar_auto_version}
Release:	%{perfsonar_auto_relnum}%{?dist}

Summary:	Null archiver formatter class for pScheduler
BuildArch:	noarch
License:	ASL 2.0
Vendor:		perfSONAR
Group:		Unspecified

Source0:	%{short}-%{version}.tar.gz

Provides:	%{name} = %{version}-%{release}

Requires:	pscheduler-server

BuildRequires:	pscheduler-rpm >= 1.0.0.5.1


%define directory %{_includedir}/make

%description
This formatter does nothing.


%prep
%setup -q -n %{short}-%{version}


%define dest %{_pscheduler_formatter_libexec}/%{short}

%build
make \
     DESTDIR=$RPM_BUILD_ROOT/%{dest} \
     install


%post
pscheduler internal warmboot

%postun
pscheduler internal warmboot


%files
%defattr(-,root,root,-)
%license LICENSE
%{dest}
