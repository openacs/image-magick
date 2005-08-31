ad_library {
    This is free software distributed under the terms of the GNU General Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    Initialises the Image Magick module.

    @author Tom Ayles (tom@beatniq.net)
    @creation-date 2004-01-09
    @cvs-id $Id$
}

set tmp_dir [parameter::get_from_package_key -package_key image-magick \
                 -parameter TmpDir]

# make temporary directory if not present

if {![file exists $tmp_dir]} {
    if {[catch {file mkdir $tmp_dir} err]} {
        ns_log Error "Error preparing TmpDir image-magick may not function correctly, message was: $err"
    }

    if {![file writable $tmp_dir]} {
        ns_log Error "$tmp_dir is not writable, image-magick may not function correctly"
    }
}

if {[parameter::get_from_package_key -package_key image-magick \
         -parameter ClearTmpDirOnStartupP]} {
    set files [glob "${tmp_dir}/*"]
    ns_log Notice "ImageMagick deleting temporary files: $files"
    eval "file delete [join $files]"
}
