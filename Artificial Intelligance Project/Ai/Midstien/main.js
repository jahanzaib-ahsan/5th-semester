// Main single-page wizard logic for the OCR + maths solver
console.log("[BUILD] main.js version v3 loaded at", new Date().toISOString());

// --- Simple app state ------------------------------------------------------

const state = {
  imageSelected: false,
  imageFile: null,
  rawOcr: "",
  cleanedOcr: "",
  isMathQuestion: null,
  approvedQuestion: "",
};

// --- DOM references --------------------------------------------------------

const timelineItems = document.querySelectorAll(".wizard-timeline li");

const step1 = document.getElementById("step-1");
const step2 = document.getElementById("step-2");
const step3 = document.getElementById("step-3");
const step4 = document.getElementById("step-4");

const imageInput = document.getElementById("imageInput");
const uploadPreview = document.getElementById("uploadPreview");
const uploadPlaceholder = document.getElementById("uploadPlaceholder");
const uploadedImage = document.getElementById("uploadedImage");
const step1Next = document.getElementById("step1Next");

const rawOcrElement = document.getElementById("rawOcr");
const cleanOcrElement = document.getElementById("cleanOcr");
const isMathBadge = document.getElementById("isMathBadge");
const mathMessage = document.getElementById("mathMessage");
const step2Back = document.getElementById("step2Back");
const step2Next = document.getElementById("step2Next");

const confirmedQuestion = document.getElementById("confirmedQuestion");
const approveQuestionButton = document.getElementById("approveQuestion");
const approvalMessage = document.getElementById("approvalMessage");
const step3Back = document.getElementById("step3Back");
const step3Next = document.getElementById("step3Next");

const finalQuestion = document.getElementById("finalQuestion");
const solveButton = document.getElementById("solveButton");
const apiStatus = document.getElementById("apiStatus");
const solutionCard = document.getElementById("solutionCard");
const solutionModelChip = document.getElementById("solutionModelChip");
const cardProblem = document.getElementById("cardProblem");
const cardReasoning = document.getElementById("cardReasoning");
const cardSteps = document.getElementById("cardSteps");
const cardFinalLatex = document.getElementById("cardFinalLatex");
const cardFinalPlain = document.getElementById("cardFinalPlain");
const cardVerification = document.getElementById("cardVerification");
const step4Back = document.getElementById("step4Back");

// --- Helper: step navigation ----------------------------------------------

function setActiveStep(stepNumber) {
  const steps = [step1, step2, step3, step4];
  steps.forEach((el, index) => {
    if (!el) return;
    el.classList.toggle("wizard-step-active", index + 1 === stepNumber);
  });

  timelineItems.forEach((item) => {
    const itemStep = Number(item.getAttribute("data-step"));
    item.classList.toggle("active", itemStep === stepNumber);
  });
}

// --- Simulated backend client (UI is model-agnostic) ----------------------

/**
 * API key handling:
 * - For a production system, call your own backend which talks to Gemini
 *   using a server-side environment variable.
 * - For a pure front-end academic demo, you can inject the key at build
 *   time or manually replace the placeholder string below.
 */
const GEMINI_API_KEY_PLACEHOLDER = "${GEMINI_API_KEY}";

function getGeminiApiKey() {
  if (typeof window !== "undefined" && window.GEMINI_API_KEY_OVERRIDE) {
    return window.GEMINI_API_KEY_OVERRIDE;
  }
  if (
    GEMINI_API_KEY_PLACEHOLDER &&
    !GEMINI_API_KEY_PLACEHOLDER.includes("${")
  ) {
    return GEMINI_API_KEY_PLACEHOLDER;
  }
  return "";
}

