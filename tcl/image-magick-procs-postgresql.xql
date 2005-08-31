<!--
 -  This is free software distributed under the terms of the GNU General Public
 -  License.  Full text of the license is available from the GNU Project:
 -  http://www.fsf.org/copyleft/gpl.html
-->

<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="ImageMagick::util::create_image_item.create"><querytext>
BEGIN
    PERFORM image__new (
        :name,            -- name
        :parent_id,       -- parent_id
        :item_id,         -- item_id
        :revision_id,     -- revision_id
        :mime_type,       -- MIME
        :user_id,         -- user ID
        :user_ip,         -- user IP
        :relation_tag,    -- relation tag (?)
        :name,            -- title
        :description,     -- description
        :live_p,          -- is live?
        current_timestamp,-- publish time
        :cr_file,         -- path
        :file_size,       -- file size
        :height,          -- height
        :width            -- width
    );

    RETURN null;
END;
</querytext></fullquery>

<fullquery name="ImageMagick::util::revise_image.revise"><querytext>
BEGIN
    PERFORM content_revision__new (
        :name,             -- title
        :description,      -- description
        current_timestamp, -- publish date
        :mime_type,        -- MIME type
        null,              -- language
        null,              -- data
        :item_id,          -- item ID
        :revision_id,      -- revision ID
        current_timestamp, -- creation date
        :user_id,          -- creation user
        :user_ip           -- creation IP
    );

    INSERT INTO images
        (image_id, height, width)
    VALUES
        (:revision_id, :height, :width);

    UPDATE cr_revisions SET
        content_length = :file_size,
        content = :cr_file
    WHERE revision_id = :revision_id;

    IF :live_p = 't' THEN
        PERFORM content_item__set_live_revision( :revision_id );
    END IF;

    RETURN null;
END;
</querytext></fullquery>

<fullquery name="ImageMagick::util::delete_revision.del"><querytext>
BEGIN
    PERFORM content_revision__delete(:revision_id);
    RETURN null;
END;
</querytext></fullquery>

<fullquery name="ImageMagick::util::delete_item.del"><querytext>
BEGIN
    PERFORM content_item__delete(:item_id);
    RETURN null;
END;
</querytext></fullquery>

</queryset>
