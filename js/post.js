function renderMath() {
  const inlineMath = document.querySelectorAll("span.math.inline");
  for (const element of inlineMath) {
    katex.render(element.innerText, element);
  }

  const displayMath = document.querySelectorAll("span.math.display");
  for (const element of displayMath) {
    katex.render(element.innerText, element, {
      displayMode: true
    });
  }

  // renderMathInElement(document.body, {
  //   delimiters: [
  //     { left: "$$", right: "$$", display: true },
  //     { left: "$", right: "$", display: false },
  //     { left: "\\(", right: "\\)", display: false },
  //     { left: "\\[", right: "\\]", display: true }
  //   ]
  // });
}

const codeBlocks = Array.from(document.querySelectorAll("pre code"));
for (const block of codeBlocks) {
  for (const c of block.classList.values()) {
    if (c !== "sourceCode") {
      block.classList.replace(c, `language-${c}`);
    }
  }
}

hljs.highlightAll();