function simulateSolve(questionText) {
  return new Promise((resolve) => {
    setTimeout(() => {
      const equationPart = extractEquationFromQuestion(questionText);
      const parsed = parseLinearEquation(equationPart);

      if (!parsed) {
        resolve({
          steps: [
            `Received question: ${questionText}`,
            "This demo solver currently supports linear equations of the form ax + b = c with one variable x.",
            "The provided expression does not match this pattern, so a numeric solution is not generated.",
          ],
          finalAnswer:
            "No numeric solution generated (unsupported equation format for this demo).",
        });
        return;
      }

      const { a, b, c, x } = parsed;
      const rhsAfterSubtraction = c - b;

      const steps = [];
      const signForB = b >= 0 ? "+" : "-";
      const absB = Math.abs(b);
      const prettyEquation =
        b === 0 ? `${a}x = ${c}` : `${a}x ${signForB} ${absB} = ${c}`;

      steps.push(`Start from the normalised equation: ${prettyEquation}.`);

      if (b !== 0) {
        steps.push(
          `Subtract ${b} from both sides: ${a}x ${signForB} ${absB} − ${b} = ${c} − ${b}, which simplifies to ${a}x = ${rhsAfterSubtraction}.`,
        );
      }

      steps.push(
        `Divide both sides by ${a} to isolate x: (${a}x) / ${a} = ${rhsAfterSubtraction} / ${a}, giving x = ${x}.`,
      );
      steps.push(
        `Therefore, the value of x that satisfies the equation is ${x}.`,
      );

      const finalAnswer = Number.isInteger(x)
        ? `Final answer: x = ${x}`
        : `Final answer: x = ${x} (approximately)`;

      resolve({ steps, finalAnswer });
    }, 500);
  });
}

// Small parsing helpers reused from the earlier step module.
function extractEquationFromQuestion(questionText) {
  const trimmed = questionText.trim();
  const colonIndex = trimmed.indexOf(":");
  if (colonIndex === -1) {
    return trimmed;
  }
  return trimmed.slice(colonIndex + 1).trim();
}

function parseLinearEquation(equation) {
  const compact = equation.replace(/\s+/g, "");
  const match = compact.match(
    /^([+-]?\d*\.?\d*)x([+-]\d*\.?\d*)?=([+-]?\d*\.?\d*)$/,
  );

  if (!match) {
    return null;
  }

  const aRaw = match[1];
  const bRaw = match[2] || "+0";
  const cRaw = match[3];

  function parseCoefficient(raw, defaultMagnitude) {
    if (raw === "" || raw === "+") return defaultMagnitude;
    if (raw === "-") return -defaultMagnitude;
    const value = parseFloat(raw);
    return Number.isFinite(value) ? value : defaultMagnitude;
  }

  const a = parseCoefficient(aRaw, 1);
  const b = parseFloat(bRaw);
  const c = parseFloat(cRaw);

  if (!Number.isFinite(a) || !Number.isFinite(b) || !Number.isFinite(c)) {
    return null;
  }
  if (a === 0) {
    return null;
  }

  const xRaw = (c - b) / a;
  const x = Number.isInteger(xRaw) ? xRaw : parseFloat(xRaw.toFixed(3));

  return { a, b, c, x };
}

// --- OCR helpers ----------------------------------------------------------

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () =>
      reject(reader.error || new Error("Failed to read file"));
    reader.readAsDataURL(file);
  });
}

function classifyTextAsMath(text) {
  const t = String(text || "").trim();
  const hasDigits = /\d/.test(t);
  const hasMathSymbol = /[+\-*/×÷^=]/.test(t);
  const hasLatexDelimiters = /(\$[^$]*\$)|\\\(|\\\)|\\\[|\\\]/.test(t);
  const hasLatexCommand =
    /\\(frac|sqrt|sum|int|log|sin|cos|tan|pi|theta|alpha|beta|gamma|cdot|times|le|ge|neq|pm|infty)/i.test(
      t,
    );
  const hasCue = /(solve|evaluate|simplify|find|compute|derive)/i.test(t);

  const classified =
    hasLatexDelimiters ||
    hasLatexCommand ||
    (hasMathSymbol && hasDigits) ||
    (hasCue && (hasDigits || hasMathSymbol || hasLatexCommand));

  console.log("[OCR] classifyTextAsMath", {
    hasDigits,
    hasMathSymbol,
    hasLatexDelimiters,
    hasLatexCommand,
    hasCue,
    classified,
  });
  return classified;
}

