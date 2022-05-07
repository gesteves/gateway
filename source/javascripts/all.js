'use strict';

var GTWY = GTWY || {};

GTWY.Nav = (function () {
  const opts = {
    navId          : 'nav',
    buttonId       : 'nav-button',
    openText       : 'Open menu',
    closeText      : 'Close menu',
    openClass      : 'nav--is-open'
  };

  const toggleMenu = function () {
    const nav = document.getElementById(opts.navId);
    const button = document.getElementById(opts.buttonId);

    nav.classList.toggle(opts.openClass);

    if (button.ariaExpanded === 'true') {
      button.ariaExpanded = 'false';
      button.innerHTML = opts.openText;
    } else {
      button.ariaExpanded = 'true';
      button.innerHTML = opts.closeText;
    }
  };

  var init = function () {
    const button = document.getElementById(opts.buttonId);
    button.addEventListener('click', toggleMenu);
  };

  return {
    init : init
  };
})();

GTWY.Nav.init();
