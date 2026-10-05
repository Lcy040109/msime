// 演示页的输入区：一个能获得焦点、但不可编辑的元素，文字、光标和行内拼音都由这里自己画。浏览器只对可编辑元素（textarea、input、contenteditable）启用系统输入法，焦点在这里时按键原样到达页面，交给水杉的引擎处理，不会被系统输入法截走。
import { KeyKind, createMsimeEngine, createShiftTap, keyFromEvent, osImeIntercepting, packKey, version } from "./msime/index.js";

const PINYIN = new Set(["quanpin", "xiaohe", "ziranma"]);
const NAMES = { quanpin: "全拼", xiaohe: "小鹤双拼", ziranma: "自然码双拼", wubi86: "五笔 86" };

const editor = document.getElementById("editor");
const before = editor.querySelector(".before");
const preeditSpan = editor.querySelector(".preedit");
const caretSpan = editor.querySelector(".caret");
const after = editor.querySelector(".after");
const wrap = editor.parentElement;
const bar = document.getElementById("candidates");
const barPreedit = bar.querySelector(".cand-preedit");
const barList = bar.querySelector(".cand-list");
const status = document.getElementById("status");
const statusText = document.getElementById("status-text");
const progress = document.getElementById("progress");
const schemeButtons = [...document.querySelectorAll(".schemes button")];

let engine = null;
let scheme = "quanpin";
let text = "";
let caret = 0;
let frame = null;
let pending = 0;
// 放弃组字（点击挪光标、清空、切换方案）时加一，之前发出的请求回来的帧就丢掉。
let generation = 0;
const shift = createShiftTap();

const composing = () => Boolean(frame?.composing);

function setStatus(state, message) {
  status.dataset.state = state;
  statusText.textContent = message;
}

function render() {
  before.textContent = text.slice(0, caret);
  after.textContent = text.slice(caret);
  preeditSpan.textContent = composing() ? frame.preedit : "";
  editor.dataset.empty = String(text === "" && !composing());
  renderCandidates();
}

function renderCandidates() {
  if (!composing() || frame.page.length === 0) {
    bar.hidden = true;
    return;
  }
  barPreedit.textContent = frame.preedit;
  barList.replaceChildren(
    ...frame.page.map((row, i) => {
      const li = document.createElement("li");
      li.dataset.highlight = String(i === frame.highlight);
      const num = document.createElement("span");
      num.className = "num";
      num.textContent = String(i + 1);
      li.append(num, row.text);
      // 编码提示只对五笔这样的形码有用；拼音方案的编码就是整串拼音，桌面版也不显示。
      if (row.code && !PINYIN.has(scheme)) {
        const code = document.createElement("span");
        code.className = "cand-code";
        code.textContent = row.code;
        li.append(code);
      }
      li.addEventListener("mousedown", (e) => e.preventDefault());
      li.addEventListener("click", () => send(() => engine.pick(i)));
      return li;
    }),
  );
  if (frame.hasPrev || frame.hasNext) {
    const pager = document.createElement("li");
    pager.className = "pager";
    pager.textContent = `${frame.hasPrev ? "‹" : " "} ${frame.hasNext ? "›" : " "}`;
    barList.append(pager);
  }
  bar.hidden = false;
  // 候选栏放在光标下方，不超出输入区右边。
  const wrapRect = wrap.getBoundingClientRect();
  const caretRect = caretSpan.getBoundingClientRect();
  const left = Math.max(0, Math.min(caretRect.left - wrapRect.left - 12, wrapRect.width - bar.offsetWidth));
  bar.style.left = `${left}px`;
  bar.style.top = `${caretRect.bottom - wrapRect.top + 8}px`;
}

function insert(value) {
  text = text.slice(0, caret) + value + text.slice(caret);
  caret += value.length;
}

function deleteBack(word) {
  if (caret === 0) return;
  const head = text.slice(0, caret);
  const start = word ? head.replace(/\S+\s*$|\s+$/u, "").length : caret - (Array.from(head).pop()?.length ?? 0);
  text = text.slice(0, start) + text.slice(caret);
  caret = start;
}

function apply(gen, next) {
  if (gen !== generation) return;
  for (const item of next.out) {
    if (item.t === "commit" || item.t === "type") insert(item.text);
    else if (item.t === "back") deleteBack(item.word);
  }
  frame = next;
  render();
}

function send(run) {
  if (!engine) return;
  const gen = generation;
  pending += 1;
  run()
    .then((next) => apply(gen, next))
    .catch((error) => console.error("msime:", error))
    .finally(() => {
      pending -= 1;
    });
}

function abandon() {
  if (!composing() && pending === 0) return;
  generation += 1;
  frame = null;
  engine?.reset().catch(() => {});
  render();
}