function normalizeOcrText(text) {
  let s = String(text || "")
    .replace(/\s+/g, " ")
    .trim();
  if (s.startsWith("$") && s.endsWith("$")) {
    s = s.slice(1, -1).trim();
  }
  if (s.startsWith("\\(") && s.endsWith("\\)")) {
    s = s.slice(2, -2).trim();
  }
  if (s.startsWith("\\[") && s.endsWith("\\]")) {
    s = s.slice(2, -2).trim();
  }
  return s;
}

async function callGeminiOcr(imageFile) {
  const apiKey = getGeminiApiKey();
  if (!apiKey) {
    throw new Error(
      "GEMINI_API_KEY is not configured in the front-end environment",
    );
  }

  console.log("[OCR] Starting Gemini OCR call", {
    hasApiKey: Boolean(apiKey),
    fileName: imageFile.name,
    fileType: imageFile.type,
    fileSizeBytes: imageFile.size,
  });

  const dataUrl = await fileToBase64(imageFile);
  const base64Data = dataUrl.split(",")[1] || dataUrl;
  const mimeType = imageFile.type || "image/png";

  const prompt =
    "You are an OCR assistant for mathematics questions. " +
    "Look at the image and return only the full text of the maths question that should be solved. " +
    "Do not add any explanation or extra words.";

  const endpoints = [
    // Stable v1 models
    "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=" +
      encodeURIComponent(apiKey),
    // Latest alias often available
    "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash-latest:generateContent?key=" +
      encodeURIComponent(apiKey),
    // Beta fallback (some keys/projects expose beta only)
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" +
      encodeURIComponent(apiKey),
    // Vision-focused older model fallback
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=" +
      encodeURIComponent(apiKey),
  ];

  let lastErrorText = "";
  for (const url of endpoints) {
    console.log("[OCR] Trying endpoint", url);
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType,
                  data: base64Data,
                },
              },
            ],
          },
        ],
      }),
    });

    console.log("[OCR] Endpoint status", response.status, response.statusText);
    if (response.ok) {
      const result = await response.json();
      console.log("[OCR] Gemini raw JSON", result);
      const parts = result.candidates?.[0]?.content?.parts || [];
      const text = parts
        .map((p) => (typeof p.text === "string" ? p.text : ""))
        .join("\n")
        .trim();

      const cleaned = normalizeOcrText(text);
      const isMathQuestion = classifyTextAsMath(cleaned);

      console.log("[OCR] Parsed output", {
        rawOcr: text,
        cleanedOcr: cleaned,
        isMathQuestion,
      });
      return { rawOcr: text, cleanedOcr: cleaned, isMathQuestion };
    } else {
      const errorText = await response.text();
      lastErrorText = errorText;
      console.warn("[OCR] Endpoint failed", url, errorText);
    }
  }

  // If all predefined endpoints failed, fetch available models and try dynamically
  try {
    const listResp = await fetch(
      "https://generativelanguage.googleapis.com/v1/models?key=" +
        encodeURIComponent(apiKey),
    );
    const listJson = await listResp.json();
    console.log("[OCR] Available models for this key", listJson);

    const models = Array.isArray(listJson.models) ? listJson.models : [];
    // Prefer flash variants first, then pro-vision
    const sorted = models.sort((a, b) => {
      const an = String(a.name || "");
      const bn = String(b.name || "");
      const aw = an.includes("flash") ? 0 : an.includes("vision") ? 1 : 2;
      const bw = bn.includes("flash") ? 0 : bn.includes("vision") ? 1 : 2;
      return aw - bw;
    });

    for (const m of sorted) {
      const modelName = m.name; // e.g., "models/gemini-1.5-flash-001"
      if (!modelName) continue;
      const url =
        "https://generativelanguage.googleapis.com/v1/" +
        modelName +
        ":generateContent?key=" +
        encodeURIComponent(apiKey);
      console.log("[OCR] Trying dynamic model endpoint", url);

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: prompt },
                { inlineData: { mimeType, data: base64Data } },
              ],
            },
          ],
        }),
      });

      console.log(
        "[OCR] Dynamic model status",
        response.status,
        response.statusText,
      );
      if (response.ok) {
        const result = await response.json();
        console.log("[OCR] Dynamic model raw JSON", result);
        const parts = result.candidates?.[0]?.content?.parts || [];
        const text = parts
          .map((p) => (typeof p.text === "string" ? p.text : ""))
          .join("\n")
          .trim();
        const cleaned = normalizeOcrText(text);
        const isMathQuestion = classifyTextAsMath(cleaned);
        console.log("[OCR] Parsed output (dynamic)", {
          rawOcr: text,
          cleanedOcr: cleaned,
          isMathQuestion,
          modelName,
        });
        return { rawOcr: text, cleanedOcr: cleaned, isMathQuestion };
      } else {
        const errorText = await response.text();
        console.warn("[OCR] Dynamic model failed", modelName, errorText);
        lastErrorText = errorText;
      }
    }
  } catch (e) {
    console.warn("[OCR] ListModels or dynamic attempts failed", e);
  }

  throw new Error(
    "Gemini OCR call failed after trying multiple endpoints: " + lastErrorText,
  );
  // (Removed single-endpoint parsing block; handled within loop above.)
}

