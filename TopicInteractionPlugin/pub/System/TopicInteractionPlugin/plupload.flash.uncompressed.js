/**
 * plupload.flash.js
 *
 * Copyright 2009, Moxiecode Systems AB
 * Released under GPL License.
 *
 * License: http://www.plupload.com/license
 * Contributing: http://www.plupload.com/contributing
 */

// JSLint defined globals
/*global plupload:false, ActiveXObject:false, escape:false */

(function(plupload) {
	var uploadInstances = {};

	function getFlashVersion() {
		var version;

		try {
			version = navigator.plugins['Shockwave Flash'];
			version = version.description;
		} catch (e1) {
			try {
				version = new ActiveXObject('ShockwaveFlash.ShockwaveFlash').GetVariable('$version');
			} catch (e2) {
				version = '0.0';
			}
		}

		version = version.match(/\d+/g);

		return parseFloat(version[0] + '.' + version[1]);
	}

	plupload.flash = {
		/**
		 * Will be executed by the Flash runtime when it sends out events.
		 *
		 * @param {String} id If for the upload instance.
		 * @param {String} name Event name to trigger.
		 * @param {Object} obj Parameters to be passed with event.
		 */
		trigger : function(id, name, obj) {
			// Detach the call so that error handling in the browser is presented correctly
			setTimeout(function() {
				var uploader = uploadInstances[id], i, args;

				if (uploader) {
					uploader.trigger('Flash:' + name, obj);
				}
			}, 0);
		}
	};

	/**
	 * FlashRuntime implementation. This runtime supports these features: jpgresize, pngresize, chunks.
	 *
	 * @static
	 * @class plupload.runtimes.Flash
	 * @extends plupload.Runtime
	 */
	plupload.runtimes.Flash = plupload.addRuntime("flash", {
		/**
		 * Returns a list of supported features for the runtime.
		 *
		 * @return {Object} Name/value object with supported features.
		 */
		getFeatures : function() {
			return {
				jpgresize: true,
				pngresize: true,
				chunks: true,
				progress: true,
				multipart: true
			};
		},

		/**
		 * Initializes the upload runtime. This method should add necessary items to the DOM and register events needed for operation. 
		 *
		 * @method init
		 * @param {plupload.Uploader} uploader Uploader instance that needs to be initialized.
		 * @param {function} callback Callback to execute when the runtime initializes or fails to initialize. If it succeeds an object with a parameter name success will be set to true.
		 */
		init : function(uploader, callback) {
			var browseButton, flashContainer, flashVars, initialized, waitCount = 0, container = document.body;

			if (getFlashVersion() < 10) {
				callback({success : false});
				return;
			}

			uploadInstances[uploader.id] = uploader;

			// Find browse button and set to to be relative
			browseButton = document.getElementById(uploader.settings.browse_button);

			// Create flash container and insert it at an absolute position within the browse button
			flashContainer = document.createElement('div');
			flashContainer.id = uploader.id + '_flash_container';

			plupload.extend(flashContainer.style, {
				position : 'absolute',
				top : '0px',
				background : uploader.settings.shim_bgcolor || 'transparent',
				zIndex : 99999,
				width : '100%',
				height : '100%'
			});

			flashContainer.className = 'plupload flash';

			if (uploader.settings.container) {
				container = document.getElementById(uploader.settings.container);
				container.style.position = 'relative';
			}

			container.appendChild(flashContainer);

			flashVars = 'id=' + escape(uploader.id);

			// Insert the Flash inide the flash container
                        if(1) {
                          flashContainer.innerHTML = '<object id="' + uploader.id + '_flash" width="100%" height="100%" style="outline:0" type="application/x-shockwave-flash" data="' + uploader.settings.flash_swf_url + '">' +
				'<param name="movie" value="' + uploader.settings.flash_swf_url + '" />' +
				'<param name="flashvars" value="' + flashVars + '" />' +
				'<param name="wmode" value="transparent" />' +
                                '<param name="allownetworking" value="all" />' +
				'<param name="allowscriptaccess" value="always" /></object>';
                        } else {
                          flashContainer.innerHTML = '<embed id="' + 
                            uploader.id + 
                            '_flash" width="100%" height="100%" style="outline:0" type="application/x-shockwave-flash" src="'+ 
                            uploader.settings.flash_swf_url +'" menu="false" wmode="transparent" flashvars="'+ 
                            flashVars+'" allownetworking="all" allowscriptaccess="always" />';
                        }

			function getFlashObj() {
				return document.getElementById(uploader.id + '_flash');
			}

			function waitLoad() {
				// Wait for 5 sec
				if (waitCount++ > 5000) {
					callback({success : false});
					return;
				}

				if (!initialized) {
					setTimeout(waitLoad, 1);
				}
			}

			waitLoad();

			// Fix IE memory leaks
			browseButton = flashContainer = null;

			// Wait for Flash to send init event
			uploader.bind("Flash:Init", function() {
				var lookup = {}, i, resize = uploader.settings.resize || {};

				initialized = true;
				var fo = getFlashObj();
                                if (!fo) {
                                  return;
                                }

                                if (typeof(fo.setFileFilters) === 'function') { // isn't there yet sometimes
                                  fo.setFileFilters(uploader.settings.filters, uploader.settings.multi_selection);
                                }

                                // don't create the same bindings again
                                if (!uploader._isInited) {
                                  uploader._isInited = true;
                                  uploader.bind("UploadFile", function(up, file) {
                                          var settings = up.settings;

                                          var fo = getFlashObj();
                                          if (!fo) {
                                            return;
                                          }
                                          fo.uploadFile(lookup[file.id], settings.url, {
                                                  name : file.target_name || file.name,
                                                  mime : plupload.mimeTypes[file.name.replace(/^.+\.([^.]+)/, '$1')] || 'application/octet-stream',
                                                  chunk_size : settings.chunk_size,
                                                  width : resize.width,
                                                  height : resize.height,
                                                  quality : resize.quality || 90,
                                                  multipart : settings.multipart,
                                                  multipart_params : settings.multipart_params || {},
                                                  file_data_name : settings.file_data_name,
                                                  format : /\.(jpg|jpeg)$/i.test(file.name) ? 'jpg' : 'png',
                                                  headers : settings.headers,
                                                  urlstream_upload : settings.urlstream_upload
                                          });
                                  });

                                  uploader.bind("Flash:UploadProcess", function(up, flash_file) {
                                          var file = up.getFile(lookup[flash_file.id]);

                                          if (file.status != plupload.FAILED) {
                                                  file.loaded = flash_file.loaded;
                                                  file.size = flash_file.size;

                                                  up.trigger('UploadProgress', file);
                                          }
                                  });

                                  uploader.bind("Flash:UploadChunkComplete", function(up, info) {
                                          var chunkArgs, file = up.getFile(lookup[info.id]);

                                          chunkArgs = {
                                                  chunk : info.chunk,
                                                  chunks : info.chunks,
                                                  response : info.text
                                          };

                                          up.trigger('ChunkUploaded', file, chunkArgs);

                                          // Stop upload if file is maked as failed
                                          if (file.status != plupload.FAILED) {
                                                  var fo = getFlashObj();
                                                  if (fo) {
                                                    fo.uploadNextChunk();
                                                  }
                                          }

                                          // Last chunk then dispatch FileUploaded event
                                          if (info.chunk == info.chunks - 1) {
                                                  file.status = plupload.DONE;

                                                  up.trigger('FileUploaded', file, {
                                                          response : info.text
                                                  });
                                          }
                                  });

                                  uploader.bind("Flash:SelectFiles", function(up, selected_files) {
                                          var file, i, files = [], id;

                                          // Add the selected files to the file queue
                                          for (i = 0; i < selected_files.length; i++) {
                                                  file = selected_files[i];

                                                  // Store away flash ref internally
                                                  id = plupload.guid();
                                                  lookup[id] = file.id;
                                                  lookup[file.id] = id;
                                                  files.push(new plupload.File(id, file.name, file.size));
                                          }

                                          // Trigger FilesAdded event if we added any
                                          if (files.length) {
                                                  uploader.trigger("FilesAdded", files);
                                          }
                                  });

                                  uploader.bind("Flash:SecurityError", function(up, err) {
                                          uploader.trigger('Error', {
                                                  code : plupload.SECURITY_ERROR,
                                                  message : 'Security error.',
                                                  details : err.message,
                                                  file : uploader.getFile(lookup[err.id])
                                          });
                                  });

                                  uploader.bind("Flash:GenericError", function(up, err) {
                                          uploader.trigger('Error', {
                                                  code : plupload.GENERIC_ERROR,
                                                  message : 'Generic error.',
                                                  details : err.message,
                                                  file : uploader.getFile(lookup[err.id])
                                          });
                                  });

                                  uploader.bind("Flash:IOError", function(up, err) {
                                          uploader.trigger('Error', {
                                                  code : plupload.IO_ERROR,
                                                  message : 'IO error.',
                                                  details : err.message,
                                                  file : uploader.getFile(lookup[err.id])
                                          });
                                  });

                                  uploader.bind("QueueChanged", function(up) {
                                          uploader.refresh();
                                  });

                                  uploader.bind("FilesRemoved", function(up, files) {
                                          var i;

                                          var fo = getFlashObj();
                                          if (!fo) {
                                            return;
                                          }
                                          for (i = 0; i < files.length; i++) {
                                                  fo.removeFile(lookup[files[i].id]);
                                          }
                                  });

                                  uploader.bind("StateChanged", function(up) {
                                          uploader.refresh();
                                  });

                                  uploader.bind("Refresh", function(up) {
                                          var browseButton, browsePos, browseSize;

                                          // Set file filters incase it has been changed dynamically
                                          var fo = getFlashObj();
                                          if (!fo) {
                                            return;
                                          }

                                          if (typeof(fo.setFileFilters) === 'function') { // isn't there yet sometimes
                                            fo.setFileFilters(uploader.settings.filters, uploader.settings.multi_selection);
                                          }

                                          browseButton = document.getElementById(up.settings.browse_button);
                                          browsePos = plupload.getPos(browseButton, document.getElementById(up.settings.container));
                                          browseSize = plupload.getSize(browseButton);

                                          plupload.extend(document.getElementById(up.id + '_flash_container').style, {
                                                  top : browsePos.y + 'px',
                                                  left : browsePos.x + 'px',
                                                  width : browseSize.w + 'px',
                                                  height : browseSize.h + 'px'
                                          });
                                  });
                                }

				callback({success : true});
			});
		}
	});
})(plupload);