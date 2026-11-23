# dmgbuild settings for the disk image Scripts/install-thundermist.sh --dmg
# makes. Finder opens the image on one fixed window with no toolbar or
# sidebar: the app on the left, Applications on the right, and a picture
# behind them with an arrow between and a hint at the top, which
# Scripts/thundermist-disk-image-background.swift draws for this layout. The
# image wears the app's icon.
#
# dmgbuild runs this file with these defines:
#   application  the signed, notarized app to put in the image
#   background   where to draw the picture
#   painter      Scripts/thundermist-disk-image-background.swift
import os
import plistlib
import subprocess

application = defines["application"]  # noqa: F821 (dmgbuild provides defines)
application_name = os.path.basename(application)
product_name = os.path.splitext(application_name)[0]

# The window and where each icon's center sits, in points from its top left.
WINDOW = (640, 400)
APPLICATION = (170, 190)
APPLICATIONS = (470, 190)

subprocess.run(
    ["/usr/bin/swift", defines["painter"], defines["background"],  # noqa: F821
     *(str(number) for number in WINDOW + APPLICATION + APPLICATIONS), product_name],
    check=True)

with open(os.path.join(application, "Contents/Info.plist"), "rb") as info:
    icon_name = plistlib.load(info)["CFBundleIconFile"]
if not icon_name.endswith(".icns"):
    icon_name += ".icns"

format = "ULFO"
filesystem = "HFS+"
files = [application]
symlinks = {"Applications": "/Applications"}
hide_extensions = [application_name]
hide = [".background.tiff", ".VolumeIcon.icns"]
icon = os.path.join(application, "Contents/Resources", icon_name)
background = defines["background"]  # noqa: F821

window_rect = ((200, 120), WINDOW)
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
arrange_by = None
label_pos = "bottom"
text_size = 13
icon_size = 128
icon_locations = {application_name: APPLICATION, "Applications": APPLICATIONS}
