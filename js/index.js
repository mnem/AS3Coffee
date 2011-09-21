$(document).ready(function() {
	var flashvars  = {};
	var params     = {};
	var attributes = {};
	var targetDiv  = "flashcontent";

	params.scale = "noscale";
	params.wmode = "opaque";
	params.menu  = "false";

	swfobject.embedSWF("Barista.swf", targetDiv, "512", "512", "10.2.0", false, flashvars, params, attributes);
});
