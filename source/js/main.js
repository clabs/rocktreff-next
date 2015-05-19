$(function(){


	if ( window.skrollr ) {
		skrollr.init({
			smoothScrolling: false,
			mobileDeceleration: 0.004
		})
	}

	$( 'a[href*=#]:not([href=#])' ).click( function () {
		if ( location.pathname.replace(/^\//,'') === this.pathname.replace(/^\//,'') &&
			location.hostname == this.hostname ) {
			var target = $( this.hash )
			target = target.length ? target : $( '#' + this.hash.slice(1) )
			if ( target.length ) {
				$( 'html,body' ).animate({
					scrollTop: target.offset().top
				}, 700)
				return true
			}
		}
	})

	$( '.scrolldown' ).click( function () {
		$( 'html,body' ).animate({
			scrollTop: $( window ).height()
		}, 700)
	})

	$( '.email' ).on( 'click', function () {
		var self = $( this )
		var alias = self.text()
		var domain = self.attr( 'domain' ) || 'rocktreff.de'
		window.location = 'mailto:'+ alias +'@'+ domain
	})

	if ( $.fancybox ) {
		$( '.gallery > a' ).fancybox()
	}


	$( '.nav.visible-xs .glyphicon-menu-hamburger, .nav a' )
		.on( 'click', function () {
			$( '.nav-small' ).toggleClass( 'in' )
		})

})
