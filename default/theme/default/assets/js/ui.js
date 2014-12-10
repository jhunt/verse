$(function () {
	['http', 'https', 'ftp'].forEach(function (x) {
		$('a[href^="'+x+'"]').addClass('ext')
	});
	$('aside:not(.quip)').append('<span class="eot">');

	$('body > header h1').before('<span id="logo"><span>'+
		$('body > header h1').text().substr(0,1)+'</span></span>');

	(function () {
		var current;
		$('body > header li a[data-path]').each(function (i,e) {
			console.log(document.location.pathname);
			if (document.location.pathname.match('^'+$(e).attr('data-path'))) { current = $(e); }
		});
		if (current) { current.addClass('this'); }
	})();

	$('ul.social li').click(function (event) {
		var $li = $(event.target);
		var $article = $li.closest('article');

		var msg = $article.data('teaser');
		if (!msg) { msg = $article.find('> p:first').text(); }

		var url = $article.data('url');
		if (!url) { url = document.location.href; }

		var go;

		if ($li.is('.tw')) {
			var author = $article.data('twitter');
			if (!author) { author = $('meta[name="twitter:site"]').attr('content'); }

			var tail = ' via ' + author;
			var max = 140 - tail.length - 1 - url.length;

			if (msg.length > max) {
				msg = msg.substr(0, max - 3).replace(/[\.,: ]+$/, '') + '...';
			}
			go = "http://twitter.com/share?url="+encodeURIComponent(url)+"&text="+encodeURIComponent(msg)+"&via="+encodeURIComponent(author);

		} else if ($li.is('.fb')) {
			go = "http://www.facebook.com/sharer/sharer.php?u="+encodeURIComponent(url);

		} else if ($li.is('.gg')) {
			go = "http://plus.google.com/share?url="+encodeURIComponent(url);
		}

		if (go) {
			window.open(go, 'verse-site-socialmedia');
		}
	});
});
