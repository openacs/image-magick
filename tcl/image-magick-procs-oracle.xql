<!--
 -  This is free software distributed under the terms of the GNU General Public
 -  License.  Full text of the license is available from the GNU Project:
 -  http://www.fsf.org/copyleft/gpl.html
-->

<queryset>
  <rdbms><type>oracle</type><version></version></rdbms>

<fullquery name="ImageMagick::util::create_image_item.create">
  <querytext>
  
	begin
	  :1 := image.new (
		  name => :name,
		  parent_id => :parent_id,
		  item_id => :item_id,
		  revision_id => :revision_id,
		  creation_user => :user_id,
		  creation_ip => :user_ip,
		  title => :name,
		  description => :description,
		  mime_type => :mime_type,
		  relation_tag => :relation_tag,
		  is_live => :live_p,
		  filename => :cr_file,
		  height => :height,
		  width => :width,
		  file_size => :file_size
		);
	end;

  </querytext>
</fullquery>

<fullquery name="ImageMagick::util::revise_image.revise">
  <querytext>

	begin
	  :1 := image.new_revision (
		  item_id => :item_id,
		  revision_id => :revision_id,
		  creation_user => :user_id,
		  creation_ip => :user_ip,
		  title => :name,
		  description => :description,
		  mime_type => :mime_type,
		  is_live => :live_p,
		  filename => :cr_file,
		  height => :height,
		  width => :width,
		  file_size => :file_size
		);
	end;

  </querytext>
</fullquery>

<fullquery name="ImageMagick::util::delete_revision.del">
  <querytext>
	
	begin
	  content_revision.del (:revision_id);
	end;

  </querytext>
</fullquery>

<fullquery name="ImageMagick::util::delete_item.del">
  <querytext>
	
	begin
	  content_item.del (:item_id);
	end;

  </querytext>
</fullquery>

</queryset>