async function performOcr(imageFile) {
  const apiKey = getGeminiApiKey();
  console.log("[OCR] performOcr: hasApiKey", Boolean(apiKey));
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not configured for OCR.");
  }
  return await callGeminiOcr(imageFile);
}

// --- Step 1: image input ---------------------------------------------------

imageInput.addEventListener("change", (event) => {
  const file = event.target.files && event.target.files[0];
  if (!file) {
    state.imageSelected = false;
    state.imageFile = null;
    uploadedImage.style.display = "none";
    uploadPlaceholder.style.display = "inline";
    step1Next.disabled = true;
    return;
  }

  const reader = new FileReader();
  reader.onload = (e) => {
    const url = String(e.target?.result || "");
    uploadedImage.src = url;
    uploadedImage.style.display = "block";
    uploadPlaceholder.style.display = "none";
    state.imageSelected = true;
    state.imageFile = file;
    step1Next.disabled = false;
  };
  reader.readAsDataURL(file);
});

step1Next.addEventListener("click", async () => {
  if (!state.imageSelected) return;

  console.log("[UI] Step 1 Next clicked", {
    imageSelected: state.imageSelected,
    hasImageFile: Boolean(state.imageFile),
  });

  const overlay = document.getElementById("processingOverlay");
  if (overlay) {
    overlay.classList.add("visible");
    overlay.setAttribute("aria-hidden", "false");
  }

  step1Next.disabled = true;
  step1Next.textContent = "Running OCR...";

  try {
    const file = state.imageFile;
    if (!file) {
      throw new Error("No image file available for OCR");
    }

    console.log("[UI] Calling performOcr with file", {
      name: file.name,
      type: file.type,
      size: file.size,
    });

    const result = await performOcr(file);

    console.log("[UI] OCR result received", result);

    state.rawOcr = result.rawOcr;
    state.cleanedOcr = result.cleanedOcr;
    state.isMathQuestion = result.isMathQuestion;

    rawOcrElement.textContent = state.rawOcr;
    cleanOcrElement.textContent = state.cleanedOcr;

    if (state.isMathQuestion) {
      isMathBadge.textContent = "Yes, maths detected";
      isMathBadge.classList.remove("badge-muted", "badge-danger");
      isMathBadge.classList.add("badge-success");
      mathMessage.textContent =
        "The system believes this is a maths question. You can continue to confirmation.";
      step2Next.disabled = false;
    } else {
      isMathBadge.textContent = "Not a maths question";
      isMathBadge.classList.remove("badge-muted", "badge-success");
      isMathBadge.classList.add("badge-danger");
      mathMessage.textContent =
        "The system does not classify this as a maths problem. You may want to recheck the input.";
      step2Next.disabled = true;
    }

    console.log("[UI] Moving to Step 2");
    setActiveStep(2);
  } catch (error) {
    console.error("[UI] Error during OCR step", error);
    step1Next.textContent = "Next — Run OCR";
    step1Next.disabled = false;
    if (mathMessage) {
      mathMessage.textContent =
        "There was a problem processing the image. Details: " +
        (error && error.message ? error.message : "see console");
    }
    return;
  } finally {
    step1Next.textContent = "Next — Run OCR";
    step1Next.disabled = false;
    if (overlay) {
      overlay.classList.remove("visible");
      overlay.setAttribute("aria-hidden", "true");
    }
  }
});

