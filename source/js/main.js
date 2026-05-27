document.addEventListener('DOMContentLoaded', () => {

  // Scroll-down arrow button
  document.querySelector('.scrolldown')?.addEventListener('click', () => {
    window.scrollTo({ top: window.innerHeight, behavior: 'smooth' })
  })

  // Email obfuscation — builds mailto from text + data-domain attribute
  document.querySelectorAll('.email').forEach(el => {
    el.addEventListener('click', () => {
      const alias = el.textContent.trim()
      const domain = el.dataset.domain || 'rocktreff.de'
      window.location = `mailto:${alias}@${domain}`
    })
  })

  // Fancybox gallery init (only on pages that load jQuery + fancybox)
  if (typeof jQuery !== 'undefined' && jQuery.fn.fancybox) {
    jQuery('.gallery > a').fancybox()
  }

  // Nav hamburger toggle (mobile)
  const nav = document.querySelector('#navigation')
  const navToggle = document.querySelector('.nav-toggle')
  if (navToggle && nav) {
    navToggle.addEventListener('click', () => {
      const open = nav.classList.toggle('open')
      navToggle.setAttribute('aria-expanded', open)
    })
    nav.querySelectorAll('.nav-links a').forEach(a =>
      a.addEventListener('click', () => {
        nav.classList.remove('open')
        navToggle.setAttribute('aria-expanded', 'false')
      })
    )
  }

  // Map iframe — click to enable scroll, mouseleave to disable
  const mapWrap = document.querySelector('.slide.map .noscroll')
  if (mapWrap) {
    const mapIframe = mapWrap.querySelector('iframe')
    const enableMap = () => {
      mapIframe.style.pointerEvents = 'auto'
      mapWrap.removeEventListener('click', enableMap)
      mapWrap.addEventListener('mouseleave', disableMap)
    }
    const disableMap = () => {
      mapIframe.style.pointerEvents = 'none'
      mapWrap.removeEventListener('mouseleave', disableMap)
      mapWrap.addEventListener('click', enableMap)
    }
    mapWrap.addEventListener('click', enableMap)
  }

  // Nav hide/show on scroll (index page only)
  const bands = document.querySelector('#bands')
  if (nav && bands) {
    const scrolldown = document.querySelector('.scrolldown')
    nav.classList.add('hidden')
    window.addEventListener('scroll', () => {
      if (window.scrollY >= bands.offsetTop - 100) {
        nav.classList.remove('hidden')
      } else if (!nav.classList.contains('hidden')) {
        nav.classList.add('hidden')
      }
      if (scrolldown) {
        scrolldown.classList.toggle('notvisible', window.scrollY >= 10)
      }
    }, { passive: true })
  }

})
