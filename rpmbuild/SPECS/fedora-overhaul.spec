Name:       fedora-overhaul
Version:    1.0
Release:    1
Summary:    Fedora setup tool
License:    MIT
Source0:    fedora-overhaul.tar.gz
Requires:   curl git zenity pipewire-utils flatpak dnf-plugins-core grubby pciutils gtk3 gtk4 pkexec
BuildArch:  noarch

%description
Set up your Fedora Linux easy way

%prep
%setup -q -n rpm-src

%install
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons
mkdir -p %{buildroot}/opt/fedora-overhaul

install -m 0755 fedora-overhaul        %{buildroot}/usr/local/bin/fedora-overhaul
install -m 0644 fedora-overhaul.desktop %{buildroot}/usr/share/applications/
install -m 0644 fedora-overhaul.png     %{buildroot}/usr/share/icons/

%files
/usr/local/bin/fedora-overhaul
/usr/share/applications/fedora-overhaul.desktop
/usr/share/icons/fedora-overhaul.png
%dir /opt/fedora-overhaul