// --- Step 2: OCR + maths check --------------------------------------------

step2Back.addEventListener("click", () => {
  setActiveStep(1);
});

step2Next.addEventListener("click", () => {
  confirmedQuestion.value = state.cleanedOcr;
  approvalMessage.textContent = "";
  step3Next.disabled = true;
  setActiveStep(3);
});

// --- Step 3: confirmation --------------------------------------------------

approveQuestionButton.addEventListener("click", () => {
  const text = confirmedQuestion.value.trim();
  if (!text) {
    approvalMessage.textContent =
      "Please enter a non-empty maths question before approving.";
    approvalMessage.style.color = "#d63384";
    step3Next.disabled = true;
    return;
  }

  state.approvedQuestion = text;
  approvalMessage.textContent =
    "Question approved. You can now view the solution.";
  approvalMessage.style.color = "#198754";
  step3Next.disabled = false;
});

step3Back.addEventListener("click", () => {
  setActiveStep(2);
});

step3Next.addEventListener("click", () => {
  if (!state.approvedQuestion) return;
  finalQuestion.textContent = state.approvedQuestion;
  apiStatus.textContent = "";
  clearSolution();
  setActiveStep(4);
});

// --- Step 4: AI solution ---------------------------------------------------

function clearSolution() {
  solutionModelChip.textContent = "";
  cardProblem.textContent = "";
  cardReasoning.textContent = "";
  while (cardSteps.firstChild) cardSteps.removeChild(cardSteps.firstChild);
  cardFinalLatex.textContent = "";
  cardFinalPlain.textContent = "";
  cardVerification.textContent = "";
}

function renderMathIn(el) {
  try {
    if (typeof window !== "undefined" && window.renderMathInElement) {
      window.renderMathInElement(el, {
        delimiters: [
          { left: "$$", right: "$$", display: true },
          { left: "$", right: "$", display: false },
          { left: "\\(", right: "\\)", display: false },
          { left: "\\[", right: "\\]", display: true },
        ],
      });
    }
  } catch (e) {
    console.warn("[SOLVE] KaTeX render warning", e);
  }
}

