/* Load this script using conditional IE comments if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'icomoon\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-untitled' : '&#x61;',
			'icon-untitled-2' : '&#x62;',
			'icon-untitled-3' : '&#x63;',
			'icon-untitled-4' : '&#x64;',
			'icon-untitled-5' : '&#x65;',
			'icon-untitled-6' : '&#x66;',
			'icon-untitled-7' : '&#x67;',
			'icon-settings' : '&#x68;',
			'icon-meter' : '&#x69;',
			'icon-magnifying-glass' : '&#x6a;',
			'icon-search' : '&#x6b;',
			'icon-pin' : '&#x6c;',
			'icon-expand' : '&#x6d;',
			'icon-shrink' : '&#x6e;',
			'icon-arrow-left' : '&#x6f;',
			'icon-arrow-right' : '&#x70;',
			'icon-arrow-down' : '&#x71;',
			'icon-arrow-up' : '&#x72;',
			'icon-share' : '&#x73;',
			'icon-graph' : '&#x74;',
			'icon-search-2' : '&#x75;',
			'icon-search-3' : '&#x76;',
			'icon-home' : '&#x77;',
			'icon-th' : '&#x78;',
			'icon-th-large' : '&#x79;',
			'icon-search-4' : '&#x7a;',
			'icon-out' : '&#x31;',
			'icon-in' : '&#x32;',
			'icon-play' : '&#x33;',
			'icon-pause' : '&#x34;'
		},
		els = document.getElementsByTagName('*'),
		i, attr, html, c, el;
	for (i = 0; ; i += 1) {
		el = els[i];
		if(!el) {
			break;
		}
		attr = el.getAttribute('data-icon');
		if (attr) {
			addIcon(el, attr);
		}
		c = el.className;
		c = c.match(/icon-[^\s'"]+/);
		if (c && icons[c[0]]) {
			addIcon(el, icons[c[0]]);
		}
	}
};