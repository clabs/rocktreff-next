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

  // Gallery lightbox
  const galleryLinks = document.querySelectorAll('.gallery > a')
  if (galleryLinks.length) {
    const lightbox = document.createElement('dialog')
    lightbox.id = 'lightbox'
    lightbox.innerHTML = '<img id="lightbox-img" alt=""><button id="lightbox-close" aria-label="Schließen">&#x2715;</button>'
    document.body.appendChild(lightbox)
    lightbox.addEventListener('click', e => {
      if (e.target === lightbox || e.target.id === 'lightbox-close' || e.target.id === 'lightbox-img') lightbox.close()
    })
    galleryLinks.forEach(a => {
      a.addEventListener('click', e => {
        e.preventDefault()
        lightbox.querySelector('#lightbox-img').src = a.href
        lightbox.showModal()
      })
    })
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

  // Scrollspy — update URL hash as sections enter viewport
  const spySections = ['slide_landing', 'bands', 'sponsors', 'spielfest', 'helfen', 'veranstalter']
    .map(id => document.getElementById(id))
    .filter(Boolean)
  if (spySections.length) {
    let scrollingToAnchor = false
    nav?.querySelectorAll('.nav-links a').forEach(a =>
      a.addEventListener('click', () => { scrollingToAnchor = true; setTimeout(() => { scrollingToAnchor = false }, 1000) })
    )
    const observer = new IntersectionObserver(entries => {
      if (scrollingToAnchor) return
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          if (entry.target.id === 'slide_landing') {
            history.replaceState(null, '', location.pathname)
          } else {
            history.replaceState(null, '', '#' + entry.target.id)
          }
        }
      })
    }, { threshold: 0.3 })
    spySections.forEach(el => observer.observe(el))
  }

})
