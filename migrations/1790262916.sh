echo "Install arch-audit, so the bar can tell security updates from ordinary ones"

# bin/handaan-pending now emits an `arch-security` count: which of the pending
# package updates carry a published security fix. Arch ships no security
# repository, so nothing on the machine separates those from any other update
# -- the answer exists only in the Arch Security Team's tracker, and arch-audit
# is their own tool over it. A fresh install gets it from install/base.packages.
#
# Without the package that count reports `?` rather than 0. Blind is not the
# same as clear, and keeping those apart is the whole point of handaan-pending
# -- but a machine that never installs this would report a blind check forever
# while looking exactly like one with nothing waiting.
#
# Nothing else changes: the other counts are unaffected, and the bar does not
# read arch-security yet.
#
# Idempotent: an installed arch-audit is left alone.

if pacman -Q arch-audit &>/dev/null; then
    echo "  arch-audit is already installed; nothing to do"
    exit 0
fi

sudo pacman -S --needed --noconfirm arch-audit
