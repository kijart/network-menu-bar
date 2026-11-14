const root = document.documentElement;
const button = document.querySelector(".o-header__theme");
const system = window.matchMedia("(prefers-color-scheme: dark)");

const current = () => root.dataset.theme ?? (system.matches ? "dark" : "light");

const render = () => {
  const dark = current() === "dark";
  button.setAttribute("aria-pressed", String(dark));
  for (const meta of document.querySelectorAll('meta[name="theme-color"]')) {
    meta.content = dark ? "#000000" : "#ffffff";
  }
};

button.hidden = false;
render();
system.addEventListener("change", render);
button.addEventListener("click", () => {
  root.dataset.theme = current() === "dark" ? "light" : "dark";
  try {
    localStorage.setItem("theme", root.dataset.theme);
  } catch {}
  render();
});
