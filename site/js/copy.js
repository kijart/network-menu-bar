for (const box of document.querySelectorAll(".m-copy-command")) {
  const code = box.querySelector("code");
  const button = box.querySelector("button");
  const status = box.querySelector(".m-copy-command__status");
  let reset;

  const selectCode = () => {
    const range = document.createRange();
    range.selectNodeContents(code);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  };

  const done = (label) => {
    button.textContent = label;
    status.textContent = label;
    clearTimeout(reset);
    reset = setTimeout(() => {
      button.textContent = "Copy";
      status.textContent = "";
    }, 2000);
  };

  button.hidden = false;
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(code.textContent.trim());
      done("Copied");
    } catch {
      selectCode();
      done("Press ⌘C");
    }
  });
}
