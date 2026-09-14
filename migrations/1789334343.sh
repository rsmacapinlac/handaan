echo "Hand notifications to the Quickshell shell: disable and mask mako.service"

# Notifications are the shell's now (Commons/NotificationCenter.qml), and only
# one program can own org.freedesktop.Notifications on the session bus.
# install/post-install/services.sh no longer enables mako on a fresh install;
# this does the same on a machine that already has it enabled.
#
# Masked, not only disabled. mako's package ships a D-Bus activation file, so a
# notification sent while nothing owns the name starts mako through systemd --
# and a disabled unit still starts that way. A mask is what stops it. mako
# stays installed as the fallback; ~/.config/mako is yours and is left alone.
#
# The running mako is not stopped. It keeps notifications working for the rest
# of this session, and the shell claims the name at the next login. To switch
# now instead, stop mako and then restart the shell, in that order -- a shell
# restarted while mako still holds the name cannot take it:
#
#   systemctl --user stop mako.service
#   systemctl --user restart quickshell.service
#
# Idempotent: a mask already in place is left as it is.

if [[ $(systemctl --user is-enabled mako.service 2>/dev/null) == masked ]]; then
    echo "  mako.service is already masked; nothing to do"
    exit 0
fi

systemctl --user disable mako.service >/dev/null 2>&1 || true
systemctl --user mask mako.service
echo "  mako.service masked; the shell takes over notifications at your next login"