function renderSolutionCard(sol, modelName) {
  solutionModelChip.textContent = modelName
    ? modelName.replace(/^models\//, "")
    : "";
  cardProblem.textContent = sol.problem || state.approvedQuestion || "";
  cardReasoning.textContent = sol.reasoning || "";
  const steps = Array.isArray(sol.steps) ? sol.steps : [];
  steps.forEach((s) => {
    const li = document.createElement("li");
    li.textContent = String(s || "");
    cardSteps.appendChild(li);
  });
  cardFinalLatex.textContent = sol.final_answer_latex || "";
  cardFinalPlain.textContent = sol.final_answer_plain || "";
  cardVerification.textContent = sol.verification || "";

  // Render LaTeX inside the card
  renderMathIn(solutionCard);
}

async function callGeminiSolve(questionText) {
  const apiKey = getGeminiApiKey();
  if (!apiKey) throw new Error("GEMINI_API_KEY is not configured for solving.");

  const basePrompt =
    "You are a careful mathematics tutor. Solve the given problem with clear, numbered steps and brief explanations. " +
    "Return ONLY valid JSON with the following exact shape and key names (no extra keys, no markdown outside JSON):\n" +
    "{\n" +
    '  "problem": string,\n' +
    '  "reasoning": string,\n' +
    '  "steps": string[],\n' +
    '  "final_answer_latex": string,\n' +
    '  "final_answer_plain": string,\n' +
    '  "verification": string\n' +
    "}\n" +
    "Use LaTeX for mathematical expressions in steps and final_answer_latex.\n" +
    "Problem: " +
    questionText;

  function extractJsonFromText(raw) {
    let txt = String(raw || "").trim();
    const fenceMatch = txt.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
    if (fenceMatch && fenceMatch[1]) {
      txt = fenceMatch[1].trim();
    }
    const firstBrace = txt.indexOf("{");
    const lastBrace = txt.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      txt = txt.slice(firstBrace, lastBrace + 1);
    }
    return txt;
  }

  const tryGenerate = async (url) => {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: basePrompt }] }] }),
    });
    if (!response.ok)
      return {
        ok: false,
        status: response.status,
        text: await response.text(),
      };
    const result = await response.json();
    const parts = result.candidates?.[0]?.content?.parts || [];
    const raw = parts
      .map((p) => (typeof p.text === "string" ? p.text : ""))
      .join("\n")
      .trim();
    let parsed = null;
    try {
      parsed = JSON.parse(extractJsonFromText(raw));
    } catch (e) {
      console.warn("[SOLVE] JSON parse failed, raw text:", raw);
      return { ok: false, status: 200, text: raw };
    }
    return {
      ok: true,
      data: parsed,
      modelVersion: result.modelVersion || result.candidates?.[0]?.model,
      responseId: result.responseId,
    };
  };

  const endpoints = [
    "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=" +
      encodeURIComponent(apiKey),
    "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=" +
      encodeURIComponent(apiKey),
    "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash-latest:generateContent?key=" +
      encodeURIComponent(apiKey),
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" +
      encodeURIComponent(apiKey),
  ];

  let lastError = "";
  for (const url of endpoints) {
    console.log("[SOLVE] Trying endpoint", url);
    const r = await tryGenerate(url);
    if (r.ok) return { solution: r.data, modelName: r.modelVersion || "" };
    lastError = r.text;
    console.warn("[SOLVE] Endpoint failed", url, r.status, r.text);
  }

  try {
    const listResp = await fetch(
      "https://generativelanguage.googleapis.com/v1/models?key=" +
        encodeURIComponent(apiKey),
    );
    const listJson = await listResp.json();
    const models = Array.isArray(listJson.models) ? listJson.models : [];
    const sorted = models.sort((a, b) => {
      const an = String(a.name || "");
      const bn = String(b.name || "");
      const aw = an.includes("2.5") ? 0 : an.includes("flash") ? 1 : 2;
      const bw = bn.includes("2.5") ? 0 : bn.includes("flash") ? 1 : 2;
      return aw - bw;
    });
    for (const m of sorted) {
      const modelName = m.name;
      if (!modelName) continue;
      const supports =
        m.supportedGenerationMethods || m.supported_generation_methods;
      if (Array.isArray(supports) && !supports.includes("generateContent")) {
        continue;
      }
      const url =
        "https://generativelanguage.googleapis.com/v1/" +
        modelName +
        ":generateContent?key=" +
        encodeURIComponent(apiKey);
      const r = await tryGenerate(url);
      console.log("[SOLVE] Dynamic model status", modelName, r.ok);
      if (r.ok) return { solution: r.data, modelName };
      lastError = r.text;
    }
  } catch (e) {
    console.warn("[SOLVE] ListModels failed", e);
  }

  throw new Error("Gemini solve failed: " + lastError);
}

solveButton.addEventListener("click", async () => {
  if (!state.approvedQuestion) return;

  clearSolution();
  apiStatus.textContent = "Solving question...";
  apiStatus.style.color = "#0b5ed7";

  try {
    const { solution, modelName } = await callGeminiSolve(
      state.approvedQuestion,
    );
    apiStatus.textContent = "Solution received.";
    apiStatus.style.color = "#198754";
    renderSolutionCard(solution, modelName);
  } catch (e) {
    console.error("[SOLVE] Error", e);
    apiStatus.textContent =
      "There was a problem generating the solution. Please try again.";
    apiStatus.style.color = "#dc3545";
  }
});

step4Back.addEventListener("click", () => {
  setActiveStep(3);
});

// Initialise to step 1
setActiveStep(1);
