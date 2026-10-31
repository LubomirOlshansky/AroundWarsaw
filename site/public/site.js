// Around Warsaw: the beta and feedback form. Without JavaScript the form still posts to
// Formspree; with it, it checks the fields, sends in place and says how it went.
(function () {
  "use strict";
  var form = document.getElementById("form");
  if (!form || !window.fetch) return;
  var status = document.getElementById("status");
  var email = form.elements.email;
  var message = form.elements.message;
  var subject = document.getElementById("subject");
  var send = form.querySelector(".send");
  var EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  function topic() {
    var t = form.querySelector("input[name=topic]:checked");
    return t ? t.value : "Feedback";
  }
  function wantsInvite() { return topic() === "Beta invite"; }
  function say(text, kind) {
    status.textContent = text || "";
    status.className = "status" + (kind ? " " + kind : "");
  }
  function mark(field, text) {
    var err = document.getElementById(field.id + "-err");
    err.textContent = text || "";
    if (text) field.setAttribute("aria-invalid", "true"); else field.removeAttribute("aria-invalid");
  }
  function check() {
    var ok = true, v = email.value.trim();
    mark(email); mark(message);
    if (wantsInvite() && !v) { mark(email, status.dataset.needEmail); ok = false; }
    else if (v && !EMAIL.test(v)) { mark(email, status.dataset.badEmail); ok = false; }
    if (!wantsInvite() && message.value.trim().length < 2) { mark(message, status.dataset.needMsg); ok = false; }
    return ok;
  }
  form.addEventListener("change", function (e) {
    if (e.target.name === "topic") { subject.value = "Around Warsaw: " + topic(); mark(email); mark(message); }
  });
  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (!check()) { (form.querySelector("[aria-invalid=true]") || email).focus(); return; }
    send.disabled = true;
    say(status.dataset.sending);
    fetch(form.action, { method: "POST", body: new FormData(form), headers: { Accept: "application/json" } })
      .then(function (r) {
        if (!r.ok) throw new Error(String(r.status));
        form.reset();
        subject.value = "Around Warsaw: " + topic();
        say(status.dataset.ok, "ok");
      })
      .catch(function () { say(status.dataset.fail, "bad"); })
      .then(function () { send.disabled = false; });
  });
})();

// The day/night picture: the range input moves the wipe (--p on the stage).
(function () {
  "use strict";
  var stage = document.querySelector(".dn-stage");
  var range = stage && stage.querySelector(".dn-range");
  if (!range) return;
  function move() { stage.style.setProperty("--p", range.value + "%"); }
  range.addEventListener("input", move);
  move();
})();