editor.addEventListener("keydown", (e) => {
  shift.down(e);
  if (osImeIntercepting(e)) {
    document.getElementById("ime-notice").hidden = false;
    return;
  }
  const busy = composing() || pending > 0;
  // 空闲时的编辑键由页面自己处理：引擎为跟打页面设计，空闲回车不输出换行，也不管光标位置。
  if (!busy && !e.ctrlKey && !e.metaKey && !e.altKey) {
    if (e.key === "Enter") {
      e.preventDefault();
      insert("\n");
      render();
      return;
    }
    if (e.key === "ArrowLeft" || e.key === "ArrowRight") {
      e.preventDefault();
      caret = Math.max(0, Math.min(text.length, caret + (e.key === "ArrowLeft" ? -1 : 1)));
      render();
      return;
    }
    if (e.key === "Home" || e.key === "End") {
      e.preventDefault();
      caret = e.key === "Home" ? 0 : text.length;
      render();
      return;
    }
    if (e.key === "Delete") {
      e.preventDefault();
      text = text.slice(0, caret) + text.slice(caret + 1);
      render();
      return;
    }
    if (e.key === "Escape" || e.key === "ArrowUp" || e.key === "ArrowDown" || e.key === "PageUp" || e.key === "PageDown") return;
  }
  const key = keyFromEvent(e, { composing: busy });
  if (key === null || !engine) return;
  e.preventDefault();
  send(() => engine.keys(key));
});

editor.addEventListener("keyup", (e) => {
  if (shift.up(e)) send(() => engine.keys(packKey(KeyKind.ShiftTap)));
});

// 点击文字把光标放到点击处；正在组字时先放弃。必须在 mousedown 里同步完成：推迟到下一帧的话，点击后立刻打的字会先发出去，再被这里的放弃当成旧请求丢掉。
editor.addEventListener("mousedown", (e) => {
  if (e.button !== 0) return;
  const position = document.caretPositionFromPoint?.(e.clientX, e.clientY);
  const range = position ? null : document.caretRangeFromPoint?.(e.clientX, e.clientY);
  const node = position ? position.offsetNode : range?.startContainer;
  const offset = position ? position.offset : (range?.startOffset ?? 0);
  let index = text.length;
  if (node && before.contains(node)) index = offset;
  else if (node && after.contains(node)) index = caret + offset;
  const wasBusy = composing() || pending > 0;
  abandon();
  index = Math.min(index, text.length);
  // 光标没动也没有放弃组字时不重绘：重建文字节点会打断从这里开始的拖选。
  if (index === caret && !wasBusy) return;
  caret = index;
  render();
});

editor.addEventListener("blur", abandon);

document.getElementById("clear").addEventListener("click", () => {
  abandon();
  text = "";
  caret = 0;
  render();
  editor.focus();
});

function copyButton(button, value) {
  navigator.clipboard?.writeText(value()).then(() => {
    const label = button.textContent;
    button.textContent = "已复制";
    setTimeout(() => (button.textContent = label), 1200);
  });
}

document.getElementById("copy").addEventListener("click", (e) => copyButton(e.currentTarget, () => text));
document.querySelector('[data-copy="snippet"]').addEventListener("click", (e) => copyButton(e.currentTarget, () => document.getElementById("snippet").textContent));

async function load(next) {
  schemeButtons.forEach((b) => (b.disabled = true));
  abandon();
  try {
    if (engine && PINYIN.has(next) && PINYIN.has(scheme)) {
      // 拼音方案之间共用词库，只重建会话，不重新下载。
      await engine.setScheme(next);
      setStatus("ready", `就绪 · ${NAMES[next]}`);
    } else {
      engine?.dispose();
      engine = null;
      progress.dataset.done = "false";
      progress.firstElementChild.style.width = "0";
      setStatus("loading", `正在加载${NAMES[next]}…`);
      const t0 = performance.now();
      engine = await createMsimeEngine({
        scheme: next,
        onProgress: (loaded, total) => {
          const percent = Math.round((loaded / total) * 100);
          progress.firstElementChild.style.width = `${percent}%`;
          setStatus("loading", `正在加载${NAMES[next]} ${percent}%`);
        },
      });
      progress.dataset.done = "true";
      engine.onError((error) => setStatus("error", `引擎出错，请刷新页面：${error.message}`));
      document.getElementById("build").textContent = `@msime/web-engine ${version}`;
      setStatus("ready", `就绪 · ${NAMES[next]} · 用时 ${((performance.now() - t0) / 1000).toFixed(1)} 秒`);
    }
    scheme = next;
  } catch (error) {
    const reason = error.code === "unsupported" ? "这个浏览器不支持 WebAssembly 或 DecompressionStream，请换用新版 Chrome、Edge、Firefox 或 Safari。" : error.message;
    setStatus("error", `加载失败：${reason}`);
  } finally {
    schemeButtons.forEach((b) => {
      b.disabled = false;
      b.setAttribute("aria-checked", String(b.dataset.scheme === scheme));
    });
    if (document.activeElement === document.body || document.activeElement === null) editor.focus();
  }
}

schemeButtons.forEach((button) =>
  button.addEventListener("click", () => {
    if (button.dataset.scheme !== scheme) load(button.dataset.scheme);
    editor.focus();
  }),
);

if (matchMedia("(pointer: coarse)").matches && !matchMedia("(any-pointer: fine)").matches) {
  document.getElementById("touch-notice").hidden = false;
}

render();
editor.focus();
load(scheme);
