ad_library {
    This is free software distributed under the terms of the GNU General Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    Provides a set of procedures that encapsulate the Image Magick command
    line image manipulation tools.

    @author Tom Ayles (tom.ayles@dsl.pipex.com)
}

namespace eval ::ImageMagick {}

ad_proc -private ::ImageMagick::bin_path {
} {
    set bin_path [parameter::get_from_package_key \
                      -package_key {image-magick} \
                      -parameter {bin_path}]
    if ![regexp /$ $bin_path] {
        append bin_path /
    }
    return $bin_path
}

ad_proc -public ::ImageMagick::convert_path {
} {
    Returns the full path to the ImageMagick convert binary.
} {
    return "[bin_path]convert"
            
}

ad_proc -public ::ImageMagick::identify_path {
} {
    Returns the full path to the ImageMagick identify binary.
} {
    return "[bin_path]identify"
}

ad_proc -public ::ImageMagick::convert {
    {-options {}}
    {-geometry {}}
    {-output_format {}}
    input_file
    output_file
} {
    Invokes the ImageMagick convert command with the given arguments.
    Ultimately, all options to convert will be encapsulated as switch 
    parameters to this procedure, and validation can be done on that.
    However, until this is done, the <code>options</code> parameter
    can be used to specify arbitrary extra parameters.

    @param options A list of extra options to pass to convert
    @param output_format The output format to use
    @param input_file The full path to the input file
    @param output_file The full path to the output file
} {
    set args {}
    foreach option $options {
        lappend args $option
    }
    if ![empty_string_p $output_format] {
        set output_file "${output_format}:${output_file}"
    }
    if ![empty_string_p $geometry] {
        lappend args {-geometry} $geometry
    }
    lappend args $input_file
    lappend args $output_file
    eval "exec [convert_path] [join $args]"
}

ad_proc -public ::ImageMagick::tmp_dir {
} {
    Returns the ImageMagick temporary directory (with trailing slash).
} {
    set tmp_dir [parameter::get_from_package_key \
                     -package_key image-magick -parameter TmpDir]
    if { ![regexp {/$} $tmp_dir] } { append tmp_dir / }
    return $tmp_dir
}

ad_proc -public ::ImageMagick::tmp_file {
} {
    Creates a new temporary file name.
    @return The full path to the temporary file location.
} {
    return "[tmp_dir][ns_mktemp imXXXXXX]"
}

ad_proc -public ::ImageMagick::delete_tmp_file {
    filename
} {
    Tests the path is valid and deletes the file.
} {
    set filename [expand_tmp_file $filename]
    if {![validate_tmp_file $filename]} {
        error "$filename is not an ImageMagick tmp file"
    }
    file delete $filename
}

ad_proc -private ::ImageMagick::shorten_tmp_file {
    filename
} {
} {
    set exp "^[tmp_dir](im\[0-9A-Za-z\]{6})$"
    regexp $exp $filename match filename
    return $filename
}

ad_proc -private ::ImageMagick::expand_tmp_file {
    filename
} {
    Returns the full path to the temporary file. If the filename passed is
    is just the filename (without full path), the temporary directory is
    prepended. If its already the full path, its just returned. No validation
    is performed.
} {
    if { ![regexp {^/} $filename] } {
        set filename "[tmp_dir]${filename}"
    }
    return $filename
}

ad_proc -private ::ImageMagick::validate_tmp_file {
    filename
} {
    Checks the given filename is a geniune temporary file.
} {
    set filename [expand_tmp_file $filename]
    set exp "^[tmp_dir]im\[0-9A-Za-z\]{6}$"
    return [regexp $exp $filename]
}

ad_proc -public ::ImageMagick::serve_tmp_file {
    filename
} {
    Serves the given file, having first validated that it is a genuine tmp
    file (and not, say, /etc/passwd). The filename passed in can be either
    the full path to the file, or just the filename in the ImageMagick
    temporary directory.
} {
    set filename [expand_tmp_file $filename]
    if { ![validate_tmp_file $filename] } {
        ad_return_complaint 1 {<li>The specified image name is invalid</li>}
    } else {
        ns_returnfile 200 image/png $filename
    }
}

ad_proc -public ::ImageMagick::identify {
    file
} {
    <p>Identifies attributes of the file specified. This currently supports
    the following attributes:</p>
    <dl>
      <dt>geometry_width<dd>The width of the image, pixels
      <dt>geometry_height<dd>The height of the image, pixels
      <dt>format<dd>The format of the image, eg PNG
      <dt>format_pretty<dd>The pretty format, eg Portable Network Graphics
      <dt>file_size<dd>The size of the file
    </dl>

    @param file The file to identify
    @return An array of attribute-value pairs, as described above.
} {
    set id_str [exec [identify_path] {-verbose} $file]
    if ![regexp \
             {[Gg]eometry: +([0-9]+)x([0-9]+)} \
             $id_str match id(geometry_width) id(geometry_height)] {
                 error {Failed to extract geometry information}
             }
    if ![regexp \
             {[Ff]ormat: ([A-Za-z]+\+?) \((.+)\)} \
             $id_str match id(format) id(format_pretty)] {
                 error {Failed to extract format information}
             }
    set id(file_size) [file size $file]

    return [array get id]
}

