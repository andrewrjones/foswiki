
jQuery(document).ready(function () {
    jQuery("li").draggable({revert:true});
    jQuery("li").droppable({
      greedy: true,
      tolerance: 'pointer',
      drop: function(event, ui) { 
    /* assert that child&parent web are the same.. */
    /* only enable d&d if and on topics that the user has change perms to */
	    var childTopic = ui.draggable;
	    var parentTopic = jQuery(this);
	    var childTopicName = ui.draggable.find("a:eq(0)").attr('topic');
	    var parentTopicName = jQuery(this).find("a:eq(0)").attr('topic');
	    var webName = jQuery(this).find("a:eq(0)").attr('web');
	
	    foswiki.post('save' , {
						    web: webName,
						    topic: childTopicName,
						    topicparent: parentTopicName,
						    action_save: 1,
						    forcenewrevision: 1,
						    skin: 'text'
					    })
	    .success(function(data, textStatus) {
				    if (textStatus == 'success') {
					    var inner_ul = parentTopic.find("ul:eq(0)");
					    if (inner_ul.size() == 0) {
						    /* make a ul to add to */
						    parentTopic.append("<ul></ul>");
						    inner_ul = parentTopic.find("ul:eq(0)");
					    }
					    inner_ul.append(childTopic);
				    }
			    })
	    .error(function(data, textStatus) {
					    alert("reparenting of "+webName+"."+childTopicName+" failed, do you have permission to change that topic?");
	    })
	    .complete(function(data, textStatus) {

	    });
      }
    });
});
