// ============================================
// Cribbage Club Landing Page — Main JS
// ============================================

(function () {
  'use strict';

  // --- DOM refs ---
  const navbar = document.getElementById('navbar');
  const navToggle = document.getElementById('nav-toggle');
  const navLinks = document.getElementById('nav-links');
  const modalOverlay = document.getElementById('modal-overlay');
  const modalClose = document.getElementById('modal-close');
  const modalForm = document.getElementById('modal-form');
  const modalEmail = document.getElementById('modal-email');
  const modalSuccess = document.getElementById('modal-success');
  const heroCta = document.getElementById('hero-cta');
  const navCta = document.getElementById('nav-cta');

  // --- Mobile Menu ---
  navToggle.addEventListener('click', function () {
    const isOpen = navLinks.classList.toggle('open');
    navToggle.classList.toggle('open', isOpen);
    navToggle.setAttribute('aria-expanded', isOpen);
  });

  // Close mobile menu on link click
  navLinks.querySelectorAll('a').forEach(function (link) {
    link.addEventListener('click', function () {
      navLinks.classList.remove('open');
      navToggle.classList.remove('open');
      navToggle.setAttribute('aria-expanded', 'false');
    });
  });

  // --- Navbar scroll effect ---
  var lastScroll = 0;
  window.addEventListener('scroll', function () {
    var scrollY = window.scrollY;
    if (scrollY > 50) {
      navbar.classList.add('scrolled');
    } else {
      navbar.classList.remove('scrolled');
    }
    lastScroll = scrollY;
  }, { passive: true });

  // --- Modal ---
  function openModal() {
    modalOverlay.classList.add('active');
    modalEmail.focus();
  }

  function closeModal() {
    modalOverlay.classList.remove('active');
    // Reset form state after transition
    setTimeout(function () {
      modalForm.reset();
      modalForm.hidden = false;
      modalSuccess.hidden = true;
    }, 300);
  }

  heroCta.addEventListener('click', openModal);
  navCta.addEventListener('click', function (e) {
    e.preventDefault();
    openModal();
  });

  modalClose.addEventListener('click', closeModal);

  modalOverlay.addEventListener('click', function (e) {
    if (e.target === modalOverlay) {
      closeModal();
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && modalOverlay.classList.contains('active')) {
      closeModal();
    }
  });

  // --- Form submission ---
  modalForm.addEventListener('submit', function (e) {
    e.preventDefault();
    // Placeholder: In production, POST to an email collection endpoint
    modalForm.hidden = true;
    modalSuccess.hidden = false;
  });

  // --- Scroll reveal ---
  var reveals = document.querySelectorAll('.reveal');

  function checkReveal() {
    var windowHeight = window.innerHeight;
    reveals.forEach(function (el) {
      var top = el.getBoundingClientRect().top;
      if (top < windowHeight - 80) {
        el.classList.add('visible');
      }
    });
  }

  window.addEventListener('scroll', checkReveal, { passive: true });
  window.addEventListener('load', checkReveal);
  // Run once on init in case elements are already in view
  checkReveal();
})();