namespace eval ::ImageMagick::util {}

ad_proc -public ::ImageMagick::util::create_image_item {
    {-file:required}
    {-revision_id {}}
    {-item_id {}}
    {-parent_id {}}
    {-name {}}
    {-description {}}
    {-user_id {}}
    {-user_ip {}}
    {-relation_tag {none}}
    {-live_p {t}}
    {-mime_type {}}
} {
    Creates a new image item in the content repository.

    @param revision_id Override the ID to use for the image revision
    @param item_id Override the ID to use for the image item
    @param parent_id The ID of the parent object of this image (default null)
    @param name The name of the image revision (defaults to 'image-x' where x is revision ID)
    @param description The description of the image revision
    @param user_id The ID of the creating user (defaults to [ad_conn user_id])
    @param user_ip The IP of the creating user (defaults to [ns_conn peeraddr])
    @param relation_tag The relation tag (? - defaults to 'none')
    @param live_p Whether the revision is set live (in 't', 'f')
    @param mime_type The MIME type of the image (default is to guess)
    @return The image item ID
} {
    foreach var {item_id revision_id} {
        if [empty_string_p [set $var]] {
            set $var [db_nextval acs_object_id_seq]
        }
    }
    if [empty_string_p $user_id] { set user_id [ad_conn user_id] }
    if [empty_string_p $user_ip] { set user_ip [ns_conn peeraddr] }
    if [empty_string_p $name] { set name "image-$revision_id" }

    # process empty string => db_null (no need, I think, but correct to do so)
    foreach var {description parent_id relation_tag} {
        if [empty_string_p [set $var]] {
            set $var [db_null]
        }
    }

    # test file for existence, checking in tmp directory if needed
    if {![file readable $file]} {
        set _file $file
        set file [ImageMagick::expand_tmp_file $file]
        if {![file readable $file]} {
            error "Couldn't open $_file for reading"
        }
    }

    array set id [ImageMagick::identify $file]

    set file_size $id(file_size)
    set width $id(geometry_width)
    set height $id(geometry_height)

    if [empty_string_p $mime_type] {
        # kludgy, but will work for most image formats
        set mime_type "image/[string tolower $id(format)]"
    }

    # create a CR file for the image
    set cr_file [cr_create_content_file \
                     $item_id $revision_id \
                     $file]
    # stick a reference to this file in the DB
    db_exec_plsql create {}

    return $item_id
}

ad_proc -public ::ImageMagick::util::revise_image {
    {-file:required}
    {-item_id:required}
    {-revision_id {}}
    {-name {}}
    {-description {}}
    {-user_id {}}
    {-user_ip {}}
    {-mime_type {}}
    {-live_p {t}}
} {
    Creates a new revision of an image in the content repository. Default
    values are as for create_image.

    @param file The image file to use
    @param item_id The image item to revise
    @param revision_Id Override the revision ID
    @param name The revision name
    @param description The revision description
    @param user_id The ID of the creating user
    @param user_ip The IP of the creating user
    @param mime_type The MIME type of the image
    @param live_p Whether to set the new revision to be the live revision
    @return The new revision ID
} {
    if [empty_string_p $revision_id] {
        set revision_id [db_nextval acs_object_id_seq]
    }
    if [empty_string_p $user_id] { set user_id [ad_conn user_id] }
    if [empty_string_p $user_ip] { set user_ip [ns_conn peeraddr] }
    if [empty_string_p $name] { set name "image-$revision_id" }
    if [empty_string_p $description] { set description [db_null] }

    # test file for existence, checking in tmp directory if needed
    if {![file readable $file]} {
        set _file $file
        set file [ImageMagick::expand_tmp_file $file]
        if {![file readable $file]} {
            error "Couldn't open $_file for reading"
        }
    }

    array set id [ImageMagick::identify $file]

    set file_size $id(file_size)
    set width $id(geometry_width)
    set height $id(geometry_height)

    if [empty_string_p $mime_type] {
        # kludgy, but will work for most image formats
        set mime_type "image/[string tolower $id(format)]"
    }

    # create a CR file for the image
    set cr_file [cr_create_content_file \
                     $item_id $revision_id \
                     $file]

    db_exec_plsql revise {}

    return $revision_id
}

ad_proc -public ImageMagick::util::delete_revision {
    revision_id
} {
    Deletes a CR revision. This is just a thin wrapper for
    content_revision__delete at the DB level.
} {
    db_exec_plsql del {}
}

ad_proc -public ImageMagick::util::delete_item {
    item_id
} {
    Deletes a CR item. This is just a thin wrapper for content_item__delete.
} {
    db_exec_plsql del {}
}
