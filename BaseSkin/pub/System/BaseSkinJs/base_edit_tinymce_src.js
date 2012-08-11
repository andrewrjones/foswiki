var foswiki;
if (!foswiki) {
	foswiki = {};
}
if (!foswiki.base) {
	foswiki.base = {};
}
if (!foswiki.base.edit) {
	foswiki.base.edit = {};
}
var FoswikiTiny,
	tinymce;

foswiki.base.edit.tinymce = (function ($) {

	"use strict";

	var SELECTOR_WYSIWYG_TEXTAREA = 'textarea.foswikiWysiwygEdit',
		SELECTOR_TEXTAREA_CONTAINER = '.foswikiEditTextarea',
		CSS_CLASS_HAS_WYSIWYG = 'foswikiHasWysiwyg';
	
	return {

		/**
		Called from TinyMCEPlugin init, defined in FoswikiTiny.init ("init_instance_callback").
		*/
		tinyMceInited: function () {

			if (!FoswikiTiny || !FoswikiTiny.init) {
				return;
			}

			if (!$(SELECTOR_WYSIWYG_TEXTAREA).length) {
				return;
			}
			
			var $toolbar,
				$container,
				classes = [],
				skin,
				skinVariant;

			$toolbar = jQuery('#topic_toolbargroup');
			if ($toolbar.length === 0) {
				return;
			}

			$container = jQuery('#foswikiEditControlsContainer');
			if ($container.length === 0) {
				return;
			}

			// grab the current class name to set it to the new container
			classes = [];
			skin = FoswikiTiny.init.skin || 'default';
			classes.push(skin + 'Skin');

			if (FoswikiTiny.init.skin_variant) {
				skinVariant = FoswikiTiny.init.skin_variant.charAt(0).toUpperCase() + FoswikiTiny.init.skin_variant.slice(1);
				classes.push(skin + 'Skin' + skinVariant);
			}
			$toolbar.addClass(classes.join(' '));

			// move toolbar to our container
			$toolbar.appendTo($container);

			// remove original toolbar table cells
			jQuery('#topic_tbl .mceToolbar').remove();
		},

		fitToContent: function (elem, minAreaHeight) {
			var SAFE_PADDING,
				adjustedHeight,
				elemMinHeight,
				nowysiwyg;
				
			if (!elem) {
				return;
			}

			SAFE_PADDING = 15;
			elemMinHeight = document.documentElement.clientHeight - minAreaHeight;
			nowysiwyg = parseInt(jQuery('form[name=main] [name="nowysiwyg"]').val(), 10);

			if (jQuery('body.' + CSS_CLASS_HAS_WYSIWYG).length > 0) {
				// we use the autoresize plugin from TineMCE,
				// so don't continue with our own resizing
				return;
			}

			// Account for deleted lines
			if (elem.clientHeight <= elem.scrollHeight) {
				elem.style.height = elemMinHeight + 'px';
			}

			adjustedHeight = Math.max(elem.scrollHeight, elem.clientHeight) + SAFE_PADDING;
			if (adjustedHeight > elem.clientHeight) {
				elem.style.height = adjustedHeight + 'px';
			}
		},

		/**
		Sets up the fit to content calls for the raw editor.
		*/
		initRaw: function () {
			var nowysiwyg,
				$textarea,
				$textareaContainer,
				that = this;

			nowysiwyg = parseInt(jQuery('form[name=main] [name="nowysiwyg"]').val(), 10);
			$textareaContainer = jQuery(SELECTOR_TEXTAREA_CONTAINER);
			$textarea = jQuery(SELECTOR_WYSIWYG_TEXTAREA, $textareaContainer);
			that = this;

			if ($textarea.length && nowysiwyg !== 1) {
				jQuery('body').addClass(CSS_CLASS_HAS_WYSIWYG);
			}

			$textarea.livequery(function () {
				that.fitTextArea();
			}).livequery('focus blur keyup paste change', function () {
				that.fitTextArea();
			});
		},

		fitTextArea: function () {
			var FOOTER_HEIGHT,
				MIN_AREA_HEIGHT,
				$textarea,
				$textareaContainer;
			
			$textareaContainer = jQuery(SELECTOR_TEXTAREA_CONTAINER);
			if (!$textareaContainer.length) {
				return;
			}
			
			FOOTER_HEIGHT = jQuery('.foswikiFooter').outerHeight();
			MIN_AREA_HEIGHT = $textareaContainer.position().top + FOOTER_HEIGHT;
			$textarea = jQuery(SELECTOR_WYSIWYG_TEXTAREA, $textareaContainer);
			this.fitToContent($textarea[0], MIN_AREA_HEIGHT);
		},
		
		updateUI: function () {
			var ed = tinymce.activeEditor,
				that = this;
				
		    setTimeout(function() {
		    	ed.hide();
		    }, 1);
    		setTimeout(function() {
    			ed.show();
    			that.fitTextArea();
    		}, 10);
		}
		
	};

}(jQuery));

function tinyMceInited() {
	"use strict";
	foswiki.base.edit.tinyMceInited();
}

function onTextAreaChanged() {
	"use strict";
	foswiki.base.edit.fitTextArea();
}

if (FoswikiTiny !== undefined) {

	/**
	Ideally, init_instance_callback is set in FoswikiTiny.init.
	In case it's not, we set it here.
	*/
	if (!FoswikiTiny.init.init_instance_callback && !tinymce.settings.init_instance_callback) {
		tinymce.settings.init_instance_callback = tinyMceInited;
	}

	// register callback to notify us when the text editor has changed
	FoswikiTiny.transformCbs.push(onTextAreaChanged);
}

jQuery(document).ready(function ($) {
	"use strict";
	foswiki.base.edit.initRaw();
	
	$(foswiki.base).bind('update', function(e) {
		foswiki.base.edit.updateUI();
	});
});


