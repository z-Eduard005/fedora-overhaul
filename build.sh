#!/bin/bash
PROJECT_DIR="$HOME/Projects/fedora-overhaul"
RPM_DIR="$PROJECT_DIR/rpmbuild"

tar czf "$RPM_DIR/SOURCES/fedora-overhaul.tar.gz" -C "$PROJECT_DIR" "rpm-src/"
rpmbuild --define "_topdir $RPM_DIR" -bb "$RPM_DIR/SPECS/fedora-overhaul.spec"
mv "$RPM_DIR/RPMS/noarch/fedora-overhaul-1.0-1.noarch.rpm" "$PROJECT_DIR/docs/fedora-overhaul.rpm"
